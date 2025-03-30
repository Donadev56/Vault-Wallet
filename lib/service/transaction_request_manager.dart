import 'package:dio/dio.dart';
import 'package:moonwallet/types/types.dart';

class TransactionRequestManager {
  final baseUrl = "https://api.moonbnb.app";
  final dio = Dio();

  Future<List<EsTransaction>> getAllTransactions(
      {required Crypto crypto, required String address}) async {
    try {
      final cryptoId = crypto.type == CryptoType.network
          ? crypto.cryptoId
          : crypto.network?.cryptoId;
      final contractAddress = crypto.contractAddress;
      Map<String, dynamic> body = {};
      if (crypto.type == CryptoType.network) {
        body = {
          "cryptoId": cryptoId,
          "address": address,
        };
      } else {
        body = {
          "cryptoId": cryptoId,
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
