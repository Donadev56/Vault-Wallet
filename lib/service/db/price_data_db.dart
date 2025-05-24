import 'package:moonwallet/logger/logger.dart';
import 'package:moonwallet/service/db/global_database.dart';
import 'package:moonwallet/types/account_related_types.dart';

class PriceDataDb {
  final _db = GlobalDatabase();
  final Crypto crypto;
  PriceDataDb({required this.crypto});

  String get cryptoId =>
      (crypto.isNative ? crypto.chainId.toString() : crypto.contractAddress) ??
      crypto.cryptoId;

  String get dataKey => "global/v2/crypto-price-data/of/${crypto.cryptoId}";

  Future<bool> saveData(String data) async {
    try {
      await _db.saveDynamicData(data: data, key: dataKey);
      return true;
    } catch (e) {
      logError(e.toString());
      return false;
    }
  }

  Future<String?> getData() async {
    try {
      final savedData = await _db.getDynamicData(key: dataKey);
      return savedData;
    } catch (e) {
      logError(e.toString());
      return null;
    }
  }
}
