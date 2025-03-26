import 'package:hive_ce_flutter/adapters.dart';
import 'package:moonwallet/logger/logger.dart';
import 'package:moonwallet/types/types.dart';

class TransactionStorage {
  final String cryptoId;
  final String accountKey;
  final box = "WalletTransactions";

  TransactionStorage({
    required this.cryptoId,
    required this.accountKey,
  });
  Future<Box> getBox() async {
    try {
      final boxExist = await Hive.boxExists(box);
      if (!boxExist) {
        return await Hive.openBox(box);
      }
      return Hive.box(box);
    } catch (e) {
      logError(e.toString());
      return await Hive.openBox(box);
    }
  }

  Future<bool> addTransactions(BscScanTransaction transaction) async {
    try {
      final savedTransactions = await getTransactions();
      if (!savedTransactions.any((tr) =>
          tr.hash.trim().toLowerCase() ==
          transaction.hash.trim().toLowerCase())) {
        savedTransactions.add(transaction);
        return await saveTransactions(savedTransactions);
      }
      logError("Transaction already exists");
      return false; // Transaction already exists
    } catch (e) {
      logError('Error adding transactions: $e');
      return false;
    }
  }

  Future<List<BscScanTransaction>> getTransactions() async {
    try {
      final List<Map<dynamic, dynamic>> transactions =
          await getDynamicData(name: "$accountKey/$cryptoId");
      return transactions.map((t) => BscScanTransaction.fromJson(t)).toList();
    } catch (e) {
      logError('Error getting transactions: $e');
      return [];
    }
  }

  Future<bool> saveTransactions(List<BscScanTransaction> transactions) async {
    try {
      List<Map<dynamic, dynamic>> jsonTransactions =
          transactions.map((t) => t.toJson()).toList();
      return await saveDynamicData(
          data: jsonTransactions, boxName: "$accountKey/$cryptoId");
    } catch (e) {
      logError('Error saving transactions: $e');
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
