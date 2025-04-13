// ignore_for_file: deprecated_member_use

import 'dart:convert';

import 'package:moonwallet/logger/logger.dart';
import 'package:moonwallet/service/wallet_saver.dart';
import 'package:moonwallet/types/types.dart';

class CryptoStorageManager {
  final saver = WalletSaver();

  Future<List<Crypto>?> getSavedCryptos({required PublicData wallet}) async {
    try {
      final name = "savedCrypto/test2/${wallet.address}";
      log("getting crypto for address ${wallet.address}");

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
      final name = "savedCrypto/test2/${wallet.address}";
      log("Saving crypto for address ${wallet.address}");

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
      final name = "assetsOf/${wallet.address}";
      log("getting assets for address ${wallet.address}");

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

  Future<UserAssetsResponse?> getSavedAssetsResponse(
      {required PublicData wallet}) async {
    try {
      final name = "assetsResponseOf/${wallet.address}";
      log("getting assets response for address ${wallet.address}");

      final String? cryptoDataString = await saver.getDynamicData(name: name);
      if (cryptoDataString == null || cryptoDataString.isEmpty) {
        logError("Crypto data not found");
        return null;
      }

      final dynamic savedAssetsJson = json.decode(cryptoDataString);
      UserAssetsResponse savedAssets =
          UserAssetsResponse.fromJson(savedAssetsJson);

      return savedAssets;
    } catch (e) {
      logError("Error getting saved assets: $e");
      return null;
    }
  }

  Future<bool> saveAssetsResponse(
      {required UserAssetsResponse assetsResponse,
      required PublicData account}) async {
    try {
      final cryptoListString = assetsResponse.toJson();
      final name = "assetsResponseOf/${account.address}";
      log("Saving assets for address ${account.address}");
      await saver.saveDynamicData(
          boxName: name, data: json.encode(cryptoListString));
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
      final name = "assetsOf/${account.address}";
      log("Saving assets for address ${account.address}");
      await saver.saveDynamicData(
          boxName: name, data: json.encode(cryptoListString));
      return true;
    } catch (e) {
      logError(e.toString());
      return false;
    }
  }

  Future<bool> toggleCanDisplay(
      {required String cryptoId,
      required bool value,
      required PublicData wallet}) async {
    try {
      final List<Crypto>? savedCryptos = await getSavedCryptos(wallet: wallet);
      Crypto? cryptoToEdit;
      if (savedCryptos != null) {
        for (final crypto in savedCryptos) {
          if (crypto.cryptoId.trim() == cryptoId.trim()) {
            cryptoToEdit = crypto;
          }
        }
        if (cryptoToEdit != null) {
          final index = savedCryptos.indexOf(cryptoToEdit);
          final newCrypto = Crypto(
              isNetworkIcon: cryptoToEdit.isNetworkIcon,
              symbol: cryptoToEdit.symbol,
              name: cryptoToEdit.name,
              color: cryptoToEdit.color,
              type: cryptoToEdit.type,
              valueUsd: cryptoToEdit.valueUsd,
              cryptoId: cryptoToEdit.cryptoId,
              canDisplay: value,
              network: cryptoToEdit.network,
              icon: cryptoToEdit.icon,
              chainId: cryptoToEdit.chainId,
              contractAddress: cryptoToEdit.contractAddress,
              explorer: cryptoToEdit.explorer,
              rpc: cryptoToEdit.rpc,
              binanceSymbol: cryptoToEdit.binanceSymbol,
              decimals: cryptoToEdit.decimals);
          savedCryptos[index] = newCrypto;
          return await saveListCrypto(cryptos: savedCryptos, wallet: wallet);
        } else {
          logError("Crypto is null");
          return false;
        }
      } else {
        logError("No saved cryptos to toggle canDisplay");
        return false;
      }
    } catch (e) {
      logError("Error : $e");
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
