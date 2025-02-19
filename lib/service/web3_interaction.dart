import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_web3_webview/flutter_web3_webview.dart';
import 'package:moonwallet/logger/logger.dart';
import 'package:moonwallet/service/price_manager.dart';
import 'package:moonwallet/service/web3.dart';
import 'package:moonwallet/types/types.dart';
import 'package:moonwallet/widgets/askUserforconf.dart';
import 'package:moonwallet/widgets/bottom_pin_copy.dart';
import 'package:web3dart/web3dart.dart';
import 'package:http/http.dart';

class Web3InteractionManager {
  var httpClient = Client();
  final web3manager = Web3Manager();
  final priceManager = PriceManager();

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

  Future<String> sendEthTransaction(
      {required JsTransactionObject data,
      required bool mounted,
      required BuildContext context,
      required PublicData currentAccount,
      required Network currentNetwork,
      required Color primaryColor,
      required Color textColor,
      required Color secondaryColor,
      required Color actionsColor,
      required int operationType}) async {
    try {
      if (currentAccount.isWatchOnly) {
        showDialog(
            context: context,
            builder: (BuildContext wOCtx) {
              return AlertDialog(
                title: Text("Warning"),
                content: Text(
                  "This a watch-only account, you won't be able to send the transaction on the blockchain.",
                ),
                actions: [
                  ElevatedButton(
                    child: Text("Ok"),
                    onPressed: () {
                      Navigator.pop(wOCtx);
                    },
                  ),
                ],
              );
            });
        throw Exception(
            "This account is a watch-only account, you can't send transactions.");
      }

      if (data.from != null &&
          data.from?.trim().toLowerCase() !=
              currentAccount.address.trim().toLowerCase()) {
        throw Exception(
            "Different address detected : \n  it seems like ${data.from} is different from the connected address  ${currentAccount.address} , please check again your transaction data .");
      }

      BigInt estimatedGas = await estimateGas(
          value: data.value ?? "0x0",
          rpcUrl: currentNetwork.rpc,
          sender: data.from ?? "",
          to: data.to ?? "",
          data: data.data ?? "");

      log("Estimated gas ${estimatedGas.toString()}");

      BigInt valueInWei = data.value != null
          ? BigInt.parse(data.value!.replaceFirst("0x", ""), radix: 16)
          : BigInt.zero;

      log("value wei $valueInWei");

      BigInt? gasLimit = data.gas != null
          ? BigInt.parse(data.gas!.replaceFirst("0x", ""), radix: 16)
          : (estimatedGas * BigInt.from(30)) ~/ BigInt.from(100);
      final gasPriceResult = await getGasPrice(currentNetwork.rpc);
      BigInt gasPrice =
          gasPriceResult != BigInt.zero ? gasPriceResult : BigInt.from(100000);
      if (!mounted) {
        throw Exception("Internal error");
      }

      final cryptoPrice = await priceManager
          .getPriceUsingBinanceApi(currentNetwork.binanceSymbol);
      if (!mounted) {
        throw Exception("Internal error");
      }
      final confirmedResponse = await askUserForConfirmation(
          operationType: operationType,
          secondaryColor: secondaryColor,
          cryptoPrice: cryptoPrice,
          estimatedGas: estimatedGas,
          gasPrice: gasPrice,
          gasLimit: gasLimit,
          valueInWei: valueInWei,
          actionsColor: actionsColor,
          txData: data,
          context: context,
          primaryColor: primaryColor,
          currentAccount: currentAccount,
          textColor: textColor);

      final confirmed = confirmedResponse.ok;

      if (!confirmed) {
        throw Exception("Transaction rejected by user");
      }

      if (data.from != null && data.to != null) {
        final transData = data.data ?? "";
        final transaction = Transaction(
          from: EthereumAddress.fromHex(data.from ?? ""),
          to: EthereumAddress.fromHex(data.to ?? ""),
          value: EtherAmount.inWei(valueInWei),
          maxGas: confirmedResponse.gasLimit.toInt(),
          gasPrice: EtherAmount.inWei(confirmedResponse.gasPrice),
          data: transData.isEmpty ? null : hexToUint8List(transData),
        );

        String userPassword = "";

        if (!mounted) {
          throw Exception("Internal error");
        }

        final response = await showPinModalBottomSheet(
            // ignore: use_build_context_synchronously
            context: context,
            handleSubmit: (password) async {
              final savedPassword = await web3manager.getSavedPassword();
              if (password.trim() != savedPassword) {
                return PinSubmitResult(
                    success: false,
                    repeat: true,
                    error: "Invalid password",
                    newTitle: "Try again");
              } else {
                userPassword = password.trim();

                return PinSubmitResult(success: true, repeat: false);
              }
            },
            title: "Enter Password");

        if (response) {
          if (!mounted) {
            throw Exception("Internal error");
          }
          showDialog(
              context: context,
              builder: (BuildContext context) {
                return Center(
                  child: Container(
                    padding: const EdgeInsets.all(30),
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: secondaryColor, width: 0.5),
                      color: primaryColor,
                    ),
                    child: SizedBox(
                      width: 50,
                      height: 50,
                      child: CircularProgressIndicator(
                        color: textColor,
                      ),
                    ),
                  ),
                );
              });
          if (userPassword.isEmpty) {
            log("No password");
            throw Exception("No password provided");
          }
          final result = await sendTransaction(
              transaction: transaction,
              chainId: currentNetwork.chainId,
              rpcUrl: currentNetwork.rpc,
              password: userPassword,
              address: data.from ?? "");

          if (!mounted) {
            throw Exception("Internal error");
          }
          Navigator.pop(context);
          return result;
        } else {
          Navigator.pop(context);

          throw Exception(
              "An error occurred while trying to enter the password");
        }
      } else {
        Navigator.pop(context);

        throw Exception("Invalid transaction data");
      }
    } catch (e) {
      logError('Error sending Ethereum transaction: $e');
      throw Exception(e.toString());
    }
  }
}
