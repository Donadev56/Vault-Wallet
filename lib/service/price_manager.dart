import 'dart:convert';

import 'package:moonwallet/custom/candlesticks/lib/candlesticks.dart';
import 'package:moonwallet/logger/logger.dart';
import 'package:http/http.dart' as http;
import 'package:moonwallet/types/types.dart';

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
            'Error fetching price from Binance API for $symbol: statusCode=${response.statusCode}');
        return 0;
      }
    } catch (e) {
      logError('Error getting price: $e');
      return 0;
    }
  }

  Future<List<double>> getPriceOfAvailableCryptos(List<Crypto> crypto) async {
    try {
      final response = await http
          .get(Uri.parse('https://api.binance.com/api/v3/ticker/price'));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        List<double> prices = [];

        for (var entry in data) {
          String symbol = entry['symbol'];
          double price = double.parse(entry['price']);
          if (crypto.any((c) => c.binanceSymbol == symbol)) {
            prices.add(price);
          }
        }
        return prices;
      } else {
        logError(
            'Error fetching available cryptos from Binance API: statusCode=${response.statusCode}');
        return [];
      }
    } catch (e) {
      logError('Error getting price of available cryptos: $e');
      return [];
    }
  }

  Future<List<Candle>> getChartPriceDataUsingBinanceApi(
      String symbol, String interval) async {
    log("Getting the chart price for ${symbol}");

    try {
      final result = await http.get(Uri.parse(
          "https://api.binance.com/api/v3/klines?symbol=$symbol&interval=$interval&limit=500"));
      if (result.statusCode == 200) {
        final data = json.decode(result.body) as List<dynamic>;

        List<Candle> chartData = [];

        for (var entry in data) {
          chartData.add(Candle(
            date: DateTime.fromMillisecondsSinceEpoch(entry[0]),
            open: double.parse(entry[1]),
            high: double.parse(entry[2]),
            low: double.parse(entry[3]),
            close: double.parse(entry[4]),
            volume: double.parse(entry[5]),
          ));
        }

        return chartData;
      } else {
        logError(
            'Error fetching chart data from Binance API: statusCode=$result.statusCode');
        return [];
      }
    } catch (e) {
      logError('Error getting chart data: $e');
      return [];
    }
  }

  Future<Map<String, double>> checkCryptoTrend(String symbol) async {
    try {
      final priceResponse = await http.get(Uri.parse(
          'https://api.binance.com/api/v3/ticker/price?symbol=$symbol'));
      if (priceResponse.statusCode == 200) {
        final priceData = json.decode(priceResponse.body);
        double currentPrice = double.parse(priceData['price']);

        final klineResponse = await http.get(Uri.parse(
            'https://api.binance.com/api/v3/klines?symbol=$symbol&interval=1d&limit=2'));
        if (klineResponse.statusCode == 200) {
          final klineData = json.decode(klineResponse.body);
          double previousClosePrice = double.parse(klineData[0][4]);

          double priceChangePercent =
              ((currentPrice - previousClosePrice) / previousClosePrice) * 100;

          return {"percent": priceChangePercent, "price": currentPrice};
        }
      }
      return {};
    } catch (e) {
      log('Error: $e');
      return {};
    }
  }
}
