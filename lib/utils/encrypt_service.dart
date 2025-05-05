import 'dart:convert';
import 'dart:math';
import 'package:moonwallet/logger/logger.dart';
import 'package:ulid/ulid.dart';
import 'package:cryptography/cryptography.dart';

class EncryptService {
  final algorithm = AesGcm.with256bits();

  Future<SecretKey> deriveEncryptionKey(String password, List<int> salt) async {
    final pbkdf2 = Pbkdf2(
      macAlgorithm: Hmac.sha256(),
      iterations: 100000,
      bits: 256,
    );

    final secretKey = await pbkdf2.deriveKey(
      secretKey: SecretKey(utf8.encode(password)),
      nonce: salt,
    );
    final len = (await secretKey.extractBytes()).length;
    if (len == 32) {
      return secretKey;
    }
    throw "Invalid Key length : $len";
  }

  List<int> generateSalt([int length = 16]) {
    final random = Random.secure();
    return List<int>.generate(length, (_) => random.nextInt(256));
  }

  String generateUniqueId() {
    return Ulid().toUuid();
  }

  Future<SecretBox> encrypt(String clearText, String keyBase64) async {
    try {
      final algorithm = AesGcm.with256bits();
      final secretKey = SecretKey(base64Decode(keyBase64));
      final secretBox = await algorithm.encryptString(
        clearText,
        secretKey: secretKey,
      );
      return secretBox;
    } catch (e) {
      logError(e.toString());
      rethrow;
    }
  }

  Future<String?> decrypt(List<int> cipherText, String base64key,
      List<int> nonce, List<int> mac) async {
    try {
      if (base64key.isEmpty) {
        throw Exception("Invalid Key");
      }

      final secretKey = SecretKey(base64Decode(base64key));
      final secretBox = SecretBox(cipherText, nonce: nonce, mac: Mac(mac));
      final clearText =
          await algorithm.decrypt(secretBox, secretKey: secretKey);
      return (utf8.decode(clearText));
    } catch (e) {
      logError(e.toString());
      rethrow;
    }
  }
}
