import 'dart:convert';

import 'package:bip39/bip39.dart' as bip39;
import 'package:bip32/bip32.dart' as bip32;
import 'package:flutter/material.dart';
import 'package:moonwallet/logger/logger.dart';

import 'package:hex/hex.dart';
import 'dart:typed_data';
import 'package:hive_ce/hive.dart';

import 'package:moonwallet/service/db/secure_storage.dart';
import 'package:moonwallet/types/types.dart';
import 'package:moonwallet/utils/crypto.dart';
import 'package:web3dart/web3dart.dart';

class WalletSaver {
  final passwordName = "userPassword";
  final secureService = SecureStorageService();
  final encryptService = EncryptService();
  final boxName = "usersWallets";
  final publicWalletKey = "publicWallets";
  final privateWalletKey = "privateWallets";

  Future<Box> getBox() async {
    try {
      final boxExist = await Hive.boxExists(boxName);
      if (!boxExist) {
        return await Hive.openBox(boxName);
      }
      return Hive.box(boxName);
    } catch (e) {
      logError(e.toString());
      return await Hive.openBox(boxName);
    }
  }

  Future<Map<String, dynamic>> createPrivatekey() async {
    try {
      final seed = generateMnemonic();
      final privateKey = deriveEthereumPrivateKey(seed);

      if (privateKey == null) {
        logError("Private key is null");
        return {};
      }
      final data = {"key": privateKey, "seed": seed};

      return data;
    } catch (e) {
      logError(e.toString());
      return {};
    }
  }

  Future<Map<String, dynamic>> createPrivatekeyFromSeed(String seed) async {
    try {
      final privateKey = deriveEthereumPrivateKey(seed);
      if (privateKey == null) {
        logError("Private key is null");
        return {};
      }
      final data = {"key": privateKey, "seed": seed};

      return data;
    } catch (e) {
      logError(e.toString());
      return {};
    }
  }

  // generate a new wallet
  String generateMnemonic() {
    return bip39.generateMnemonic();
  }

  // derive Ethereum private key from mnemonic
  String? deriveEthereumPrivateKey(String mnemonic) {
    Uint8List seed = bip39.mnemonicToSeed(mnemonic);

    final bip32.BIP32 root = bip32.BIP32.fromSeed(seed);

    final bip32.BIP32 child = root.derivePath("m/44'/60'/0'/0/0");

    final privateKey = child.privateKey;
    if (privateKey == null) {
      logError("Private key is null");
      return null;
    }
    return HEX.encode(privateKey);
  }

  // save privatekey to secure storage with password
  Future<bool> savePrivatekeyInStorage(String privatekey, String password,
      String walletName, String? mnemonicToSeed) async {
    try {
      final date = (DateTime.now().microsecondsSinceEpoch);
      final keyId = encryptService.generateUniqueId();
      final Credentials fromHex = EthPrivateKey.fromHex(privatekey);
      final addr = fromHex.address.hex;
      log("Address found : $addr");
      // generate a new wallet
      final SecureData wallet = SecureData(
          address: addr,
          keyId: keyId,
          privateKey: privatekey,
          walletName: walletName,
          mnemonic: mnemonicToSeed,
          creationDate: date);

      final PublicData publicWallet = PublicData(
          isWatchOnly: false,
          address: addr,
          keyId: keyId,
          walletName: walletName,
          creationDate: date);

      final dataJson = wallet.toJson();
      final publicDataJson = publicWallet.toJson();
      List<dynamic> listPublicDataJson;
      final publicDataResult = await getListDynamicData(name: publicWalletKey);
      if (publicDataResult != null) {
        listPublicDataJson = publicDataResult;
        log("Public data found ${json.encode(listPublicDataJson).toString()}");
      } else {
        listPublicDataJson = [];
      }

      log("Saving : ${dataJson.toString()}");

      List<dynamic> dataToSave;
      final decryptedArrayData = await getDecryptedData(password);
      if (decryptedArrayData == null) {
        log("Decrypted data is null");
        return false;
      }
      dataToSave = decryptedArrayData;

      listPublicDataJson.add(publicDataJson);
      dataToSave.add(dataJson);
      final publicResult = await saveListDynamicData(
          data: listPublicDataJson, boxName: publicWalletKey);
      final result = await saveListPrivateKeyData(dataToSave, password);
      if (!result || !publicResult) {
        logError(
            "The result is $result and the public result is $publicResult, So error occurred");
        return false;
      } else {
        saveLastAccount(wallet.address);
        log("Saved successfully");
        return true;
      }
    } catch (e) {
      logError(e.toString());
      return false;
    }
  }

  Future<bool> saveLastAccount(String address) async {
    try {
      final res = encryptService.saveLastConnectedData(address);
      return res;
    } catch (e) {
      logError(e.toString());
      return false;
    }
  }

  Future<bool> saveListPrivateKeyData(
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

      final lastAccount = await encryptService.getLastConnectedAddress();

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
      String? newName,
      IconData? icon,
      Color? color}) async {
    try {
      List<PublicData> savedAccounts = await getSavedWallets();

      final PublicData newWallet = PublicData(
          walletColor: color ?? account.walletColor,
          walletIcon: icon ?? account.walletIcon,
          isWatchOnly: account.isWatchOnly,
          address: account.address,
          walletName: newName ?? account.walletName,
          creationDate: account.creationDate,
          keyId: account.keyId);

      for (final acc in savedAccounts) {
        if (acc.address.trim().toLowerCase() ==
            account.address.trim().toLowerCase()) {
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

  Future<bool> saveObservationWalletInStorage(
      String walletName, String address) async {
    try {
      final date = (DateTime.now().microsecondsSinceEpoch);
      final keyId = encryptService.generateUniqueId();
      final addr = address;
      log("Address found : $addr");
      // generate a new wallet

      final PublicData publicWallet = PublicData(
          address: addr,
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
        return false;
      } else {
        saveLastAccount(address.trim());
        log("Saved successfully");
        return true;
      }
    } catch (e) {
      logError(e.toString());
      return false;
    }
  }

  // get the savedKey if the user use fingerprint
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

  /* Future<bool> saveListPublicData ({required List<PublicData> wallets}) async {
    try {
      final Store store = await openStore(directory: 'person-db');

    } catch (e) {
      logError(e.toString());
      return false;
      
    }
  }*/
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
      final savedWallets = (await getBox()).get(name);
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
      {required dynamic data, required String boxName}) async {
    try {
      final box = await getBox();
      box.put(boxName, data);
      return true;
    } catch (e) {
      logError(e.toString());
      return false;
    }
  }
}
