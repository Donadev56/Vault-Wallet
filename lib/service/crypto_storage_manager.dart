// ignore_for_file: deprecated_member_use

import 'dart:convert';

import 'package:moonwallet/logger/logger.dart';
import 'package:moonwallet/types/types.dart';
import 'package:moonwallet/utils/document_manager.dart';

class CryptoStorageManager {
  final documentStorage = DocumentManager();
  final path = "/db/crypto/accounts";

  Future<List<Crypto>?> getSavedCryptos({required PublicData wallet}) async {
    try {
      final filePath = "${wallet.keyId}/test8/wallet.json";

      final cryptoDataString =
          await documentStorage.readData(filePath: filePath);
      if (cryptoDataString == null || cryptoDataString.isEmpty) {
        throw Exception("Crypto data not found");
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
      final filePath = "${wallet.keyId}/test8/wallet.json";

      List<dynamic> cryptoJson = [];
      for (final crypto in cryptos) {
        cryptoJson.add(crypto.toJson());
      }
      if (cryptoJson.isNotEmpty) {
        await documentStorage.saveFile(
            filePath: filePath, data: json.encode(cryptoJson));
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
              apiBaseUrl: cryptoToEdit.apiBaseUrl,
              apiKey: cryptoToEdit.apiKey,
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
