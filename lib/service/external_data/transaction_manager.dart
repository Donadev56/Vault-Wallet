import 'package:moonwallet/logger/logger.dart';
import 'package:moonwallet/service/db/transactions_db.dart';
import 'package:moonwallet/service/external_data/transactions_request.dart';
import 'package:moonwallet/types/account_related_types.dart';
import 'package:moonwallet/types/transaction.dart';
import 'package:moonwallet/utils/prefs.dart';

class TransactionManager {
  final Crypto token;
  final PublicAccount account;
  final PublicDataManager prefs = PublicDataManager();

  String get address => account.addressByToken(token);
  String get identifier =>
      (token.isNative ? token.cryptoId : token.contractAddress) ??
      token.cryptoId;

  String get lastFetchDataKey =>
      "/transactions/of/lastFetchTime/$address/&/$identifier";
  TransactionManager({required this.account, required this.token});

  Future<List<Transaction>> getTransactions() async {
    try {
      final type = token.getNetworkType;

      switch (type) {
        case NetworkType.evm:
          final transactions = await _getEvmTransactions();
          log("Transactions fetched ${transactions.length}");
          return transactions;

        default:
          return [];
      }
    } catch (e) {
      logError(e.toString());
      return [];
    }
  }

  Future<List<Transaction>> getSavedTransactions() async {
    try {
      return await TransactionStorage(token: token, account: account)
          .getSavedTransactions();
    } catch (e) {
      logError(e.toString());
      return [];
    }
  }

  Future<List<Transaction>> _getEvmTransactions() async {
    final storage = TransactionStorage(account: account, token: token);
    try {
      log("New request received from ${account.addressByToken(token)} for crypto ${token.symbol}");
      final lastTime = await prefs.getDataFromPrefs(key: lastFetchDataKey);
      final currentTime =
          (DateTime.now().millisecondsSinceEpoch / 1000).toInt();

      if (lastTime != null) {
        if ((currentTime - int.parse(lastTime)) < 60) {
          return await storage.getSavedTransactions();
        }
      }

      await prefs.saveDataInPrefs(
          data: currentTime.toString(), key: lastFetchDataKey);

      final TransactionsRequest transactionManager =
          TransactionsRequest(account: account, token: token);

      final recentData = await transactionManager.getRecentTransactions();
      log("Recent data ${recentData.length}");
      if (recentData.isEmpty) {
        return await storage.getSavedTransactions();
      }
      return await storage.patchTransactions(recentData);
    } catch (e) {
      logError(e.toString());
      rethrow;
    }
  }
}
