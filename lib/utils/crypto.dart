import 'dart:convert';
import 'package:encrypt/encrypt.dart';
import 'package:moonwallet/logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ulid/ulid.dart';

class EncryptService {
  Future<String?> encryptJson(String jsonData, String password) async {
    try {
      final key = Key.fromUtf8(password.padRight(32, "*"));
      final iv = IV.fromLength(16);
      final encrypter = Encrypter(AES(key, mode: AESMode.cbc));
      final encrypted = encrypter.encrypt(jsonData, iv: iv);
      final encryptedData = {
        "iv": base64Encode(iv.bytes),
        "ecr": encrypted.base64
      };

      log("Data encrypted and saved successfully");

      return jsonEncode(encryptedData);
    } catch (e) {
      logError(e.toString());
      return null;
    }
  }

  Future<String?> decryptJson(String encryptedJson, String password) async {
    try {
      final Map<String, dynamic> encryptedData = jsonDecode(encryptedJson);

      final iv = IV.fromBase64(encryptedData['iv']);
      final encryptedText = encryptedData['ecr'];

      final key = Key.fromUtf8(password.padRight(32, "*"));
      final encrypter = Encrypter(AES(key, mode: AESMode.cbc));

      final decrypted = encrypter.decrypt64(encryptedText, iv: iv);

      log("Data decrypted successfully");
      return decrypted;
    } catch (e) {
      logError("Erreur : ${e.toString()}");
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

  String generateUniqueId() {
    return Ulid().toUuid();
  }
}
