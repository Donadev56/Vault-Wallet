// ignore_for_file: deprecated_member_use

import 'dart:convert';

import 'package:moonwallet/logger/logger.dart';
import 'package:moonwallet/service/db/wallet_db.dart';
import 'package:moonwallet/types/types.dart';

class CryptoStorageManager {
  final saver = WalletDatabase();

  Future<List<Crypto>?> getSavedCryptos({required PublicData wallet}) async {
    try {
      final name = "savedCrypto/test21/${wallet.keyId}";
      log("Getting crypto for address ${wallet.keyId}");

      final String? cryptoDataString = await saver.getDynamicData(name: name);
      if (cryptoDataString == null || cryptoDataString.isEmpty) {
        logError("Crypto data not found");
        return [];
      }

      final List<dynamic> savedCryptosJson = json.decode(cryptoDataString);
      List<Crypto> savedCryptos = [];

      for (final cryptoJson in savedCryptosJson) {
        final newCrypto = Crypto.fromJson(cryptoJson);
        savedCryptos.add(newCrypto);
      }

      if (savedCryptos.isNotEmpty) {
        return savedCryptos;
      }

      logError("No crypto found");

      return null;
    } catch (e) {
      logError("Error getting saved cryptos: $e");
      return null;
    }
  }

  Future<bool> saveListCrypto(
      {required List<Crypto> cryptos, required PublicData wallet}) async {
    try {
      final name = "savedCrypto/test21/${wallet.keyId}";
      log("Saving crypto for address ${wallet.keyId}");

      List<dynamic> cryptoJson = cryptos.map((c) => c.toJson()).toList();

      if (cryptoJson.isNotEmpty) {
        await saver.saveDynamicData(
            boxName: name, data: json.encode(cryptoJson));
        return true;
      } else {
        logError("No crypto to save");
        return false;
      }
    } catch (e) {
      logError("Error saving cryptos: $e");
      return false;
    }
  }

  Future<List<Asset>?> getSavedAssets({required PublicData wallet}) async {
    try {
      final name = "assetsOf/test4/${wallet.keyId}";
      log("getting assets for address ${wallet.keyId}");

      final String? cryptoDataString = await saver.getDynamicData(name: name);
      if (cryptoDataString == null || cryptoDataString.isEmpty) {
        logError("Crypto data not found");
        return [];
      }

      final List<dynamic> savedAssetsJson = json.decode(cryptoDataString);
      List<Asset> savedAssets = [];

      for (final assetJson in savedAssetsJson) {
        final newAsset = Asset.fromJson(assetJson);
        savedAssets.add(newAsset);
      }

      if (savedAssets.isNotEmpty) {
        return savedAssets;
      }

      logError("No assets found");

      return null;
    } catch (e) {
      logError("Error getting saved assets: $e");
      return null;
    }
  }

  Future<List<dynamic>?> getSavedCryptoPriceData(
      {required Crypto crypto, required String interval}) async {
    try {
      final name = "cryptoData/of/${crypto.cgSymbol}/at/$interval/";
      final String? cryptoDataString = await saver.getDynamicData(name: name);
      if (cryptoDataString == null) {
        logError("Crypto data not found");
        return [];
      }
      return json.decode(cryptoDataString);
    } catch (e) {
      logError("Error getting saved assets: $e");
      return null;
    }
  }

  Future<bool> saveCryptoPriceData(
      {required Crypto crypto,
      required String interval,
      required List<dynamic>? data}) async {
    try {
      final name = "cryptoData/of/${crypto.cgSymbol}/at/$interval/";
      await saver.saveDynamicData(boxName: name, data: json.encode(data));
      return true;
    } catch (e) {
      logError(e.toString());
      return false;
    }
  }

  Future<bool> saveListAssets(
      {required List<Asset> assets, required PublicData account}) async {
    try {
      final cryptoListString = assets.map((c) => c.toJson()).toList();
      final name = "assetsOf/test4/${account.keyId}";
      log("Saving assets for address ${account.keyId}");
      await saver.saveDynamicData(
          boxName: name, data: json.encode(cryptoListString));
      return true;
    } catch (e) {
      logError(e.toString());
      return false;
    }
  }

  Future<bool> toggleCanDisplay(
      {required Crypto crypto,
      required bool value,
      required PublicData wallet}) async {
    try {
      final List<Crypto>? savedCryptos = await getSavedCryptos(wallet: wallet);
      final cryptoToEdit = crypto;
      if (savedCryptos == null) {
        throw 'Saved data is null';
      }
      log("Crypto ${cryptoToEdit.toJson()}");
      if (cryptoToEdit.isNative && cryptoToEdit.networkType == null) {
        throw 'A native crypto must have a network type';
      }
      final index =
          savedCryptos.indexWhere((c) => c.cryptoId == cryptoToEdit.cryptoId);
      final newCrypto = cryptoToEdit.copyWith(canDisplay: value);

      savedCryptos[index] = newCrypto;
      return await saveListCrypto(cryptos: savedCryptos, wallet: wallet);
    } catch (e) {
      logError("Error : $e");
      return false;
    }
  }

  Future<bool> editNetwork(
      {required int chainId,
      String? name,
      String? symbol,
      required PublicData wallet,
      List<String>? rpcUrls,
      List<String>? explorers}) async {
    try {
      final List<Crypto>? savedCryptos = await getSavedCryptos(wallet: wallet);
      if (savedCryptos == null) {
        throw 'Saved data is null';
      }
      final index = savedCryptos.indexWhere((c) => c.chainId == chainId);
      final cryptoToEdit = savedCryptos[index];
      final newCrypto = cryptoToEdit.copyWith(
        explorers: explorers,
        rpcUrls: rpcUrls,
        name: name,
        symbol: symbol,
      );
      savedCryptos[index] = newCrypto;
      final cryptosOfThisNetwork =
          savedCryptos.where((c) => c.network?.chainId == chainId).toList();
      for (final crypto in cryptosOfThisNetwork) {
        final index = savedCryptos.indexWhere((c) =>
            c.cryptoId.trim().toLowerCase() ==
            crypto.cryptoId.trim().toLowerCase());
        if (index < 0) {
          continue;
        }
        savedCryptos[index] = crypto.copyWith(network: newCrypto);
      }
      return await saveListCrypto(cryptos: savedCryptos, wallet: wallet);
    } catch (e) {
      return false;
    }
  }

  Future<bool> addCrypto(
      {required Crypto crypto, required PublicData wallet}) async {
    try {
      final List<Crypto>? savedCryptos = await getSavedCryptos(wallet: wallet);
      if (savedCryptos != null) {
        savedCryptos.add(crypto);
        return await saveListCrypto(cryptos: savedCryptos, wallet: wallet);
      } else {
        logError("No saved cryptos to add new one");
        return false;
      }
    } catch (e) {
      logError("Error adding crypto: $e");
      return false;
    }
  }
}
