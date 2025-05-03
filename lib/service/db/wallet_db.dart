import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:moonwallet/logger/logger.dart';

import 'package:hive_ce/hive.dart';

import 'package:moonwallet/service/db/secure_storage.dart';
import 'package:moonwallet/types/types.dart';
import 'package:moonwallet/utils/crypto.dart';
import 'package:moonwallet/utils/prefs.dart';
import 'package:web3dart/web3dart.dart';

class WalletDatabase {
  final passwordName = "userPassword";
  final secureService = SecureStorageService();
  final encryptService = EncryptService();
  final prefs = PublicDataManager();
  final boxName = "usersWallets";

  final publicWalletKey = "publicWallets";
  final privateWalletKey = "privateWallets";

  Future<Box?> getBox() async {
    try {
      await Hive.openBox(boxName);
      return Hive.box(boxName);
    } catch (e) {
      logError(e.toString());
      return null;
    }
  }

  Future<PublicData?> savePrivateData(
      {required String privatekey,
      required String password,
      required String walletName,
      String? mnemonic,
      required bool createdLocally}) async {
    try {
      final date = (DateTime.now().microsecondsSinceEpoch);
      final keyId = encryptService.generateUniqueId();
      final Credentials fromHex = EthPrivateKey.fromHex(privatekey);
      final addr = fromHex.address.hex;
      // generate a new wallet
      final SecureData privateWallet = SecureData(
          isBackup: false,
          keyId: keyId,
          privateKey: privatekey,
          walletName: walletName,
          mnemonic: mnemonic,
          createdLocally: createdLocally,
          creationDate: date);

      final PublicData publicWallet = PublicData(
          isWatchOnly: false,
          addresses: [PublicAddress(address: addr, type: NetworkType.evm)],
          keyId: keyId,
          createdLocally: createdLocally,
          walletName: walletName,
          creationDate: date);

      final dataJson = privateWallet.toJson();
      final publicDataJson = publicWallet.toJson();

      List<dynamic> listPublicDataJson;
      final publicDataResult = await getListDynamicData(name: publicWalletKey);

      if (publicDataResult != null) {
        listPublicDataJson = publicDataResult;
        log("Public data found ${json.encode(listPublicDataJson).toString()}");
      } else {
        listPublicDataJson = [];
      }

      List<dynamic> privateDataList;
      final decryptedArrayData = await getDecryptedData(password);
      if (decryptedArrayData == null) {
        throw ("Invalid Password");
      }
      privateDataList = decryptedArrayData;

      listPublicDataJson.add(publicDataJson);
      privateDataList.add(dataJson);

      final publicResult = await saveListDynamicData(
          data: listPublicDataJson, boxName: publicWalletKey);

      final privateSaveResult =
          await saveListPrivateDataJson(privateDataList, password);

      if (!privateSaveResult || !publicResult) {
        throw ("The result is $privateSaveResult and the public result is $publicResult, So error occurred");
      } else {
        prefs.saveLastConnectedData(privateWallet.keyId);
        log("Saved successfully");
        return publicWallet;
      }
    } catch (e) {
      logError(e.toString());
      return null;
    }
  }

  Future<bool> changePassword(String oldPassword, String newPassword) async {
    try {
      final dataJson = await getDecryptedData(oldPassword);
      if (dataJson == null) {
        logError("Decrypted data is null");
        throw Exception("Incorrect password ");
      }
      final String jsonDataArray = json.encode(dataJson);
      final encryptedData =
          await encryptService.encryptJson(jsonDataArray, newPassword);

      if (encryptedData != null) {
        await saveDynamicData(data: encryptedData, boxName: privateWalletKey);
        await secureService.saveDataInFSS(newPassword, passwordName);
        return true;
      } else {
        logError("An error occurred");
        return false;
      }
    } catch (e) {
      logError(e.toString());
      return false;
    }
  }

  Future<List<PublicData>> getSavedWallets() async {
    try {
      List<PublicData> accounts = [];
      final savedData = await getListDynamicData(name: publicWalletKey);

      final lastAccount = await prefs.getLastConnectedAddress();

      if (savedData != null && lastAccount != null) {
        for (final account in savedData) {
          final newAccount = PublicData.fromJson(account);
          accounts.add(newAccount);
        }
      }

      return accounts;
    } catch (e) {
      logError('Error getting saved wallets: $e');
      return [];
    }
  }

  Future<PublicData?> editWallet(
      {required PublicData account,
      List<PublicAddress>? addresses,
      String? newName,
      IconData? icon,
      bool? isBackup,
      Color? color}) async {
    try {
      List<PublicData> savedAccounts = await getSavedWallets();

      final PublicData newWallet = account.copyWith(
          walletColor: color,
          walletIcon: icon,
          walletName: newName,
          addresses: addresses,
          isBackup: isBackup);

      for (final acc in savedAccounts) {
        if (acc.keyId.trim().toLowerCase() ==
            account.keyId.trim().toLowerCase()) {
          final index = savedAccounts.indexOf(acc);
          savedAccounts[index] = newWallet;
          await saveListPublicData(savedAccounts);
          return newWallet;
        }
      }

      return null;
    } catch (e) {
      logError(e.toString());
      return null;
    }
  }

  Future<SecureData?> editPrivateWalletData({
    required SecureData account,
    required String password,
    bool? isBackup,
  }) async {
    try {
      final listSecureData = await getListSecureData(password: password);
      if (listSecureData == null) {
        throw "An error has occurred";
      }

      final SecureData newWallet = account.copyWith(isBackup: isBackup);

      for (final acc in listSecureData) {
        if (acc.keyId.trim().toLowerCase() ==
            account.keyId.trim().toLowerCase()) {
          final index = listSecureData.indexOf(acc);
          listSecureData[index] = newWallet;
          await saveListPrivateDataJson(
              listSecureData.map((e) => e.toJson()).toList(), password);
          return newWallet;
        }
      }

      return null;
    } catch (e) {
      logError(e.toString());
      return null;
    }
  }

  Future<List<dynamic>?> getDecryptedData(String password) async {
    try {
      List<dynamic> dataToSave;
      final savedData = await getDynamicData(name: privateWalletKey);

      if (savedData == null) {
        log("Data is null");
        dataToSave = [];
        return [];
      } else {
        log("Data is not null");
        final decryptData =
            await encryptService.decryptJson(savedData, password);
        if (decryptData != null) {
          dataToSave = json.decode(decryptData);
          return dataToSave;
        } else {
          logError("The password is incorrect");
          return null;
        }
      }
    } catch (e) {
      logError(e.toString());
      return null;
    }
  }

  Future<PublicData?> saveObservationWalletInStorage(
      String walletName, String address, NetworkType type) async {
    try {
      final date = (DateTime.now().microsecondsSinceEpoch);
      final keyId = encryptService.generateUniqueId();
      final addr = address;
      log("Address found : $addr");
      // generate a new wallet

      final PublicData publicWallet = PublicData(
          isBackup: true,
          createdLocally: false,
          addresses: [PublicAddress(address: address, type: type)],
          keyId: keyId,
          isWatchOnly: true,
          walletName: walletName,
          creationDate: date);

      final publicDataJson = publicWallet.toJson();
      List<dynamic> listPublicDataJson;
      final publicDataResult = await getListDynamicData(name: publicWalletKey);
      if (publicDataResult != null) {
        listPublicDataJson = publicDataResult;
        log("Public data found ${json.encode(listPublicDataJson).toString()}");
      } else {
        listPublicDataJson = [];
      }

      listPublicDataJson.add(publicDataJson);
      final publicResult = await saveListDynamicData(
          data: listPublicDataJson, boxName: publicWalletKey);
      if (!publicResult) {
        logError("The result  is $publicResult, So error occurred");
        return null;
      } else {
        prefs.saveLastConnectedData(keyId);
        log("Saved successfully");
        return publicWallet;
      }
    } catch (e) {
      logError(e.toString());
      return null;
    }
  }

  // get the savedKey if the user uses fingerprint
  Future<String?> getSavedPassword() async {
    try {
      final password = await secureService.loadDataFromFSS(passwordName);
      if (password == null) {
        return null;
      }
      return password;
    } catch (e) {
      logError(e.toString());
      return null;
    }
  }

  Future<bool> isPasswordValid(String password) async {
    try {
      final data = await getDecryptedData(password);
      return data != null && data.isNotEmpty;
    } catch (e) {
      logError(e.toString());
      return false;
    }
  }

  Future<SecureData?> getSecureData(
      {required String password, required PublicData account}) async {
    try {
      final listSecureData = await getListSecureData(password: password);
      if (listSecureData == null) {
        throw "An error has occurred";
      }

      if (listSecureData.isNotEmpty) {
        for (final e in listSecureData) {
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

  Future<List<SecureData>?> getListSecureData(
      {required String password}) async {
    try {
      final decryptedData = await getDecryptedData(password);
      if (decryptedData == null) {
        throw 'Invalid password';
      }
      final List<SecureData> listSecureData = [];
      for (final data in decryptedData) {
        final SecureData newData = SecureData.fromJson(data);
        listSecureData.add(newData);
      }
      return listSecureData;
    } catch (e) {
      logError(e.toString());
      rethrow;
    }
  }

  Future<bool> saveListPublicDataJson(List<dynamic> data) async {
    try {
      final res =
          await saveListDynamicData(data: data, boxName: publicWalletKey);
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

  Future<bool> saveListPrivateDataJson(
      List<dynamic> dataArrayJson, String password) async {
    try {
      final String jsonDataArray = json.encode(dataArrayJson);
      final encryptedData =
          await encryptService.encryptJson(jsonDataArray, password);

      if (encryptedData != null) {
        await saveDynamicData(data: encryptedData, boxName: privateWalletKey);
        await secureService.saveDataInFSS(password, passwordName);
        return true;
      } else {
        logError("An error occurred");
        return false;
      }
    } catch (e) {
      logError(e.toString());
      return false;
    }
  }

  Future<List<dynamic>?> getPublicData() async {
    try {
      return await getListDynamicData(name: publicWalletKey);
    } catch (e) {
      logError(e.toString());
      return null;
    }
  }

  Future<bool> saveListPublicData(List<PublicData> publicDataJson) async {
    try {
      final jsonDataArray = (publicDataJson.map((d) => d.toJson()).toList());
      final res = await saveListDynamicData(
          data: jsonDataArray, boxName: publicWalletKey);
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

  Future<List<dynamic>?> getListDynamicData({required String name}) async {
    try {
      final savedWallets = (await getBox())?.get(name);
      if (savedWallets == null) {
        throw "No saved wallets";
      }
      if (savedWallets != null) {
        return savedWallets;
      }
      return null;
    } catch (e) {
      logError(e.toString());
      return null;
    }
  }

  Future<bool> saveListDynamicData(
      {required List<dynamic> data, required String boxName}) async {
    try {
      final box = await getBox();
      if (box == null) {
        throw "Box Not Initialized";
      }
      box.put(boxName, data);
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

  Future<bool> saveDynamicData(
      {required String data, required String boxName}) async {
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
}
