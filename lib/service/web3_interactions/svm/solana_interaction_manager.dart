import 'package:bs58/bs58.dart';
import 'package:flutter/widgets.dart';
import 'package:moonwallet/logger/logger.dart';
import 'package:moonwallet/service/db/balance_database.dart';
import 'package:moonwallet/service/db/wallet_db.dart';
import 'package:moonwallet/service/internet_manager.dart';
import 'package:moonwallet/types/types.dart';
import 'package:moonwallet/widgets/func/transactions/svm/ask_user_svm.dart';
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

  Future<BigInt?> getTransactionFee() async {
    try {} catch (e) {
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

      final askConfirmation = await askUserSvm(
          crypto: data.crypto,
          context: context,
          colors: colors,
          from: from,
          to: to,
          value: amount);
    } catch (e) {
      logError(e.toString());
      return null;
    }
  }

  bool isAddressValid(String address) {
    try {
      final decoded = base58.decode(address);
      return decoded.length == 32;
    } catch (e) {
      return false;
    }
  }
}
