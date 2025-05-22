import 'package:moonwallet/logger/logger.dart';
import 'package:moonwallet/service/db/global_database.dart';
import 'package:moonwallet/types/account_related_types.dart';

class PriceDatabase {
  final _db = GlobalDatabase();
  final Crypto crypto;
  PriceDatabase({required this.crypto});

  String get cryptoId =>
      (crypto.isNative ? crypto.chainId.toString() : crypto.contractAddress) ??
      crypto.cryptoId;

  String get dataKey => "global/crypto-price/of/${crypto.cryptoId}";
  String get priceChange24hDataKey =>
      "global/crypto-price-change-24h/of/${crypto.cryptoId}";

  Future<bool> saveData(String price) async {
    try {
      await _db.saveDynamicData(data: price, key: dataKey);
      return true;
    } catch (e) {
      logError(e.toString());
      return false;
    }
  }

  Future<bool> savePriceChangeData(String price) async {
    try {
      await _db.saveDynamicData(data: price, key: priceChange24hDataKey);
      return true;
    } catch (e) {
      logError(e.toString());
      return false;
    }
  }

  Future<String> getPriceChange24hData() async {
    try {
      final savedData = await _db.getDynamicData(key: priceChange24hDataKey);
      return savedData is double ? savedData.toString() : savedData ?? "0";
    } catch (e) {
      logError(e.toString());
      return "0";
    }
  }

  Future<String> getData() async {
    try {
      final savedData = await _db.getDynamicData(key: dataKey);
      return savedData is double ? savedData.toString() : savedData ?? "0";
    } catch (e) {
      logError(e.toString());
      return "0";
    }
  }
}
