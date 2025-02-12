import 'package:moonwallet/logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PublicDataManager {
  final prefsInstance = SharedPreferences.getInstance();

  Future<bool> saveDataInPrefs(
      {required String data, required String key}) async {
    try {
      final prefs = await prefsInstance;
      prefs.setString(key, data);
      return true;
    } catch (e) {
      logError(e.toString());
      return false;
    }
  }

  Future<bool> removeDataFromPrefs({required String key}) async {
    try {
      final prefs = await prefsInstance;
      prefs.remove(key);
      return true;
    } catch (e) {
      logError(e.toString());
      return false;
    }
  }

  Future<String?> getDataFromPrefs({required String key}) async {
    try {
      final prefs = await prefsInstance;
      return prefs.getString(key);
    } catch (e) {
      logError(e.toString());
      return null;
    }
  }

  Future<String?> getLastConnectedAddress() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('lastAccountConnected');
    } catch (e) {
      logError("Error : ${e.toString()}");
      return null;
    }
  }

  Future<bool> saveLastConnectedData(String data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('lastAccountConnected', data);
      return true;
    } catch (e) {
      logError("Error : ${e.toString()}");
      return false;
    }
  }
}
