import 'dart:convert';

import 'package:moonwallet/logger/logger.dart';
import 'package:moonwallet/service/db/global_database.dart';
import 'package:moonwallet/service/internet_manager.dart';
import 'package:moonwallet/types/account_related_types.dart';
import 'package:http/http.dart' as http;

class CryptoRequestManager {
  final baseUrl = "https://api.moonbnb.app";
  final _db = GlobalDatabase();
  final internet = InternetManager();
  final dataKey = "user/global/crypto-available";
  final defaultDataKey = "user/global/crypto-available-default-tokens";
  final baseV2Url = "http://46.202.175.219:4006";

  Future<List<Crypto>> getAllCryptos() async {
    try {
      if (!(await internet.isConnected())) {
        return await getSavedCrypto();
      }
      final url = Uri.parse("$baseV2Url/v2/tokens/allTokens");

      final response = await http.get(url);
      if (response.statusCode != 200) {
        throw Exception('Failed to fetch cryptos ${response.body}');
      }
      final cryptos = toDart(json.decode(response.body)["tokens"]);
      await saveCryptos(cryptos);
      return cryptos;
    } catch (e) {
      logError(e.toString());
      return await getSavedCrypto();
    }
  }

  Future<List<Crypto>> getTokensPerPage(int index) async {
    try {
      log("Sending request for index : $index");
      final url = Uri.parse("$baseV2Url/v2/tokens/tokensPerPage?page=$index");
      final response = await http.get(url);
      if (response.statusCode != 200) {
        throw Exception('Failed to fetch cryptos ${response.body}');
      }
      final cryptos = toDart(json.decode(response.body));
      return cryptos;
    } catch (e) {
      logError(e.toString());
      return [];
    }
  }

  Future<List<Crypto>> searchTokens(String query) async {
    try {
      log("Sending request for query : $query");
      final url = Uri.parse("$baseV2Url/v2/tokens/search?query=$query");
      final response = await http.get(url);
      if (response.statusCode != 200) {
        throw Exception('Failed to fetch cryptos ${response.body}');
      }
      final cryptos = toDart(json.decode(response.body));
      return cryptos;
    } catch (e) {
      logError(e.toString());
      return [];
    }
  }

  Future<List<Crypto>?> getDefaultTokens() async {
    try {
      if (!(await internet.isConnected())) {
        return await getDefaultTokens();
      }
      final url = Uri.parse("$baseV2Url/v2/tokens/defaultTokens");

      final response = await http.get(url);
      if (response.statusCode != 200) {
        throw Exception('Failed to fetch cryptos ${response.body}');
      }
      final cryptos = toDart(json.decode(response.body));
      await savedDefaultTokens(cryptos);
      return cryptos;
    } catch (e) {
      logError(e.toString());
      return await getDefaultTokens();
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

  Future<bool> savedDefaultTokens(List<Crypto> cryptos) async {
    try {
      final cryptoJsonString =
          json.encode(cryptos.map((e) => e.toJson()).toList());
      return await _db.saveDynamicData(
          data: cryptoJsonString, key: defaultDataKey);
    } catch (e) {
      logError(e.toString());
      return false;
    }
  }

  Future<List<Crypto>> getSavedDefaultCrypto() async {
    try {
      final savedData = await _db.getDynamicData(key: defaultDataKey);
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
