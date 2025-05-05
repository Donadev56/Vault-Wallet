import 'package:dio/dio.dart';
import 'package:moonwallet/types/account_related_types.dart';
import 'package:moonwallet/types/types.dart';

class TransactionRequestManager {
  final baseUrl = "https://api.moonbnb.app";
  final dio = Dio();

  Future<List<EsTransaction>> getAllTransactions(
      {required Crypto crypto, required String address}) async {
    try {
      final contractAddress = crypto.contractAddress;
      Map<String, dynamic> body = {};
      if (crypto.isNative) {
        final chainId = crypto.chainId;
        if (chainId == null) {
          throw "No chain Id provided";
        }
        body = {
          "chainId": chainId,
          "address": address,
        };
      } else {
        final chainId = crypto.network?.chainId;
        if (chainId == null) {
          throw "No chain Id provided";
        }
        body = {
          "chainId": chainId,
          "address": address,
          "contractAddress": contractAddress,
        };
      }

      final url = "$baseUrl/transactions/all";

      final response = await dio.get(url, queryParameters: body);
      final jsonResponse = response.data;

      return toDart(jsonResponse);
    } catch (e) {
      throw Exception("Failed to fetch transactions: $e");
    }
  }
}

List<EsTransaction> toDart(List<dynamic> data) {
  final List<EsTransaction> transactions = [];
  for (final json in data) {
    transactions.add(EsTransaction.fromJson(json));
  }
  return transactions;
}
