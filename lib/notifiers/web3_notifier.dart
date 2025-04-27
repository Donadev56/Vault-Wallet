import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moonwallet/logger/logger.dart';
import 'package:moonwallet/notifiers/providers.dart';
import 'package:moonwallet/service/db/wallet_db.dart';
import 'package:moonwallet/service/web3_interactions/evm/addresses.dart';

class Web3Notifier {
  final web3Manager = WalletDatabase();
  final ethAddresses = EthAddresses();

  final Ref ref;
  Web3Notifier(this.ref);

  Future<bool> saveSeed(
      String seed, String userPassword, bool createdLocally) async {
    try {
      final secretData = await ethAddresses.createPrivatekeyFromSeed(seed);

      final key = secretData["key"];
      if (userPassword.isEmpty) {
        throw Exception("passwords must not be empty ");
      }
      final result = await web3Manager.savePrivateData(
          createdLocally: createdLocally,
          privatekey: key,
          password: userPassword,
          walletName: "New Wallet",
          mnemonic: seed);
      ref.invalidate(accountsNotifierProvider);
      if (result) {
        return result;
      } else {
        throw Exception("Failed to save the key.");
      }
    } catch (e) {
      logError(e.toString());
      rethrow;
    }
  }

  Future<bool> savePrivateKey(
      String privateKey, String userPassword, bool createdLocally) async {
    try {
      final response = await web3Manager.savePrivateData(
        createdLocally: createdLocally,
        privatekey: privateKey,
        password: userPassword,
        walletName: "MoonWallet-1",
      );
      if (response) {
        ref.invalidate(accountsNotifierProvider);

        return response;
      }

      return response;
    } catch (e) {
      logError(e.toString());
      rethrow;
    }
  }

  Future<bool> saveWO(String address) async {
    try {
      final result = await web3Manager.saveObservationWalletInStorage(
          "New view Wallet", address);
      if (result) {
        ref.invalidate(accountsNotifierProvider);
        return result;
      }

      return result;
    } catch (e) {
      logError(e.toString());
      rethrow;
    }
  }
}
