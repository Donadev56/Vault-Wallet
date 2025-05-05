import 'dart:convert';

import 'package:moonwallet/logger/logger.dart';
import 'package:moonwallet/service/db/wallet_db.dart';
import 'package:moonwallet/service/db/wallet_db_keys.dart';
import 'package:moonwallet/types/account_related_types.dart';
import 'package:moonwallet/utils/encrypt_service.dart';
import 'package:moonwallet/utils/prefs.dart';

class WalletDbStateLess extends WalletDatabase {
  final _encryptService = EncryptService();
  final _prefs = PublicDataManager();
  final _keys = WalletKeys();

  Future<String> derivateEncryptionKeyStateless(String password) async {
    try {
      final deriveInfo = await getDerivationInfo();
      if (deriveInfo == null) {
        throw Exception("Derive info is null");
      }
      final secretKey =
          await _encryptService.deriveEncryptionKey(password, deriveInfo.salt);
      final rawKey = await secretKey.extractBytes();
      return base64Encode(rawKey);
    } catch (e) {
      logError(e.toString());
      rethrow;
    }
  }

  Future<PublicAccount?> saveObservationWalletInStorage(
      String walletName,
      String address,
      NetworkType type,
      List<NetworkType> supportedNetworks) async {
    try {
      final date = (DateTime.now().millisecondsSinceEpoch / 1000).toInt();
      final keyId = _encryptService.generateUniqueId();

      final publicWallet = PublicAccount(
          origin: Origin.publicAddress,
          supportedNetworks: supportedNetworks,
          isBackup: true,
          createdLocally: false,
          addresses: [PublicAddress(address: address, type: type)],
          keyId: keyId,
          isWatchOnly: true,
          walletName: walletName,
          creationDate: date);

      List<dynamic> listPublicAccount = [];
      final publicAccountsResult =
          await getDynamicData(name: _keys.publicWalletKey);

      if (publicAccountsResult != null) {
        listPublicAccount = publicAccountsResult;
      }
      listPublicAccount.add(publicWallet.toJson());
      await saveDynamicData(
          data: listPublicAccount, boxName: _keys.publicWalletKey);
      await _prefs.saveLastConnectedData(keyId);
      return publicWallet;
    } catch (e) {
      logError(e.toString());
      return null;
    }
  }

  Future<List<dynamic>?> decryptPrivateDataUsingKey(String deriveKey) async {
    try {
      final savedData = await getDynamicData(name: _keys.privateWalletKey);
      final encryptInfo = await getEncryptionInfo();

      if (savedData == null || encryptInfo == null) {
        return [];
      }

      final decryptData = await _encryptService.decrypt(
          savedData, deriveKey, encryptInfo.nonce, encryptInfo.mac);

      if (decryptData != null) {
        log("Decrypted data $decryptData");
        return json.decode(decryptData);
      }
      throw "Invalid Key";
    } catch (e) {
      logError(e.toString());
      rethrow;
    }
  }

  Future<List<dynamic>?> getDecryptedDataUsingPassword(String password) async {
    try {
      final deriveKey = await derivateEncryptionKeyStateless(password);
      final data = await decryptPrivateDataUsingKey(deriveKey);
      if (data != null) {
        return data;
      }
      throw ("The password is invalid");
    } catch (e) {
      logError(e.toString());
      rethrow;
    }
  }

  Future<List<dynamic>?> getDecryptedDataUsingKey(String deriveKey) async {
    try {
      final data = await decryptPrivateDataUsingKey(deriveKey);
      if (data != null) {
        return data;
      }
      throw "Invalid Derivate key";
    } catch (e) {
      logError(e.toString());
      rethrow;
    }
  }

  // get the savedKey if the user uses fingerprint
  Future<String?> getSavedDeriveKey() async {
    try {
      final deriveKeyInfo = await getDerivationInfo();
      if (deriveKeyInfo != null) {
        return deriveKeyInfo.derivateKey;
      }
      return null;
    } catch (e) {
      logError(e.toString());
      return null;
    }
  }

  Future<bool> isPasswordValid(String password) async {
    try {
      final data = await getDecryptedDataUsingPassword(password);
      return data != null && data.isNotEmpty;
    } catch (e) {
      logError(e.toString());
      return false;
    }
  }

  Future<PrivateAccount?> getPrivateAccountUsingKey(
      {required String deriveKey, required PublicAccount account}) async {
    try {
      final listPrivateAccount =
          await getAlreadySavedListPrivateAccount(deriveKey);
      if (listPrivateAccount.isEmpty) {
        throw "An error has occurred";
      }

      if (listPrivateAccount.isNotEmpty) {
        for (final e in listPrivateAccount) {
          if (e.keyId.trim().toLowerCase() == account.keyId.toLowerCase()) {
            return e;
          }
        }
      }

      return null;
    } catch (e) {
      logError(e.toString());

      rethrow;
    }
  }

  Future<PrivateAccount?> getPrivateAccountUsingPassword(
      {required String password, required PublicAccount account}) async {
    try {
      final deriveKey = await derivateEncryptionKeyStateless(password);
      return getPrivateAccountUsingKey(deriveKey: deriveKey, account: account);
    } catch (e) {
      logError(e.toString());

      rethrow;
    }
  }
}
