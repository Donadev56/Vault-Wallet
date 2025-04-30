import 'dart:convert';

import 'package:moonwallet/logger/logger.dart';
import 'package:moonwallet/service/db/global_database.dart';
import 'package:moonwallet/service/internet_manager.dart';
import 'package:moonwallet/types/types.dart';
import 'package:http/http.dart' as http;

class CryptoRequestManager {
  final baseUrl = "https://api.moonbnb.app";
  final _db = GlobalDatabase();
  final internet = InternetManager();
  final dataKey = "user/global/crypto-available";

  Future<List<Crypto>> getAllCryptos() async {
    try {
      if (!(await internet.isConnected())) {
        return await getSavedCrypto();
      }
      final url = Uri.parse("$baseUrl/crypto/available-cryptos");

      final response = await http.get(url);
      if (response.statusCode != 200) {
        throw Exception('Failed to fetch cryptos');
      }
      final cryptos = toDart(json.decode(response.body));
      await saveCryptos(cryptos);
      return cryptos;
    } catch (e) {
      logError(e.toString());
      return await getSavedCrypto();
    }
  }

  List<Crypto> toDart(List<dynamic> data) {
    final List<Crypto> cryptos = [];
    for (final cryptoJson in data) {
      cryptos.add(Crypto.fromJsonRequest(cryptoJson as Map<String, dynamic>));
    }
    return cryptos;
  }

  Future<bool> saveCryptos(List<Crypto> cryptos) async {
    try {
      final cryptoJsonString =
          json.encode(cryptos.map((e) => e.toJson()).toList());
      return await _db.saveDynamicData(data: cryptoJsonString, key: dataKey);
    } catch (e) {
      logError(e.toString());
      return false;
    }
  }

  Future<List<Crypto>> getSavedCrypto() async {
    try {
      final savedData = await _db.getDynamicData(key: dataKey);
      if (savedData != null) {
        final dataJson = json.decode(savedData);
        return (dataJson as List<dynamic>)
            .map((e) => Crypto.fromJson(e))
            .toList();
      }
      return [];
    } catch (e) {
      logError(e.toString());
      return [];
    }
  }
}
