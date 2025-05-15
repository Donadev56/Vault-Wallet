import 'package:moonwallet/logger/logger.dart';
import 'package:moonwallet/service/db/transactions_db.dart';
import 'package:moonwallet/service/external_data/solana_request_manager.dart';
import 'package:moonwallet/service/external_data/transactions_request.dart';
import 'package:moonwallet/service/web3_interactions/evm/web3_client.dart';
import 'package:moonwallet/types/account_related_types.dart';
import 'package:moonwallet/types/transaction.dart';
import 'package:moonwallet/utils/prefs.dart';
import '../rpc_service.dart';

class TransactionManager {
  final Crypto token;
  final PublicAccount account;
  final PublicDataManager prefs = PublicDataManager();
  final rpcService = RpcService();

  String get address => account.addressByToken(token);
  String get identifier =>
      (token.isNative ? token.cryptoId : token.contractAddress) ??
      token.cryptoId;

  String get lastFetchDataKey =>
      "/transactions/of/lastFetchTime/$address/&/$identifier";
  TransactionManager({required this.account, required this.token});

  Future<List<Transaction>> getSavedTransactions() async {
    try {
      return await TransactionStorage(token: token, account: account)
          .getSavedTransactions();
    } catch (e) {
      logError(e.toString());
      return [];
    }
  }

  Future<List<Transaction>> getTransactions() async {
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

  Future<Transaction?> addTransactionAfterTransfer(
      String id, String amount, String to) async {
    try {
      final storage = TransactionStorage(account: account, token: token);

      final type = token.getNetworkType;
      switch (type) {
        case NetworkType.evm:
          final transaction = await _getEthTransaction(id, amount, to);
          await storage.patchTransactions([transaction]);
          return transaction;
        case NetworkType.svm:
          final transaction = await _getSolTransaction(id, amount, to);
          log("Transaction retrieved : ${transaction}");
          await storage.patchTransactions([transaction]);
          return transaction;

          break;
        default:
      }
    } catch (e) {
      logError(e.toString());
      return null;
    }
  }

  Future<Transaction> _getSolTransaction(
      String id, String amount, String to) async {
    try {
      final json =
          await SolanaRequestManager().getTransactionGlobalDetails(id, token);
      log("JSON $json");
      if (json != null) {
        final now = DateTime.now().millisecondsSinceEpoch / 1000;
        final meta = json["meta"];
        final blockTime = json["blockTime"];
        final fee = (meta["fee"] ?? 0) / 1e9;
        final slot = json["slot"] ?? 0;
        final jsonStatus = meta["status"];
        final status = jsonStatus != null && jsonStatus["Err"] != null
            ? "Fail"
            : "Success";
        return SolanaTransaction(
            from: account.addressByToken(token),
            networkFees: fee is String ? fee : fee.toString(),
            timeStamp: blockTime ?? now.toInt(),
            to: to,
            uiAmount: amount,
            txId: id,
            transactionId: id,
            status: status,
            slot: slot);
      }
      throw Exception("An error has occurred");
    } catch (e) {
      logError(e.toString());
      rethrow;
    }
  }

  Future<Transaction> _getEthTransaction(
      String id, String amount, String to) async {
    try {
      final receipt =
          await DynamicWeb3Client(rpcUrl: token.getRpcUrl).getReceipt(id);
      final now = DateTime.now().millisecondsSinceEpoch / 1000;
      final transaction = EthereumTransaction(
          transactionId: id,
          token: token,
          from: account.addressByToken(token),
          networkFees: "",
          timeStamp: now.toInt(),
          to: to,
          uiAmount: amount,
          hash: id,
          blockNumber: (receipt?.blockNumber).toString(),
          status: receipt?.status == null
              ? null
              : (receipt?.status == true ? "success" : "fail"));
      return transaction;
    } catch (e) {
      logError(e.toString());
      rethrow;
    }
  }
}
