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

  Future<bool> addTransactions(EsTransaction transaction) async {
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

  Future<List<EsTransaction>> getTransactions() async {
    try {
      final transactions =
          await getDynamicData(name: "transaction/of/$accountKey/$cryptoId");
          if (transactions == null) {
            throw ("Saved Transaction is null");
          }
      return( transactions as List<dynamic>).map((t) => EsTransaction.fromJson(t)).toList();
    } catch (e) {
      logError('Error getting transactions: $e');
      return [];
    }
  }

  Future<bool> patchTransactions(List<EsTransaction> transactions) async {
    try {
      final savedTransactions = await getTransactions();
      List<EsTransaction> transactionsToSave = [];

      final filteredTransaction = savedTransactions
        ..sort((a, b) => (int.tryParse(b.timeStamp) ?? 0)
            .compareTo(int.tryParse(a.timeStamp) ?? 0));

      transactionsToSave = [...transactions];

      if (savedTransactions.isNotEmpty) {
        final lastUpdateDate =
            int.tryParse(filteredTransaction.first.timeStamp) ?? 0;
        for (final trx in transactions) {
          if ((int.tryParse(trx.timeStamp) ?? 0) > lastUpdateDate) {
            transactionsToSave.add(trx);
          }
        }
      }

      return await saveTransactions(transactionsToSave);
    } catch (e) {
      logError(e.toString());
      return false;
    }
  }

  Future<bool> saveTransactions(List<EsTransaction> transactions) async {
    try {
      List<Map<dynamic, dynamic>> jsonTransactions =
          transactions.map((t) => t.toJson()).toList();
      return await saveDynamicData(
          data: jsonTransactions,
          boxName: "transaction/of/$accountKey/$cryptoId");
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
