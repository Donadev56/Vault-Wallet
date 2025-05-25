import 'package:moonwallet/logger/logger.dart';
import 'package:moonwallet/service/db/global_database.dart';

class DynamicDatabase {
  final String path;
  final _db = GlobalDatabase();

  DynamicDatabase({required this.path});

  Future<String?> getData() async {
    try {
      return await _db.getDynamicData(key: path);
    } catch (e) {
      logError(e.toString());
      return null;
    }
  }

  Future<bool> saveData(String data) async {
    try {
      return await _db.saveDynamicData(data: data, key: path);
    } catch (e) {
      logError(e.toString());
      return false;
    }
  }
}
