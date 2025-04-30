import 'package:moonwallet/logger/logger.dart';
import 'package:moonwallet/service/db/global_database.dart';
import 'package:moonwallet/types/types.dart';

class BalanceDatabase {
  final _db = GlobalDatabase();
  final PublicData account;
  final Crypto crypto;
  BalanceDatabase({required this.account, required this.crypto});
  String get cryptoId =>
      (crypto.isNative ? crypto.chainId.toString() : crypto.contractAddress) ??
      crypto.cryptoId;
  String get dataKey =>
      "user/${account.address.trim().toLowerCase()}/crypto/$cryptoId/balance-database";

  Future<bool> saveData(double balance) async {
    try {
      await _db.saveDynamicData(data: balance, key: dataKey);
      return true;
    } catch (e) {
      logError(e.toString());
      return false;
    }
  }

  Future<double> getBalance() async {
    try {
      final savedData = await _db.getDynamicData(key: dataKey);
      return savedData ?? 0.0;
    } catch (e) {
      logError(e.toString());
      return 0.0;
    }
  }
}
