import 'dart:convert';
import 'package:moonwallet/logger/logger.dart';
import 'package:http/http.dart' as http;
import 'package:moonwallet/service/db/crypto_storage_manager.dart';
import 'package:moonwallet/types/types.dart';
import 'package:moonwallet/utils/prefs.dart';

class PriceManager {
  Future<List<CryptoMarketData>> getListTokensMarketData() async {
    try {
      final response = await http.get(
          Uri.parse("https://api.moonbnb.app/prices/all-cryptos/market-data"));
      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        return (jsonResponse as List<dynamic>)
            .map((e) => CryptoMarketData.fromJson(e))
            .toList();
      }
      log("Response ${response.body}");
      return [];
    } catch (e) {
      logError(e.toString());
      return [];
    }
  }

  Future<CryptoMarketData?> getTokenMarketData(String cgId) async {
    try {
      final data = await getListTokensMarketData();
      if (data.isNotEmpty) {
        final marketData = data
            .where(
                (d) => d.id.toLowerCase().trim() == cgId.toLowerCase().trim())
            .firstOrNull;
        if (marketData != null) {
          return marketData;
        }
        throw "No data found for $cgId";
      }

      throw "No data found f";
    } catch (e) {
      logError(e.toString());
      return null;
    }
  }

  Future<List<dynamic>?> getPriceDataUsingCg(
      Crypto currentCrypto, String interval) async {
    try {
      if (currentCrypto.cgSymbol == null ||
          currentCrypto.cgSymbol?.isEmpty == true) {
        throw Exception("No cg identifier provided");
      }
      log("Crypto ${currentCrypto.toJson()}");
      final manager = CryptoStorageManager();
      final prefs = PublicDataManager();
      final name = "cryptoDataOf/${currentCrypto.cgSymbol}/$interval";
      final url =
          "https://api.coingecko.com/api/v3/coins/${currentCrypto.cgSymbol}/market_chart?vs_currency=usd&days=$interval";
      log("The url ${url}");
      final uri = Uri.parse(url);

      final savedData = await manager.getSavedCryptoPriceData(
          crypto: currentCrypto, interval: interval);

      if (savedData != null) {
        final lastUpdate =
            json.decode((await (prefs.getDataFromPrefs(key: name)) ?? "{}"));

        if (lastUpdate["lastUpdate"] != null) {
          final lastTime =
              int.tryParse(lastUpdate["lastUpdate"].toString()) ?? 0;
          final currentTime = (DateTime.now().millisecondsSinceEpoch ~/ 1000);
          final canUseCache = currentTime - lastTime < 3600;
          log("Last update Time : $lastTime");
          log("Current Time $currentTime");
          log("Time remaining ${3600 - (currentTime - lastTime)}");
          if (canUseCache) {
            log("Getting data from local storage");
            return savedData;
          }
        }
      }

      return await http.get(uri).then((response) async {
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body)["prices"];

          if (data != null && (data as List<dynamic>).isNotEmpty) {
            await manager.saveCryptoPriceData(
                crypto: currentCrypto, interval: interval, data: data);
            final jsonToSave = {
              "lastUpdate": DateTime.now().millisecondsSinceEpoch ~/ 1000,
              "cgSymbol": currentCrypto.cgSymbol
            };
            await prefs.saveDataInPrefs(
                data: json.encode(jsonToSave), key: name);
            return data;
          }
        } else {
          logError("Response : ${response.body}");
        }
        return null;
      }).catchError((e) {
        logError(e.toString());
        return null;
      });
    } catch (e) {
      logError(e.toString());
      return null;
    }
  }
}
