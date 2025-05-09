import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moonwallet/logger/logger.dart';
import 'package:moonwallet/service/db/transactions_db.dart';
import 'package:moonwallet/types/transaction.dart';

class SavedTransactions
    extends FamilyAsyncNotifier<List<Transaction>, AccountWithToken> {
  @override
  Future<List<Transaction>> build(AccountWithToken data) async {
    try {
      final storage =
          TransactionStorage(account: data.account, token: data.token);
      return await storage.getSavedTransactions();
    } catch (e) {
      logError(e.toString());
      return [];
    }
  }
}
