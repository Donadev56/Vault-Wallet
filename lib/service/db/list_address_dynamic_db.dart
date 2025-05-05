import 'package:moonwallet/logger/logger.dart';
import 'package:moonwallet/service/db/global_database.dart';
import 'package:moonwallet/types/account_related_types.dart';

class ListAddressDynamicDb {
  final _db = GlobalDatabase();
  final PublicAccount account;
  final Crypto crypto;
  ListAddressDynamicDb({required this.account, required this.crypto});

  String get cryptoId =>
      (crypto.isNative ? crypto.chainId.toString() : crypto.contractAddress) ??
      crypto.cryptoId;
  String get dataKey =>
      "user/${account.addressByToken(crypto).trim().toLowerCase()}/last_used_addresses/$cryptoId/addresses-database";

  Future<bool> saveData(List<String> addresses) async {
    try {
      await _db.saveDynamicData(data: addresses, key: dataKey);
      return true;
    } catch (e) {
      logError(e.toString());
      return false;
    }
  }

  Future<List<dynamic>> getData() async {
    try {
      final savedData = await _db.getDynamicData(key: dataKey);
      return (savedData is List ? savedData : savedData) ?? [];
    } catch (e) {
      logError(e.toString());
      return [];
    }
  }
}
