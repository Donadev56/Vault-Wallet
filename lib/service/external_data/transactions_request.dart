import 'package:dio/dio.dart';
import 'package:moonwallet/logger/logger.dart';
import 'package:moonwallet/service/db/transactions_db.dart';
import 'package:moonwallet/service/external_data/solana_request_manager.dart';
import 'package:moonwallet/service/internet_manager.dart';
import 'package:moonwallet/types/account_related_types.dart';
import 'package:moonwallet/types/transaction.dart';

class TransactionsRequest {
  final Crypto token;
  final PublicAccount account;
  final baseUrl = "https://api.moonbnb.app";
  final dio = Dio();
  final internet = InternetManager();

  TransactionsRequest({required this.account, required this.token});

  Future<List<Transaction>> getRecentTransactions() async {
    final storage = TransactionStorage(token: token, account: account);
    try {
      final type = token.getNetworkType;
      switch (type) {
        case NetworkType.evm:
          if (!(await internet.isConnected())) {
            return await storage.getSavedTransactions();
          }
          final result = await getEvmTransactions();
          log("Result ${result.length}");
          return result;
        case NetworkType.svm:
          final result = await getSvmTransactions();
          log("Result ${result.length}");
          return result;

        default:
          return [];
      }
    } catch (e) {
      logError(e.toString());
      rethrow;
    }
  }

  Future<List<Transaction>> getEvmTransactions() async {
    try {
      final contractAddress = token.contractAddress;
      final address = account.addressByToken(token);
      final chainId = token.tokenNetwork?.chainId;

      if (chainId == null) {
        throw ArgumentError("Invalid chain Id");
      }

      Map<String, dynamic> body = {
        "chainId": chainId,
        "address": address,
      };
      if (!token.isNative) {
        body["contractAddress"] = contractAddress;
      }
      final url = "$baseUrl/transactions/all";

      final response = await dio.get(url, queryParameters: body);
      final jsonResponse = response.data;
      log("Response $jsonResponse");

      if ((jsonResponse as List<dynamic>).isNotEmpty) {
        final transactions = jsonResponse
            .map((e) => EthereumTransaction.fromJson(e, token: token))
            .toList();
        log("Transactions len ${transactions.length}");
        return transactions;
      }
      return [];
    } catch (e) {
      logError(e.toString());
      rethrow;
    }
  }

  Future<List<Transaction>> getSvmTransactions() async {
    try {
      return await SolanaRequestManager().fetchTransactions(account, token);
    } catch (e) {
      logError(e.toString());
      rethrow;
    }
  }
}
