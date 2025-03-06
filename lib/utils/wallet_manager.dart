/*
import 'dart:convert';
import 'package:save_money/logger/log.dart';
import 'package:save_money/types/types.dart';
import 'package:save_money/utils/document_manager.dart';

class WalletManager {
  final String walletFileName = "db/wallets/wallet.json";

  final DocumentManager documentManager = DocumentManager();

  Future<bool> saveWallet({required Wallet wallet}) async {
    try {
      final savedFileData =
          await documentManager.readData(filePath: walletFileName);
      log("Saved File : $savedFileData");
      if (savedFileData != null) {
        final newWalletJson = wallet.toJson();
        List<dynamic> listWallets = json.decode(savedFileData);
        listWallets.add(newWalletJson);
        final savedResult = await documentManager.saveFile(
            data: json.encode(listWallets), filePath: walletFileName);
        log("Saved Result : $savedResult");
        return true;
      } else {
        final newWalletJson = [wallet.toJson()];
        final savedResult = await documentManager.saveFile(
            data: json.encode(newWalletJson), filePath: walletFileName);
        log("Saved Result : $savedResult");
        return true;
      }
    } catch (e) {
      logError(e.toString());
      return false;
    }
  }

  Future<bool> saveWallets({required List<Wallet> wallets}) async {
    try {
      List<dynamic> walletsJSON =
          wallets.map((wallet) => wallet.toJson()).toList();
      final savedResult = await documentManager.saveFile(
          data: json.encode(walletsJSON), filePath: walletFileName);
      if (savedResult != null) {
        log("Saved Result : $savedResult");
        return true;
      } else {
        log("Failed to save wallets");
        return false;
      }
    } catch (e) {
      logError(e.toString());
      return false;
    }
  }

  Future<List<dynamic>> getWallets() async {
    try {
      final savedFileData =
          await documentManager.readData(filePath: walletFileName);

      if (savedFileData != null) {
        log("Saved file : $savedFileData");
        List<dynamic> listWallets = json.decode(savedFileData);
        return listWallets;
      } else {
        return [];
      }
    } catch (e) {
      logError(e.toString());
      return [];
    }
  }
}
*/