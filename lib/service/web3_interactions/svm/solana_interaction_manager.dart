import 'package:bs58/bs58.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter/widgets.dart';
import 'package:moonwallet/custom/web3_webview/lib/utils/loading.dart';
import 'package:moonwallet/logger/logger.dart';
import 'package:moonwallet/service/db/balance_database.dart';
import 'package:moonwallet/service/db/wallet_db.dart';
import 'package:moonwallet/service/internet_manager.dart';
import 'package:moonwallet/types/types.dart';
import 'package:moonwallet/widgets/func/security/ask_password.dart';
import 'package:moonwallet/widgets/func/transactions/svm/ask_user_svm.dart';
import 'package:solana/dto.dart' as dto;
import 'package:solana/encoder.dart';
import 'package:solana/solana.dart';

class SolanaInteractionManager {
  RpcClient get _rpcClient => RpcClient("https://api.mainnet-beta.solana.com");
  final internet = InternetManager();
  final walletDb = WalletDatabase();

  Future<String?> generateAddress(String mnemonic) async {
    try {
      final keyPair = await getKeyPair(mnemonic);
      if (keyPair == null) {
        throw "Failed to generate key pair";
      }
      final address = keyPair.address;
      log("Generated address: $address");
      return address;
    } catch (e) {
      logError(e.toString());
      return null;
    }
  }

  Future<Ed25519HDKeyPair?> getKeyPair(String mnemonic) async {
    try {
      final keyPair = await Ed25519HDKeyPair.fromMnemonic(mnemonic);
      return keyPair;
    } catch (e) {
      logError(e.toString());
      return null;
    }
  }

  Future<String?> getBalanceToken(PublicData account, Crypto crypto) async {
    try {
      final db = BalanceDatabase(account: account, crypto: crypto);
      final savedBalance = db.getBalance();
      final solAddress = account.svmAddress;
      final tokenAddress = crypto.contractAddress;
      if (solAddress == null) {
        throw "Invalid address";
      }
      if (tokenAddress == null) {
        throw "Invalid Token address";
      }

      if (!(await internet.isConnected())) {
        return await savedBalance;
      }

      final accounts = await _rpcClient.getTokenAccountsByOwner(
        solAddress,
        dto.TokenAccountsFilter.byMint(tokenAddress),
      );

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
      logError(e.toString());
      return null;
    }
  }

  Future<String?> getUserBalance(PublicData account, Crypto crypto) async {
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
      return null;
    }
  }

  Future<String?> getBalance(PublicData account, Crypto crypto) async {
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

      final password = await askPassword(context: context, colors: colors);
      if (password.isEmpty) {
        throw "Invalid Password";
      }
      final secureData = await walletDb.getSecureData(
          password: password, account: data.account);
      final mnemonic = secureData?.mnemonic;

      if (mnemonic == null) {
        throw "Invalid Wallet";
      }

      final wallet = await getKeyPair(mnemonic);
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

      final message = Message(instructions: instructions);
      final signature = await _rpcClient
          .signAndSendTransaction(message, [wallet]).withLoading(
              context, colors, "Waiting For Transfer");
      log("Message signed $signature");

      return signature;
    } catch (e) {
      logError(e.toString());
      return null;
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

  bool isAddressValid(String address) {
    try {
      final decoded = base58.decode(address);
      return decoded.length == 32;
    } catch (e) {
      return false;
    }
  }
}
