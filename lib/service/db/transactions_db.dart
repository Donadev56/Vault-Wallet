import 'package:moonwallet/logger/logger.dart';
import 'package:moonwallet/service/db/global_database.dart';
import 'package:moonwallet/types/account_related_types.dart';
import 'package:moonwallet/types/transaction.dart';

class TransactionStorage {
  final Crypto token;
  final PublicAccount account;
  final db = GlobalDatabase();

  TransactionStorage({
    required this.token,
    required this.account,
  });

  String get address => account.addressByToken(token);
  String get identifier =>
      (token.isNative ? token.cryptoId : token.contractAddress) ??
      token.cryptoId;

  String get dbKeyName => "/transactions/of/$address/&/$identifier/test6";

  Future<List<Transaction>> patchTransactions(
      List<Transaction> transactions) async {
    try {
      log("Transactions received ${transactions.length}");
      final savedTransactions = await getSavedTransactions();
      if (savedTransactions.isEmpty) {
        await saveTransactions(transactions);
        return transactions;
      }
      List<Transaction> transactionsToSave = [];

      final filteredTransaction = savedTransactions
        ..sort((a, b) => b.timeStamp.compareTo(a.timeStamp));

      transactionsToSave = [...filteredTransaction];
      log("Transactions ${transactionsToSave.firstOrNull}");

      if (transactionsToSave.isNotEmpty) {
        final lastUpdateDate = transactionsToSave.first.timeStamp;
        for (final trx in transactions) {
          if (trx.timeStamp > lastUpdateDate) {
            transactionsToSave.add(trx);
          }
        }
      }

      await saveTransactions(transactionsToSave);
      return transactionsToSave;
    } catch (e) {
      logError(e.toString());
    }

    return await getSavedTransactions();
  }

  Future<bool> saveTransactions(List<Transaction> transactions) async {
    try {
      await db.saveDynamicData(data: transactions.toJson(), key: dbKeyName);
      return true;
    } catch (e) {
      logError(e.toString());
      return false;
    }
  }

  Future<List<Transaction>> getSavedTransactions() async {
    try {
      final savedData = await db.getDynamicData(key: dbKeyName);
      final type = token.getNetworkType;
      if (savedData != null) {
        switch (type) {
          case NetworkType.evm:
            return (savedData as List<dynamic>)
                .map((e) =>
                    EthereumTransaction.fromInternalJson(e, token: token))
                .toList();
          case NetworkType.svm:
            return (savedData as List<dynamic>)
                .map((e) => SolanaTransaction.fromJson(e))
                .toList();
          default:
        }
      }
    } catch (e) {
      logError(e.toString());
    }
    return [];
  }
}
