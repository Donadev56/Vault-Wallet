import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:moonwallet/logger/logger.dart';

import 'package:hive_ce/hive.dart';
import 'package:moonwallet/service/address_manager.dart';
import 'package:moonwallet/service/db/crypto_storage_manager.dart';

import 'package:moonwallet/service/db/secure_storage.dart';
import 'package:moonwallet/service/db/wallet_db_keys.dart';
import 'package:moonwallet/service/external_data/crypto_request_manager.dart';
import 'package:moonwallet/types/account_related_types.dart';
import 'package:moonwallet/types/exception.dart';
import 'package:moonwallet/utils/encrypt_service.dart';
import 'package:moonwallet/utils/prefs.dart';

class WalletDatabase {
  final _secureService = SecureStorageService();
  final _encryptService = EncryptService();
  final _prefs = PublicDataManager();
  final _addressManager = AddressManager();
  final _keys = WalletKeys();
  final cryptoRequestManager = CryptoRequestManager();

  Future<Box?> getBox() async {
    try {
      await Hive.openBox(_keys.boxName);
      return Hive.box(_keys.boxName);
    } catch (e) {
      logError(e.toString());
      return null;
    }
  }

  Future<DerivateKeys> _deriveEncryptionKey(String password) async {
    try {
      List<int> salt = [];
      final savedDerivationInfo = await getDerivationInfo();

      if (savedDerivationInfo == null) {
        salt = _encryptService.generateSalt();
      } else {
        salt = savedDerivationInfo.salt;
      }
      final secretKey =
          await _encryptService.deriveEncryptionKey(password, salt);

      final rawKey = await secretKey.extractBytes();
      final keyBase64 = base64Encode(rawKey);

      return DerivateKeys(derivateKey: keyBase64, salt: salt);
    } catch (e) {
      logError(e.toString());
      rethrow;
    }
  }

  Future<DerivateKeys> deriveEncryptionKeyStateless(String password) async {
    try {
      List<int> salt = [];
      final savedDerivationInfo = await getDerivationInfo();
      if (savedDerivationInfo == null) {
        throw Exception();
      }

      salt = savedDerivationInfo.salt;

      final secretKey =
          await _encryptService.deriveEncryptionKey(password, salt);

      final rawKey = await secretKey.extractBytes();
      final keyBase64 = base64Encode(rawKey);
      return DerivateKeys(derivateKey: keyBase64, salt: salt);
    } catch (e) {
      logError(e.toString());
      rethrow;
    }
  }

  Future<List<PrivateAccount>> _getListPrivateAccount(
      List<dynamic> listPublicAccount, String deriveKeyBase64) async {
    final encryptedPrivateData =
        await getDynamicData(name: _keys.privateWalletKey);
    if (encryptedPrivateData == null ||
        (encryptedPrivateData as List<int>).isEmpty) {
      return [];
    }
    final encryptInfo = await getEncryptionInfo();
    if (encryptInfo == null) {
      throw Exception();
    }

    final decryptedPrivateData = await _encryptService.decrypt(
        encryptedPrivateData,
        deriveKeyBase64,
        encryptInfo.nonce,
        encryptInfo.mac);
    if (listPublicAccount.isNotEmpty && decryptedPrivateData == null) {
      throw InvalidPasswordException();
    }

    if (decryptedPrivateData == null) {
      return [];
    }

    final List<dynamic> privateDataJson = json.decode(decryptedPrivateData);
    return privateDataJson.map((e) => PrivateAccount.fromJson(e)).toList();
  }

  Future<List<PublicAccount>> getListPublicAccount() async {
    final List<dynamic>? data =
        await getDynamicData(name: _keys.publicWalletKey);
    if (data == null) {
      return [];
    }
    return data.map((e) => PublicAccount.fromJson(e)).toList();
  }

  Future<List<Crypto>> getCompatibleCryptos(PublicAccount account) async {
    try {
      final listCrypto = await cryptoRequestManager.getDefaultTokens() ?? [];
      List<Crypto> compatibleCrypto = [];
      if (account.origin.isMnemonic) {
        return listCrypto;
      }

      if (account.origin.isPrivateKey || account.origin.isPublicAddress) {
        compatibleCrypto = listCrypto
            .where((e) =>
                e.getNetworkType == account.supportedNetworks.firstOrNull)
            .toList();
      }

      return compatibleCrypto
          .map((e) => e.isNative ? e.copyWith(canDisplay: true) : e)
          .toList();
    } catch (e) {
      logError(e.toString());
      return [];
    }
  }

  Future<PublicAccount?> savePrivateData(
      {required String password,
      required String walletName,
      required Origin origin,
      required List<NetworkType> networks,
      required String keyOrigin,
      required bool createdLocally}) async {
    try {
      if (origin.isPublicAddress) {
        throw "Cannot use this function for public watch only accounts";
      }

      if (networks.isEmpty) {
        throw "An account should have at last one compatible network";
      }

      // current date ;
      final date = (DateTime.now().millisecondsSinceEpoch / 1000).toInt();
      final keyId = _encryptService.generateUniqueId();
      final accountAddresses = await _addressManager.generateAddressFromOrigin(
          keyOrigin, origin, networks);

      // this _derivateEncryptionKeyStateFull will automatically update the state if necessary
      final derive = await _deriveEncryptionKey(password);
      // create a new  private wallet

      final PrivateAccount privateWallet = PrivateAccount(
          origin: origin,
          supportedNetworks: networks,
          isBackup: false,
          keyId: keyId,
          walletName: walletName,
          keyOrigin: keyOrigin,
          createdLocally: createdLocally,
          creationDate: date);
      // create a new public wallet associated with private wallet by keyId

      final PublicAccount publicWallet = PublicAccount(
          origin: origin,
          supportedNetworks: networks,
          isWatchOnly: false,
          addresses: accountAddresses,
          keyId: keyId,
          createdLocally: createdLocally,
          walletName: walletName,
          creationDate: date);

      List<PublicAccount> listPublicAccount = await getListPublicAccount();
      List<PrivateAccount> privateDataList =
          await _getListPrivateAccount(listPublicAccount, derive.derivateKey);

      privateDataList.add(privateWallet);
      listPublicAccount.add(publicWallet);
      log("Saving data");
      await saveListPrivateDataJson(privateDataList, derive.derivateKey);

      await saveDynamicData(
          data: listPublicAccount.map((e) => e.toJson()).toList(),
          boxName: _keys.publicWalletKey);
      await saveDerivationInfo(
          DerivateKeys(derivateKey: derive.derivateKey, salt: derive.salt));

      _prefs.saveLastConnectedData(privateWallet.keyId);
      if (publicWallet.origin.isPrivateKey) {
        final listCrypto = await getCompatibleCryptos(publicWallet);
        await CryptoStorageManager()
            .saveListCrypto(cryptos: listCrypto, wallet: publicWallet);
      }
      log("Saved successfully");
      return publicWallet;
    } catch (e) {
      logError(e.toString());
      return null;
    }
  }

  Future<List<PrivateAccount>> getAlreadySavedListPrivateAccount(
      String derivateKey) async {
    try {
      final savedData = await getDynamicData(name: _keys.privateWalletKey);
      if (savedData == null) {
        throw "Saved Private Data not found";
      }
      if ((savedData as List<int>).isEmpty) {
        throw Exception("Invalid saved Data format");
      }

      final encryptInfo = await getEncryptionInfo();
      if (encryptInfo == null) {
        throw Exception();
      }
      final decryptedData = await _encryptService.decrypt(
          savedData, derivateKey, encryptInfo.nonce, encryptInfo.mac);
      if (decryptedData == null) {
        throw InvalidPasswordException();
      }
      List<dynamic> dataJson = json.decode(decryptedData);
      return dataJson.map((e) => PrivateAccount.fromJson(e)).toList();
    } catch (e) {
      logError(e.toString());
      rethrow;
    }
  }

  Future<bool> changePassword(String oldPassword, String newPassword) async {
    try {
      final oldDerive = await deriveEncryptionKeyStateless(oldPassword);
      final newDerivateKey =
          await _encryptService.generateNewSecretKey(newPassword);

      final alreadySavedData =
          await getAlreadySavedListPrivateAccount(oldDerive.derivateKey);
      if (alreadySavedData.isEmpty) {
        throw "No decrypted data found";
      }

      await saveSecureData(alreadySavedData, newDerivateKey.derivateKey);
      await saveDerivationInfo(newDerivateKey);

      return true;
    } catch (e) {
      logError(e.toString());
      rethrow;
    }
  }

  Future<PublicAccount?> editWallet(
      {required PublicAccount account,
      List<PublicAddress>? addresses,
      String? newName,
      IconData? icon,
      bool? isBackup,
      Color? color}) async {
    try {
      List<PublicAccount> savedAccounts = await getListPublicAccount();

      final PublicAccount newWallet = account.copyWith(
          walletColor: color,
          walletIcon: icon,
          walletName: newName,
          addresses: addresses,
          isBackup: isBackup);

      final index = savedAccounts.indexWhere((e) =>
          e.keyId.toLowerCase().trim() == account.keyId.toLowerCase().trim());
      if (index < 0) {
        throw "Wallet not found";
      }
      savedAccounts[index] = newWallet;
      await saveListPublicAccount(savedAccounts);
      return newWallet;
    } catch (e) {
      logError(e.toString());
      return null;
    }
  }

  Future<PrivateAccount?> editPrivateWalletData({
    required PrivateAccount account,
    required String deriveKey,
    bool? isBackup,
  }) async {
    try {
      final listPrivateAccount =
          await getAlreadySavedListPrivateAccount(deriveKey);

      if (listPrivateAccount.isEmpty) {
        throw "Private account is empty";
      }
      final deriveInfo = await getDerivationInfo();
      if (deriveInfo == null) {
        throw Exception("Derive info is null");
      }

      final PrivateAccount newWallet = account.copyWith(isBackup: isBackup);
      final targetAccountIndex = listPrivateAccount.indexWhere((e) =>
          e.keyId.trim().toLowerCase() == account.keyId.trim().toLowerCase());

      if (targetAccountIndex < 0) {
        throw "Account not found";
      }
      listPrivateAccount[targetAccountIndex] = newWallet;
      await saveListPrivateDataJson(listPrivateAccount, deriveKey);
      return newWallet;
    } catch (e) {
      logError(e.toString());
      return null;
    }
  }

  Future<EncryptionInfo?> getEncryptionInfo() async {
    try {
      final data =
          await _secureService.loadDataFromFSS(_keys.encryptionInfoKey);
      if (data == null) {
        throw "Data not found";
      }
      final jsonData = json.decode(data);
      return EncryptionInfo.fromJson(jsonData);
    } catch (e) {
      logError(e.toString());
      return null;
    }
  }

  Future<DerivateKeys?> getDerivationInfo() async {
    try {
      final data = await _secureService.loadDataFromFSS(_keys.derivationInfo);
      if (data == null) {
        throw "Data not found";
      }
      return DerivateKeys.fromJson(json.decode(data));
    } catch (e) {
      logError(e.toString());
      return null;
    }
  }

  Future<bool> saveEncryptionInfo(EncryptionInfo info) async {
    try {
      final jsonInfo = json.encode(info.toJson());
      await _secureService.saveDataInFSS(jsonInfo, _keys.encryptionInfoKey);
      return true;
    } catch (e) {
      logError(e.toString());
      return false;
    }
  }

  Future<bool> saveDerivationInfo(DerivateKeys info) async {
    try {
      final jsonInfo = json.encode(info.toJson());
      await _secureService.saveDataInFSS(jsonInfo, _keys.derivationInfo);
      return true;
    } catch (e) {
      logError(e.toString());
      return false;
    }
  }

  Future<bool> saveListPrivateDataJson(
      List<PrivateAccount> dataArrayJson, String derivateKey) async {
    try {
      return await saveSecureData(dataArrayJson, derivateKey);
    } catch (e) {
      logError(e.toString());
      rethrow;
    }
  }

  Future<bool> saveSecureData(
      List<PrivateAccount> data, String derivateKey) async {
    try {
      final secretBox =
          await _encryptService.encrypt(data.toJsonString(), derivateKey);

      await saveDynamicData(
          data: secretBox.cipherText, boxName: _keys.privateWalletKey);
      await saveEncryptionInfo(
          EncryptionInfo(mac: secretBox.mac.bytes, nonce: secretBox.nonce));
      return true;
    } catch (e) {
      logError(e.toString());
      rethrow;
    }
  }

  Future<bool> saveListPublicAccount(List<PublicAccount> publicAccount) async {
    try {
      final jsonDataArray = (publicAccount.map((d) => d.toJson()).toList());
      final res = await saveDynamicData(
          data: jsonDataArray, boxName: _keys.publicWalletKey);
      if (res) {
        return true;
      } else {
        return false;
      }
    } catch (e) {
      logError(e.toString());
      return false;
    }
  }

  Future<bool> saveDynamicData(
      {required dynamic data, required String boxName}) async {
    try {
      final box = await getBox();
      if (box == null) {
        throw "Box Not Initialized";
      }
      await box.put(boxName, data);
      return true;
    } catch (e) {
      logError(e.toString());
      return false;
    }
  }

  Future<dynamic> getDynamicData({required String name}) async {
    try {
      final box = await getBox();
      if (box == null) {
        throw "Box Not Initialized";
      }
      final savedWallets = box.get(name);
      if (savedWallets != null) {
        return savedWallets;
      }
      return null;
    } catch (e) {
      logError(e.toString());
      return null;
    }
  }
}
