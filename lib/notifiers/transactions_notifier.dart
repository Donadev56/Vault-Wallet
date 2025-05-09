/*import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moonwallet/logger/logger.dart';
import 'package:moonwallet/service/external_data/transaction_manager.dart';
import 'package:moonwallet/types/transaction.dart';

class TransactionsNotifier
    extends FamilyAsyncNotifier<List<Transaction>, AccountWithToken> {
  @override
  @override
  Future<List<Transaction>> build(AccountWithToken data) async {
    try {
      final transactionHandler = TransactionManager(
        account: data.account,
        token: data.token,
      );
      final transactions = await transactionHandler.getTransactions();
      if (transactions.isEmpty) {
        log("Empty Transaction ");
      }
      return transactions;
    } catch (e) {
      logError(e.toString());
      return [];
    }
  }
}
*/
