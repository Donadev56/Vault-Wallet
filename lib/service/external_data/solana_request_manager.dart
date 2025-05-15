import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:moonwallet/logger/logger.dart';
import 'package:moonwallet/types/account_related_types.dart';
import 'package:moonwallet/types/transaction.dart';

class SolanaRequestManager {
  final baseUrl = "https://api.moonbnb.app/transactions";
  String get byAddressUrl => "$baseUrl/all-svm?address=";

  Future<List<Transaction>> fetchTransactions(
      PublicAccount account, Crypto token) async {
    log("Getting transactions");
    try {
      final url = "$byAddressUrl${account.addressByToken(token)}";
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final transactionList = jsonDecode(response.body) as List;
        List<Transaction> transactions = [];

        for (final trx in transactionList) {
          final fees = trx["networkFees"];
          final timeStamp = trx["timeStamp"];
          final id = trx["transactionId"];
          final instructions = trx["instructions"] as List?;
          final status = trx["status"];
          final slot = trx["slot"];
          if (instructions != null) {
            for (final instruction in instructions) {
              final StringType = instruction["type"];
              final type = SolInstruction.values
                  .where((e) =>
                      e.toShortString() ==
                      (StringType as String).split('.').lastOrNull)
                  .firstOrNull;
              if (type == null) {
                continue;
              }
              if ((!token.isNative && type == SolInstruction.token) ||
                  (token.isNative && type == SolInstruction.lamports)) {
                final to = instruction["to"];
                final from = instruction["from"];
                final amount = instruction["amount"];

                SolanaTransaction solanaTransaction = SolanaTransaction(
                    from: from ?? "",
                    networkFees: fees,
                    timeStamp: timeStamp,
                    to: to,
                    uiAmount: amount as String,
                    txId: id,
                    transactionId: id,
                    token: token,
                    status: status,
                    slot: slot);
                transactions.add(solanaTransaction);
              }
            }
          }
        }

        return transactions;
      }

      throw Exception(response.body);
    } catch (e) {
      logError(e.toString());
      rethrow;
    }
  }

  Future<dynamic> getTransactionGlobalDetails(
      String signature, Crypto token) async {
    try {
      final body = jsonEncode({
        "jsonrpc": "2.0",
        "id": 1,
        "method": "getTransaction",
        "params": [
          signature,
          {"encoding": "jsonParsed"},
        ],
      });

      final response = await http.post(
        Uri.parse(token.getRpcUrl),
        headers: {'Content-Type': 'application/json'},
        body: body,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data["result"];
      }

      throw ("An error has occurred ${response.body}");
    } catch (e) {
      logError(e.toString());
      return null;
    }
  }
}
