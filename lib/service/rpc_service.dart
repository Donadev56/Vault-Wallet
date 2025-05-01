import 'package:moonwallet/logger/logger.dart';
import 'package:moonwallet/service/web3_interactions/evm/eth_interaction_manager.dart';
import 'package:moonwallet/types/types.dart';

class RpcService {
  final EthInteractionManager _ethClient = EthInteractionManager();
  Future<String> getBalance(Crypto crypto, PublicData account) async {
    try {
      final balance = await _ethClient.getUserBalance(account, crypto);
      return balance;
    } catch (e) {
      logError(e.toString());
      return "0";
    }
  }

  Future<BigInt> getGasPrice(Crypto crypto) async {
    try {
      final gasPrice = await _ethClient.getGasPrice(crypto.getRpcUrl);
      return gasPrice;
    } catch (e) {
      logError(e.toString());
      return BigInt.from(0);
    }
  }
}
