import 'dart:convert';

import 'package:moonwallet/logger/logger.dart';
import 'package:http/http.dart' as http;

class PriceManager {
  Future<double> getPriceUsingBinanceApi(String symbol) async {
    try {
      if (symbol.isEmpty) {
        logError('Symbol is empty');
        return 0;
      }
      final baseUrl = "https://api.binance.com/api/v3/ticker/price?symbol=";
      final response = await http.get(Uri.parse(baseUrl + symbol));
      if (response.statusCode == 200) {
        final price = json.decode(response.body)["price"];
        return double.parse(price);
      } else {
        logError(
            'Error fetching price from Binance API: statusCode=$response.statusCode');
        return 0;
      }
    } catch (e) {
      logError('Error getting price: $e');
      return 0;
    }
  }
}
