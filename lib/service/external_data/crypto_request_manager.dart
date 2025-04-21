import 'dart:convert';

import 'package:moonwallet/types/types.dart';
import 'package:http/http.dart' as http;

class CryptoRequestManager {
  final baseUrl = "https://api.moonbnb.app";

  Future<List<Crypto>> getAllCryptos() async {
    try {
      final url = Uri.parse("$baseUrl/crypto/available-cryptos");

      final response = await http.get(url);
      if (response.statusCode != 200) {
        throw Exception('Failed to fetch cryptos');
      }
      return toDart(json.decode(response.body));
    } catch (e) {
      throw Exception('Failed to fetch cryptos, $e');
    }
  }

  List<Crypto> toDart(List<dynamic> data) {
    final List<Crypto> cryptos = [];
    for (final cryptoJson in data) {
      cryptos.add(Crypto.fromJsonRequest(cryptoJson as Map<String, dynamic>));
    }
    return cryptos;
  }
}
