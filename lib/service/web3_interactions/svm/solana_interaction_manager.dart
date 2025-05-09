// ignore_for_file: use_build_context_synchronously
import 'package:flutter/widgets.dart';
import 'package:moonwallet/custom/solana/src/solana.dart';
import 'package:moonwallet/custom/web3_webview/lib/utils/loading.dart';
import 'package:moonwallet/logger/logger.dart';
import 'package:moonwallet/service/db/balance_database.dart';
import 'package:moonwallet/service/db/wallet_db_stateless.dart';
import 'package:moonwallet/service/internet_manager.dart';
import 'package:moonwallet/service/web3_interactions/svm/solana_address.dart';
import 'package:moonwallet/service/web3_interactions/svm/utils.dart';
import 'package:moonwallet/types/account_related_types.dart' as types;
import 'package:moonwallet/types/exception.dart';
import 'package:moonwallet/types/types.dart';
import 'package:moonwallet/widgets/func/account_related/show_watch_only_warning.dart';
import 'package:moonwallet/widgets/func/security/ask_derivate_key.dart';
import 'package:moonwallet/widgets/func/transactions/svm/ask_user_svm.dart';
import 'package:solana/solana.dart';

class SolanaInteractionManager {
  final internet = InternetManager();
  final walletDb = WalletDbStateLess();
  final solAddress = SolanaAddress();
  final _utils = SolanaUtils();

  Future<String> getBalanceToken(
      types.PublicAccount account, types.Crypto crypto) async {
    try {
      final solana = Solana(crypto.getRpcUrl);
      final tokenAddress = crypto.contractAddress;
      final ownerAddress = account.svmAddress;

      if (tokenAddress == null) {
        throw Exception("Invalid account");
      }

      if (ownerAddress == null) {
        throw Exception('Invalid account : user address is null');
      }

      final balance = await solana.getTokenBalance(
        address: ownerAddress,
        tokenAddress: tokenAddress,
      );

      log("Balance of ${crypto.symbol} $balance");

      return balance is String ? balance : balance.toString();
    } catch (e) {
      logError(e.toString());
      rethrow;
    }
  }

  Future<String> getBalance(
      types.PublicAccount account, types.Crypto crypto) async {
    final db = BalanceDatabase(account: account, crypto: crypto);
    final savedBalance = db.getBalance();
    try {
      String balance = "0";

      if (!(await internet.isConnected())) {
        return await savedBalance;
      }

      if (crypto.isNative) {
        balance = await getSolBalance(account, crypto);
      } else {
        balance = await getBalanceToken(account, crypto);
      }

      await db.saveData(balance);
      return balance;
    } catch (e) {
      logError(e.toString());
    }

    return await savedBalance;
  }

  Future<bool> _validateTokenBalance(types.PublicAccount account,
      types.Crypto token, String amountLamports) async {
    final userBalance = await getBalanceToken(account, token);
    final amountDecimal = amountLamports.toDecimal();
    final balanceLamports = _utils.solToLamportsDecimal(userBalance);
    return balanceLamports >= amountDecimal;
  }

  Future<bool> _validateSolBalance(types.PublicAccount account,
      types.Crypto token, String amountLamports) async {
    final userBalance = await getBalance(account, token);
    final amountDecimal = amountLamports.toDecimal();
    final balanceLamports = _utils.solToLamportsDecimal(userBalance);
    return balanceLamports >= amountDecimal;
  }

  Future<bool> _validateBalance(types.PublicAccount account, types.Crypto token,
      String amountLamports) async {
    if (token.isNative) {
      return (await _validateSolBalance(account, token, amountLamports));
    }
    return (await _validateTokenBalance(account, token, amountLamports));
  }

  Future<String?> handleTransfer(
      BasicTransactionData data, AppColors colors, BuildContext context) async {
    try {
      if (data.account.isWatchOnly) {
        showWatchOnlyWaring(colors: colors, context: context);
        throw Exception("Watch only account can't send transactions");
      }
      final String to = data.addressTo;
      final String from = data.account.svmAddress ?? "";
      final String amount = data.amount;
      final account = data.account;
      final crypto = data.crypto;
      final isNative = crypto.isNative;
      final String amountLamports = isNative
          ? _utils.solToLamportsString(amount)
          : _utils.parseTokenAmount(amount, crypto.decimals);

      // IF THE CURRENT CRYPTO IS A TOKEN
      final tokenAddress = crypto.contractAddress;
      if (!(await _validateBalance(account, crypto, amountLamports))) {
        throw Exception("Insufficient balance");
      }

      log("Amount Lamports $amountLamports");

      final confirmation = await askUserSvm(
          crypto: data.crypto,
          context: context,
          colors: colors,
          from: from,
          to: to,
          value: amount);

      if (confirmation == null || !confirmation.ok) {
        throw ("Transaction Rejected by user");
      }
      final memo = confirmation.memo;
      final deriveKey = await askDerivateKey(context: context, colors: colors);

      if (deriveKey == null) {
        throw InvalidPasswordException();
      }
      final privateAccount = await walletDb.getPrivateAccountUsingKey(
          deriveKey: deriveKey, account: data.account);
      final accountKey = privateAccount?.keyOrigin;

      if (accountKey == null) {
        throw "Invalid Wallet";
      }

      Ed25519HDKeyPair? wallet;
      if (account.origin.isPrivateKey) {
        wallet = await solAddress.getKeyPairByPrivateKey(accountKey);
      } else {
        wallet = await solAddress.getKeyPair(accountKey);
      }

      if (wallet == null) {
        throw Exception("Invalid Account Data");
      }

      if (isNative) {
        return await sendSolCoin(
                crypto: crypto,
                account: account,
                accountKey: accountKey,
                to: to,
                context: context,
                amountLamports: amountLamports,
                colors: colors,
                memo: memo,
                wallet: wallet)
            .withLoading(context, colors, "Sending...");
      } else {
        if (tokenAddress == null) {
          throw ArgumentError("Token address should not be null");
        }
        return await sendSplCoin(
                crypto: crypto,
                account: account,
                accountKey: accountKey,
                to: to,
                context: context,
                amountLamports: amountLamports,
                colors: colors,
                memo: memo,
                tokenAddress: tokenAddress,
                wallet: wallet)
            .withLoading(context, colors, "Sending...");
      }
    } catch (e) {
      logError(e.toString());
      rethrow;
    }
  }

  Future<String?> sendSolCoin(
      {required types.PublicAccount account,
      required String accountKey,
      required String to,
      required BuildContext context,
      required String amountLamports,
      required Ed25519HDKeyPair wallet,
      String? memo,
      required types.Crypto crypto,
      required AppColors colors}) async {
    try {
      final solana = Solana(crypto.getRpcUrl);

      final transactionId = await solana
          .sendSolCoin(
              receiverAddress: to,
              amount: int.parse(amountLamports),
              wallet: wallet,
              memo: memo)
          .withLoading(context, colors, "Sending...");
      log("Message signed $transactionId");

      return transactionId;
    } catch (e) {
      logError(e.toString());
      rethrow;
    }
  }

  Future<String?> sendSplCoin(
      {required types.PublicAccount account,
      required String accountKey,
      required String to,
      required BuildContext context,
      required String amountLamports,
      required String tokenAddress,
      required Ed25519HDKeyPair wallet,
      String? memo,
      required types.Crypto crypto,
      required AppColors colors}) async {
    try {
      final solana = Solana(crypto.getRpcUrl);

      final transactionId = await solana.sendToken(
          receiverAddress: to,
          tokenAddress: tokenAddress,
          amount: int.parse(amountLamports),
          wallet: wallet,
          memo: memo);
      log("Transaction id $transactionId");
      return transactionId;
    } catch (e) {
      logError(e.toString());
      rethrow;
    }
  }

  Future<String> getSolBalance(
      types.PublicAccount account, types.Crypto crypto) async {
    try {
      final solana = Solana(crypto.getRpcUrl);

      final ownerAddress = account.svmAddress;
      if (ownerAddress == null) {
        throw Exception("Invalid account");
      }
      final solBalance = await solana.getBalance(address: ownerAddress);
      log("Solana balance $solBalance");
      return solBalance.toString();
    } catch (e) {
      logError(e.toString());
      rethrow;
    }
  }
}
