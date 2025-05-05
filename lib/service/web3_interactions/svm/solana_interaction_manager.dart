import 'package:bs58/bs58.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter/widgets.dart';
import 'package:moonwallet/custom/web3_webview/lib/utils/loading.dart';
import 'package:moonwallet/logger/logger.dart';
import 'package:moonwallet/service/db/balance_database.dart';
import 'package:moonwallet/service/db/wallet_db.dart';
import 'package:moonwallet/service/db/wallet_db_stateless.dart';
import 'package:moonwallet/service/internet_manager.dart';
import 'package:moonwallet/service/web3_interactions/svm/solana_address.dart';
import 'package:moonwallet/types/account_related_types.dart';
import 'package:moonwallet/types/types.dart';
import 'package:moonwallet/widgets/func/security/ask_derivate_key.dart';
import 'package:moonwallet/widgets/func/security/ask_password.dart';
import 'package:moonwallet/widgets/func/transactions/svm/ask_user_svm.dart';
import 'package:solana/dto.dart' as dto;
import 'package:solana/encoder.dart';
import 'package:solana/solana.dart';

class SolanaInteractionManager {
  RpcClient get _rpcClient => RpcClient("https://api.mainnet-beta.solana.com");
  final internet = InternetManager();
  final walletDb = WalletDbStateLess();
  final solAddress = SolanaAddress();

  Future<String?> getBalanceToken(PublicAccount account, Crypto crypto) async {
    final db = BalanceDatabase(account: account, crypto: crypto);
    final solAddress = account.svmAddress;
    final tokenAddress = crypto.contractAddress;
    try {
      final savedBalance = db.getBalance();

      if (solAddress == null) {
        throw "Invalid address";
      }
      if (tokenAddress == null) {
        throw "Invalid Token address";
      }
      if (!this.solAddress.isAddressValid(solAddress)) {
        throw "Invalid key format";
      }

      if (!this.solAddress.isAddressValid(tokenAddress)) {
        throw "Invalid Token key $tokenAddress format";
      }

      if (!(await internet.isConnected())) {
        return await savedBalance;
      }

      log("The address $tokenAddress is valid");
      final accounts = await _rpcClient.getTokenAccountsByOwner(
        solAddress,
        dto.TokenAccountsFilter.byMint(tokenAddress),
      );

      log("Accounts $tokenAddress ${accounts.toJson()}");

      if (accounts.value.isEmpty) {
        throw "No token accounts found ";
      }

      final tokenAccountPubKey = accounts.value.first;
      final balanceResult =
          await _rpcClient.getTokenAccountBalance(tokenAccountPubKey.pubkey);
      final balanceUi = balanceResult.value.uiAmountString;
      await db.saveData(balanceUi ?? "0");
      return balanceUi;
    } catch (e) {
      logError(
          'An error occurred while getting balance of $solAddress using $tokenAddress token address\n Error : $e');
    }

    return await db.getBalance();
  }

  Future<String?> getUserBalance(PublicAccount account, Crypto crypto) async {
    final db = BalanceDatabase(account: account, crypto: crypto);

    try {
      final db = BalanceDatabase(account: account, crypto: crypto);
      final address = account.svmAddress;
      final savedBalance = db.getBalance();

      if (!(await internet.isConnected())) {
        return await savedBalance;
      }

      if (address == null) {
        throw "No solana address found";
      }
      final balance = await _rpcClient.getBalance(address);
      await db.saveData(balance.value.toString());

      log("User balance: $balance");
      return balance.value.toString();
    } catch (e) {
      logError(e.toString());
      return await db.getBalance();
    }
  }

  Future<String?> getBalance(PublicAccount account, Crypto crypto) async {
    try {
      if (crypto.isNative) {
        return await getUserBalance(account, crypto);
      }

      return await getBalanceToken(account, crypto);
    } catch (e) {
      logError(e.toString());
      return null;
    }
  }

  Future<String?> sendTransaction(
      BasicTransactionData data, AppColors colors, BuildContext context) async {
    try {
      final String to = data.addressTo;
      final String from = data.account.svmAddress ?? "";
      final String amount = data.amount;
      final String amountLamports =
          (Decimal.parse(data.amount) * Decimal.fromInt(10).pow(9).toDecimal())
              .toStringAsFixed(0);
      log("Amount Lamports ${amountLamports}");

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
      final mnemonic = privateAccount?.keyOrigin;

      if (mnemonic == null) {
        throw "Invalid Wallet";
      }

      final wallet = await solAddress.getKeyPair(mnemonic);
      if (wallet == null) {
        throw "Invalid Key Pair";
      }

      final instructions = <Instruction>[];

      if (memo != null) {
        final memoInstruction =
            MemoInstruction(signers: [wallet.publicKey], memo: memo);
        instructions.add(memoInstruction);
      }
      final transaction = SystemInstruction.transfer(
        fundingAccount: wallet.publicKey,
        recipientAccount: Ed25519HDPublicKey.fromBase58(to),
        lamports: int.parse(amountLamports),
      );

      instructions.add(transaction);

      final message = Message(
        instructions: instructions,
      );

      final signature = await _rpcClient.signAndSendTransaction(
          message, [wallet]).withLoading(context, colors, "Sending...");
      log("Message signed $signature");

      return signature;
    } catch (e) {
      logError(e.toString());
      rethrow;
    }
  }
  /*
  Future<TransactionReceiptData?> getReceipt(String hash) async {
    try {
      final transaction = await _rpcClient.getTransaction(hash);
      if (transaction != null) {
        return TransactionReceiptData(
            from: "",
            to: "",
            transactionId: hash,
            block: transaction.slot.toString(),
            status: null);
      }
    } catch (e) {
      logError(e.toString());
      return null;
    }
  }
  */
}
