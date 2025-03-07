// ignore_for_file: deprecated_member_use

import 'dart:convert';

import 'package:moonwallet/logger/logger.dart';
import 'package:moonwallet/types/types.dart';
import 'package:moonwallet/utils/document_manager.dart';

class CryptoStorageManager {
  final documentStorage = DocumentManager();
  final path = "/db/crypto/cryptos.json";

  Future<List<Crypto>?> getSavedCryptos() async {
    try {
      final cryptoDataString = await documentStorage.readData(filePath: path);
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

  Future<bool> saveListCrypto({required List<Crypto> cryptos}) async {
    try {
      List<dynamic> cryptoJson = [];
      for (final crypto in cryptos) {
        cryptoJson.add(crypto.toJson());
      }
      if (cryptoJson.isNotEmpty) {
        await documentStorage.saveFile(
            filePath: path, data: json.encode(cryptoJson));
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

  Future<bool> addCrypto({required Crypto crypto}) async {
    try {
      final List<Crypto>? savedCryptos = await getSavedCryptos();
      if (savedCryptos != null) {
        savedCryptos.add(crypto);
        return await saveListCrypto(cryptos: savedCryptos);
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
