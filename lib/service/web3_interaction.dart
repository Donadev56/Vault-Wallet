import 'package:moonwallet/logger/logger.dart';
import 'package:web3dart/web3dart.dart';
import 'package:http/http.dart';
import 'package:hex/hex.dart';

class Web3InteractionManager {
  var httpClient = Client();
  Future<double> getBalance(String address, String rpcUrl) async {
    try {
      if (address.isEmpty || rpcUrl.isEmpty) {
        log("address or rpc is empty");
        return 0;
      }
      var ethClient = Web3Client(rpcUrl, httpClient);
      final balance =
          await ethClient.getBalance(EthereumAddress.fromHex(address));
      return balance.getValueInUnit(EtherUnit.ether);
    } catch (e) {
      logError(e.toString());
      return 0;
    }
  }
}
