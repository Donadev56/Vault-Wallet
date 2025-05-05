import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moonwallet/logger/logger.dart';
import 'package:moonwallet/notifiers/providers.dart';
import 'package:moonwallet/service/db/wallet_db_stateless.dart';
import 'package:moonwallet/service/web3_interactions/evm/addresses.dart';
import 'package:moonwallet/types/account_related_types.dart';

class WalletManagerNotifier {
  final web3Manager = WalletDbStateLess();
  final ethAddresses = EthAddresses();

  final Ref ref;
  WalletManagerNotifier(this.ref);

  Future<PublicAccount?> saveMnemonic(
      String mnemonic, String userPassword, bool createdLocally) async {
    final accountsProvider = ref.watch(accountsNotifierProvider.notifier);

    try {
      if (userPassword.isEmpty) {
        throw Exception("passwords must not be empty ");
      }
      final walletCounts = (await accountsProvider.getPublicAccount()).length;
      final result = await web3Manager.savePrivateData(
          createdLocally: createdLocally,
          password: userPassword,
          walletName: "New Wallet $walletCounts",
          origin: Origin.mnemonic,
          networks: NetworkType.values,
          keyOrigin: mnemonic);

      ref.invalidate(accountsNotifierProvider);
      if (result != null) {
        return result;
      } else {
        throw Exception("Failed to save the key.");
      }
    } catch (e) {
      logError(e.toString());
      rethrow;
    }
  }

  Future<PublicAccount?> savePrivateKey(String privateKey, String userPassword,
      bool createdLocally, NetworkType type) async {
    try {
      final response = await web3Manager.savePrivateData(
          createdLocally: createdLocally,
          keyOrigin: privateKey,
          origin: Origin.privateKey,
          password: userPassword,
          walletName: "MoonWallet-1",
          networks: [type]);
      if (response != null) {
        ref.invalidate(accountsNotifierProvider);

        return response;
      }

      return response;
    } catch (e) {
      logError(e.toString());
      rethrow;
    }
  }

  Future<PublicAccount?> saveWO(String address, NetworkType type) async {
    try {
      final result = await web3Manager.saveObservationWalletInStorage(
          "New view Wallet", address, type, [type]);
      if (result != null) {
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
