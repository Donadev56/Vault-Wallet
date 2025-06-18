import 'dart:convert';
import 'package:moonwallet/logger/logger.dart';
import 'package:http/http.dart' as http;
import 'package:moonwallet/service/db/dynamic_bd.dart';
import 'package:moonwallet/service/db/global_database.dart';
import 'package:moonwallet/service/db/price_data_db.dart';
import 'package:moonwallet/service/db/price_db.dart';
import 'package:moonwallet/service/internet_manager.dart';
import 'package:moonwallet/types/account_related_types.dart';
import 'package:moonwallet/types/news_types.dart';
import 'package:moonwallet/types/types.dart';
import 'package:moonwallet/utils/prefs.dart';

class PriceManager {
  final _dataName = "user/crypto/market-data";
  final _db = GlobalDatabase();
  //final baseV2Url = "http://46.202.175.219:4006";
  final baseV2Url = "https://api.moonbnb.app";
  final internet = InternetManager();
  final prefs = PublicDataManager();
  final maxCacheTime = 300;

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
      final data = await db.getData();
      final now = (DateTime.now().millisecondsSinceEpoch / 1000).toInt();

      final url =
          "$baseV2Url/v2/tokens/tokenPriceData?tokenAddress=${contractAddress}&chainId=${chainId}";
      final lastUpdate = await prefs.getDataFromPrefs(key: url);

      if (lastUpdate != null) {
        if (now - int.parse(lastUpdate) < maxCacheTime) {
          if (data != null) {
            final dataJson = jsonDecode(data);
            log("---- GETTING LOCAL PRICE DATA ----");

            return (dataJson["price"] as String, dataJson["percent"] as double);
          }
        }
      }

      if (!(await internet.isConnected())) {
        if (data == null) {
          return ("0", 0.0);
        }
        final dataJson = jsonDecode(data);
        log("Data jon $dataJson");

        return (dataJson["price"] as String, dataJson["percent"] as double);
      }

      final response = await http.get(Uri.parse(
          // ignore: unnecessary_brace_in_string_interps
          url));
      if (response.statusCode == 200) {
        final dataJson = json.decode(response.body);
        await db.saveData(jsonEncode(dataJson));
        await prefs.saveDataInPrefs(data: now.toString(), key: url);
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

  Future<List<CryptoMarketData>> fetchTokensMarketData() async {
    try {
      final url = '$baseV2Url/v2/tokens/tokensMarketData';
      final db = DynamicDatabase(path: url);
      final savedData = await db.getData();
      if (!(await internet.isConnected())) {
        if (savedData != null) {
          final savedJson = jsonDecode(savedData);
          return (savedJson as List)
              .map((e) => CryptoMarketData.fromJson(e))
              .toList();
        }
      }
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        await db.saveData(response.body);
        return (data as List).map((e) => CryptoMarketData.fromJson(e)).toList();
      }
      if (savedData != null) {
        final savedJson = jsonDecode(savedData);
        return (savedJson as List)
            .map((e) => CryptoMarketData.fromJson(e))
            .toList();
      }

      return [];
    } catch (e) {
      logError(e.toString());
      return [];
    }
  }

  Future<NewsData?> fetchNewsData() async {
    try {
      final url = '$baseV2Url/v2/tokens/news';
      final db = DynamicDatabase(path: url);
      final savedData = await db.getData();
      if (!(await internet.isConnected())) {
        if (savedData != null) {
          return NewsData.fromJson(jsonDecode(savedData));
        }
      }
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        await db.saveData(response.body);

        return NewsData.fromJson(data);
      }
      if (savedData != null) {
        return NewsData.fromJson(jsonDecode(savedData));
      }

      return null;
    } catch (e) {
      logError(e.toString());
      return null;
    }
  }

  Future<String?> getCgIdByContractAddress(
      String address, int networkCgId) async {
    try {
      final url =
          "https://api.coingecko.com/api/v3/coins/$networkCgId/contract/$address";
      final fallBackUrl =
          "https://api.coingecko.com/api/v3/coins/ethereum/contract/$address";

      final firstTry = await http.get(
        Uri.parse(url),
      );

      if (firstTry.statusCode == 200) {
        final json = jsonDecode(firstTry.body);
        final id = json["id"];
        if (id != null) {
          log("Coingecko from first try id Found for $address \n");
          log("Id :$id");

          return id;
        }
      }
      final secondTry = await http.get(Uri.parse(fallBackUrl));
      if (secondTry.statusCode == 200) {
        final json = jsonDecode(secondTry.body);
        final id = json["id"];
        if (id != null) {
          log("Coingecko from second try id Found for $address \n");
          log("Id :$id");

          return id;
        }
      }

      logError("No Id Found");
      return null;
    } catch (e) {
      logError(e.toString());
      return null;
    }
  }

  Future<List<dynamic>> getTokenHistData(
      Crypto currentCrypto, String interval) async {
    try {
      if (currentCrypto.isNative) {
        return await getPriceDataUsingGeckoId(
                interval, currentCrypto.cgSymbol ?? '') ??
            [];
      }
      final addressAndChainId = getAddressAndChainID(currentCrypto);
      final contract = addressAndChainId.$1;
      final chainId = addressAndChainId.$2;
      if (contract.isEmpty) {
        logError("Invalid Contract address");
        return [];
      }

      final key = "coinGeckoId/of/$contract/in-chain/${chainId}";
      final data = await prefs.getDataFromPrefs(key: key);
      if (data != null) {
        return await getPriceDataUsingGeckoId(interval, data) ?? [];
      }

      final coingeckoId = await getCgIdByContractAddress(contract, chainId);
      if (coingeckoId != null) {
        await prefs.saveDataInPrefs(data: coingeckoId, key: key);
        return await getPriceDataUsingGeckoId(interval, coingeckoId) ?? [];
      }

      return [];
    } catch (e) {
      logError(e.toString());
      return [];
    }
  }

  Future<List<dynamic>?> getPriceDataUsingGeckoId(
      String interval, String symbol) async {
    try {
      final prefs = PublicDataManager();
      final url =
          "https://api.coingecko.com/api/v3/coins/${symbol}/market_chart?vs_currency=usd&days=$interval";
      final db = DynamicDatabase(path: url);
      final uri = Uri.parse(url);
      final now = (DateTime.now().millisecondsSinceEpoch ~/ 1000);
      final savedData = await db.getData();

      if (savedData != null) {
        final lastUpdate = (await prefs.getDataFromPrefs(key: url));

        if (lastUpdate != null) {
          final lastTime = int.tryParse(lastUpdate) ?? 0;
          final canUseCache = now - lastTime < 3600;
          if (canUseCache) {
            log("GETTING DATA FROM CACHE");
            final prices = jsonDecode(savedData)["prices"];
            return prices;
          }
        }
      }
      log("GETTING FRESH DATA");
      return await http.get(uri).then((response) async {
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body)["prices"];

          if (data != null && (data as List<dynamic>).isNotEmpty) {
            await db.saveData(response.body);
            await prefs.saveDataInPrefs(data: now.toString(), key: url);

            return data;
          }
          return [];
        }
      }).catchError((e) {
        if (savedData != null) {
          return ((jsonDecode(savedData)["prices"]) as List)
              .map((e) => CryptoMarketData.fromJson(e))
              .toList();
        }
        return [];
      });
    } catch (e) {
      logError(e.toString());
      return [];
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
