import 'dart:typed_data';

import 'package:moonwallet/logger/logger.dart';
import 'package:moonwallet/service/web3.dart';
import 'package:web3dart/web3dart.dart';
import 'package:http/http.dart';

class Web3InteractionManager {
  var httpClient = Client();
  final web3manager = Web3Manager();

  Uint8List hexToUint8List(String hex) {
    if (hex.startsWith("0x") || hex.startsWith("0X")) {
      hex = hex.substring(2);
    }
    if (hex.length % 2 != 0) {
      throw 'Odd number of hex digits';
    }
    var l = hex.length ~/ 2;
    var result = Uint8List(l);
    for (var i = 0; i < l; ++i) {
      var x = int.parse(hex.substring(2 * i, 2 * (i + 1)), radix: 16);
      if (x.isNaN) {
        throw 'Expected hex string';
      }
      result[i] = x;
    }
    return result;
  }

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

  Future<String> sendTransaction(
      {required Transaction transaction,
      required int chainId,
      required String rpcUrl,
      required String password,
      required String address}) async {
    try {
      if (rpcUrl.isEmpty) {
        log("rpc url is empty");
        throw Exception("Internal error : rpcUrl is empty");
      }
      var ethClient = Web3Client(rpcUrl, httpClient);
      final savedPrivateKeys = await web3manager.getDecryptedData(password);
      if (savedPrivateKeys != null) {
        log("Retrieved private key list");

        if (savedPrivateKeys.isNotEmpty) {
          log('the list is not empty');
          for (final privatekey in savedPrivateKeys) {
            final key = privatekey["privatekey"];
            final Credentials fromHex = EthPrivateKey.fromHex(key);

            final keyAddr = fromHex.address.hex;
            log("Address found $address");
            if (keyAddr.trim().toLowerCase() == address.trim().toLowerCase()) {
              log("Key found for address $address");

              return await ethClient.sendTransaction(
                fromHex,
                transaction,
                chainId: chainId,
              );
            }
          }
        } else {
          log("No key found for address $address");
          throw Exception("Internal error : No key found for address $address");
        }
      } else {
        log("Invalid password or no data found");
        throw Exception("Internal error : Invalid password or no data found");
      }

      throw Exception("Internal error");
    } catch (e) {
      logError(e.toString());
      return ("Internal error : $e");
    }
  }

  Future<BigInt> getGasPrice(String rpcUrl) async {
    try {
      if (rpcUrl.isEmpty) {
        log("rpc url is empty");
        return BigInt.zero;
      }
      var ethClient = Web3Client(rpcUrl, httpClient);
      final gasPrice = await ethClient.getGasPrice();
      log("gas price is ${gasPrice.getInWei.toString()}");
      return gasPrice.getInWei;
    } catch (e) {
      logError(e.toString());
      return BigInt.zero;
    }
  }

  Future<BigInt> estimateGas(
      {required String rpcUrl,
      required String sender,
      required String to,
      required String value,
      required String data}) async {
    try {
      // log every data received
      log("rpc url: $rpcUrl, sender: $sender, to: $to, value: $value, data: $data");

      var client = Web3Client(rpcUrl, httpClient);

      final BigInt estimatedGas = await client.estimateGas(
        sender: EthereumAddress.fromHex(sender),
        to: EthereumAddress.fromHex(to),
        value: EtherAmount.inWei(parseHex(value)),
        data: hexToUint8List(data),
      );

      return estimatedGas;
    } catch (e) {
      logError(e.toString());
      return BigInt.zero;
    }
  }

  BigInt parseHex(String hex) {
    log("Parsing hex $hex");
    if (hex.startsWith("0x")) {
      hex = hex.substring(2);
      log(hex);
      final hexParsed = BigInt.parse(hex, radix: 16);
      log("The hex parsed is $hexParsed");
      return hexParsed;
    }
    return BigInt.parse(hex, radix: 16);
  }
}
