import 'package:http/http.dart';
import 'package:moonwallet/logger/logger.dart';
import 'package:moonwallet/types/account_related_types.dart';
import 'package:moonwallet/types/types.dart';
import 'package:web3dart/web3dart.dart';

class DynamicWeb3Client {
  var httpClient = Client();
  final String rpcUrl;

  DynamicWeb3Client({required this.rpcUrl});

  Web3Client get client => Web3Client(rpcUrl, httpClient);

  Future<int?> getChainId() async {
    try {
      return (await client.getChainId()).toInt();
    } catch (e) {
      logError(e.toString());
      return null;
    }
  }

  Future<TransactionReceipt?> getReceipt(String tx) async {
    try {
      final result = await client.getTransactionReceipt(tx);
      return result;
    } catch (e) {
      logError(e.toString());
      return null;
    }
  }

  Future<String?> getStatus(String tx, Crypto crypto) async {
    try {
      final web3Client = DynamicWeb3Client(
          rpcUrl: (!crypto.isNative
                  ? crypto.network?.rpcUrls?.firstOrNull
                  : crypto.rpcUrls?.firstOrNull) ??
              "");
      final receipt = await web3Client.getReceipt(tx);
      return receipt?.status == true ? "Success" : "Failed";
    } catch (e) {
      logError(e.toString());
      return null;
    }
  }
}
