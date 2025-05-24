import 'dart:convert';
import 'package:moonwallet/logger/logger.dart';
import 'package:http/http.dart' as http;
import 'package:moonwallet/service/db/crypto_storage_manager.dart';
import 'package:moonwallet/service/db/global_database.dart';
import 'package:moonwallet/service/db/price_data_db.dart';
import 'package:moonwallet/service/db/price_db.dart';
import 'package:moonwallet/service/internet_manager.dart';
import 'package:moonwallet/types/account_related_types.dart';
import 'package:moonwallet/types/types.dart';
import 'package:moonwallet/utils/prefs.dart';

class PriceManager {
  final _dataName = "user/crypto/market-data";
  final _db = GlobalDatabase();
  //final baseV2Url = "http://46.202.175.219:4006";
  final baseV2Url = "https://api.moonbnb.app";
  final internet = InternetManager();

  Future<List<CryptoMarketData>> getListTokensMarketData() async {
    try {
      if (!await internet.isConnected()) {
        return await getSavedListMarketData();
      }

      final response = await http.get(
          Uri.parse("https://api.moonbnb.app/prices/all-cryptos/market-data"));
      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        final data = (jsonResponse as List<dynamic>)
            .map((e) => CryptoMarketData.fromJson(e))
            .toList();
        await saveListTokenMarketData(data);
        // final saved = await getSavedListMarketData();
        // log("Saved ${saved.length}");
        return data;
      }
      log("Response ${response.body}");
      final savedData = await getSavedListMarketData();

      return savedData;
    } catch (e) {
      logError(e.toString());
      return [];
    }
  }
/*
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
  */

  Future<String> getTokenPriceUsd(Crypto token) async {
    final db = PriceDatabase(crypto: token);

    final savedData = await db.getData();
    if (!(await internet.isConnected())) {
      log("Returning $savedData of token ${token.symbol}");

      return savedData;
    }
    try {
      final price = (await getPriceDataV2(token)).$1;
      await db.saveData(price);
      return price;
    } catch (e) {
      logError(e.toString());
    }
    return await db.getData();
  }

  Future<String> getPriceChange24h(Crypto token) async {
    final db = PriceDatabase(crypto: token);

    final savedData = await db.getPriceChange24hData();
    if (!(await internet.isConnected())) {
      return savedData;
    }
    try {
      final change = (await getPriceDataV2(token)).$2;

      await db.savePriceChangeData(change.toString());
      return change.toString();
    } catch (e) {
      logError(e.toString());
    }
    return await db.getPriceChange24hData();
  }

  (String, int) getAddressAndChainID(Crypto token) {
    final network = token.tokenNetwork;
    if (network == null) {
      throw Exception("Invalid token, network is missing");
    }

    String contractAddress = "";
    int chainId = 1;
    final tokenRef = token.refToken;
    final refChain = token.refTokenChainId;
    final tokenContract = token.contractAddress;

    if (tokenRef != null) {
      contractAddress = tokenRef;
    } else if (tokenContract != null) {
      contractAddress = tokenContract;
    }

    if (refChain != null) {
      chainId = refChain;
    } else if (network.chainId != null) {
      chainId = network.chainId!;
    }
    return (contractAddress, chainId);
  }

  Future<(String, double)> getPriceDataV2(Crypto token) async {
    try {
      final db = PriceDataDb(crypto: token);
      final chainData = getAddressAndChainID(token);
      final chainId = chainData.$2;
      final contractAddress = chainData.$1;

      if (!(await internet.isConnected())) {
        final data = await db.getData();
        if (data == null) {
          return ("0", 0.0);
        }
        final dataJson = jsonDecode(data);
        log("Data jon $dataJson");

        return (dataJson["price"] as String, dataJson["percent"] as double);
      }

      final response = await http.get(Uri.parse(
          // ignore: unnecessary_brace_in_string_interps
          "$baseV2Url/v2/tokens/tokenPriceData?tokenAddress=${contractAddress}&chainId=${chainId}"));
      if (response.statusCode == 200) {
        final dataJson = json.decode(response.body);
        await db.saveData(jsonEncode(dataJson));
        final price = dataJson["price"];
        final percent = dataJson["percent"];
        if (price != null && percent != null) {
          return (price as String, percent as double);
        }
        throw Exception("Response received but price Data is null");
      }
      // ignore: unnecessary_brace_in_string_interps
      throw Exception(
          "${response.body} For Token ${token.symbol}\n Chain ID ${chainId} \n Contract address ${contractAddress}");
    } catch (e) {
      logError(e.toString());
      rethrow;
    }
  }

  Future<List<dynamic?>> getTokenHistData(
      Crypto currentCrypto, String interval) async {
    try {
      final chainData = getAddressAndChainID(currentCrypto);
      final chainId = chainData.$2;

      final contractAddress = chainData.$1;

      return [];
    } catch (e) {
      logError(e.toString());
      return [];
    }
  }

  Future<List<dynamic>?> getPriceDataUsingCg(
      Crypto currentCrypto, String interval, String symbol) async {
    try {
      log("Crypto ${currentCrypto.toJson()}");
      final manager = CryptoStorageManager();
      final prefs = PublicDataManager();
      final name = "cryptoDataOf/${symbol}/$interval";
      final url =
          "https://api.coingecko.com/api/v3/coins/${symbol}/market_chart?vs_currency=usd&days=$interval";
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
          // log("Last update Time : $lastTime");
          // log("Current Time $currentTime");
          // log("Time remaining ${3600 - (currentTime - lastTime)}");
          if (canUseCache) {
            //  log("Getting data from local storage");
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
              "cgSymbol": symbol
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

  Future<bool> saveListTokenMarketData(List<CryptoMarketData> data) async {
    try {
      await _db.saveDynamicData(
          data: json.encode(data.map((e) => e.toJson()).toList()),
          key: _dataName);

      return true;
    } catch (e) {
      logError(e.toString());
      return false;
    }
  }

  Future<List<CryptoMarketData>> getSavedListMarketData() async {
    try {
      final savedData = await _db.getDynamicData(key: _dataName);
      if (savedData == null) {
        return [];
      }
      List<dynamic> jsonData = [];
      jsonData = json.decode(savedData);

      return jsonData.map((e) => CryptoMarketData.fromJson(e)).toList();
    } catch (e) {
      logError(e.toString());
      return [];
    }
  }
}
