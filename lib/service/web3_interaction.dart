import 'dart:convert';
import 'dart:typed_data';
import 'package:hex/hex.dart';

import 'package:flutter/material.dart';
import 'package:flutter_web3_webview/flutter_web3_webview.dart';
import 'package:moonwallet/custom/web3_webview/lib/utils/loading.dart';
import 'package:moonwallet/logger/logger.dart';
import 'package:moonwallet/service/price_manager.dart';
import 'package:moonwallet/service/token_manager.dart';
import 'package:moonwallet/service/wallet_saver.dart';
import 'package:moonwallet/types/types.dart';
import 'package:moonwallet/widgets/func/askUserforconf.dart';
import 'package:moonwallet/widgets/func/ask_password.dart';
import 'package:moonwallet/widgets/func/snackbar.dart';
import 'package:web3dart/web3dart.dart';
import 'package:http/http.dart';

class Web3InteractionManager {
  var httpClient = Client();
  final web3Manager = WalletSaver();
  final priceManager = PriceManager();
  final tokenManager = TokenManager();

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

  Future<double> getBalance(PublicData account, Crypto crypto) async {
    try {
      final address = account.address;
      final rpcUrl =
          crypto.type == CryptoType.network ? crypto.rpc : crypto.network?.rpc;
      if (crypto.type == CryptoType.token) {
        return await tokenManager.getTokenBalance(crypto, address);
      }

      if (address.isEmpty || rpcUrl == null || rpcUrl.isEmpty) {
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

  Future<String?> personalSign(String data,
      {required Crypto network,
      required PublicData account,
      required String password}) async {
    try {
      final credentials =
          await getCredentials(password: password, address: account.address);
      List<int> messageBytes = utf8.encode(data);
      if (credentials != null) {
        final signature = credentials
            .signPersonalMessageToUint8List(Uint8List.fromList(messageBytes));
        final signed = HEX.encode(signature);
        log("the signed message $signed");
        return signed;
      } else {
        return null;
      }
    } catch (e) {
      logError(e.toString());
      return null;
    }
  }

  Future<String?> sign(String data,
      {required Crypto network,
      required PublicData account,
      required String password}) async {
    try {
      final credentials =
          await getCredentials(password: password, address: account.address);
      List<int> messageBytes = utf8.encode(data);
      if (credentials != null) {
        final signature =
            credentials.signToUint8List(Uint8List.fromList(messageBytes));
        return HEX.encode(signature);
      } else {
        return null;
      }
    } catch (e) {
      logError(e.toString());
      return null;
    }
  }

  Future<String?> getPrivateKey({required String address}) async {
    try {
      String password = "";
      final pRes = await web3Manager.getSavedPassword();
      if (pRes != null) {
        password = pRes;
      }
      final savedPrivateKeys = await web3Manager.getDecryptedData(password);
      if (savedPrivateKeys != null) {
        log("Retrieved private key list");

        if (savedPrivateKeys.isNotEmpty) {
          log('the list is not empty');
          for (final privatekey in savedPrivateKeys) {
            final key = privatekey["privatekey"];
            final Credentials fromHex = EthPrivateKey.fromHex(key);

            final keyAddr = fromHex.address.hex;
            log("Address  $address");
            if (keyAddr.trim().toLowerCase() == address.trim().toLowerCase()) {
              log("Key found for address $address");
              log("Address $keyAddr == $address");
              return key;
            }
          }

          return null;
        } else {
          log("No key found for address $address");
          throw Exception("Internal error : No key found for address $address");
        }
      } else {
        log("Invalid password or no data found");
        throw Exception("Internal error : Invalid password or no data found");
      }
    } catch (e) {
      logError(e.toString());
      return null;
    }
  }

  Future<Credentials?> getCredentialsUsingPassword(
      {required BuildContext context,
      required String address,
      required AppColors colors}) async {
    try {
      log("Address $address");
      if (address.isEmpty) {
        logError("Address is empty");
        throw Exception("Address is empty");
      }
      final password = await askPassword(context: context, colors: colors);
      if (password.isNotEmpty) {
        try {
          final cred =
              await getCredentials(password: password, address: address);
          return cred;
        } catch (e) {
          logError("Error: $e");
          return null;
        }
      } else {
        log("Password is empty");
        throw Exception("Password is empty");
      }
    } catch (e) {
      logError(e.toString());
      return null;
    }
  }

  Future<Credentials?> getCredentials(
      {required String password, required String address}) async {
    try {
      final savedPrivateKeys = await web3Manager.getDecryptedData(password);
      if (savedPrivateKeys != null) {
        if (savedPrivateKeys.isNotEmpty) {
          for (final privatekey in savedPrivateKeys) {
            final key = privatekey["privatekey"];
            final Credentials fromHex = EthPrivateKey.fromHex(key);

            final keyAddr = fromHex.address.hex;
            if (keyAddr.trim().toLowerCase() == address.trim().toLowerCase()) {
              log("Key found for address $address");
              return fromHex;
            }
          }

          return null;
        } else {
          log("No key found for address $address");
          throw Exception("Internal error : No key found for address $address");
        }
      } else {
        log("Invalid password or no data found");
        throw Exception("Internal error : Invalid password or no data found");
      }
    } catch (e) {
      logError(e.toString());
      return null;
    }
  }

  Future<Credentials?> getCredentialsV2({required String address}) async {
    try {
      String password = "";
      final pRes = await web3Manager.getSavedPassword();
      if (pRes != null) {
        password = pRes;
      }
      final savedPrivateKeys = await web3Manager.getDecryptedData(password);
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
              return fromHex;
            }
          }

          return null;
        } else {
          log("No key found for address $address");
          throw Exception("Internal error : No key found for address $address");
        }
      } else {
        log("Invalid password or no data found");
        throw Exception("Internal error : Invalid password or no data found");
      }
    } catch (e) {
      logError(e.toString());
      return null;
    }
  }

  Future<String> sendTransaction(
      {required Transaction transaction,
      required int chainId,
      required String rpcUrl,
      required String password,
      required String address,
      required AppColors colors,
      required BuildContext context}) async {
    try {
      if (rpcUrl.isEmpty) {
        log("rpc url is empty");
        throw Exception("Internal error : rpcUrl is empty");
      }
      var ethClient = Web3Client(rpcUrl, httpClient);
      final credentials =
          await getCredentials(password: password, address: address);
      if (credentials != null) {
        final hash = await ethClient.sendTransaction(
          credentials,
          transaction,
          chainId: chainId,
        );
        if (hash.isNotEmpty) {
          showCustomSnackBar(
              type: MessageType.success,
              context: context,
              message: "Hash : $hash",
              colors: colors,
              icon: Icons.check_circle,
              iconColor: colors.greenColor);
        }

        return hash;
      } else {
        log("Credentials are null");
        throw Exception("Internal error : Credentials are null");
      }
    } catch (e) {
      logError(e.toString());
      // show error
      showCustomSnackBar(
          type: MessageType.error,
          context: context,
          message: e.toString(),
          colors: colors,
          icon: Icons.error,
          iconColor: Colors.red);
      throw ("Internal error : $e");
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

  Future<BigInt?> estimateGas(
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
      return null;
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
      {required Crypto crypto,
      required JsTransactionObject data,
      required AppColors colors,
      required bool mounted,
      required BuildContext context,
      required PublicData currentAccount,
      required Crypto currentNetwork,
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
      log("Data value ${data.value}");
      BigInt? estimatedGas = await estimateGas(
          value: data.value ?? "0x0",
          rpcUrl:
              currentNetwork.rpc ?? "https://opbnb-mainnet-rpc.bnbchain.org",
          sender: data.from ?? "",
          to: data.to ?? "",
          data: data.data ?? "");

      log("Estimated gas ${estimatedGas.toString()}");

      BigInt valueInWei = data.value != null
          ? BigInt.parse(data.value!.replaceFirst("0x", ""), radix: 16)
          : BigInt.zero;

      log("value wei $valueInWei");

      if (estimatedGas == null) {
        throw Exception("An error occurred when trying to estimate the gas.");
      }

      BigInt? gasLimit = data.gas != null
          ? BigInt.parse(data.gas!.replaceFirst("0x", ""), radix: 16)
          : (estimatedGas * BigInt.from(30)) ~/ BigInt.from(100);
      final gasPriceResult = await getGasPrice(
          currentNetwork.rpc ?? "https://opbnb-mainnet-rpc.bnbchain.org");
      BigInt gasPrice =
          gasPriceResult != BigInt.zero ? gasPriceResult : BigInt.from(100000);
      if (!mounted) {
        throw Exception("Internal error");
      }

      final cryptoPrice = await priceManager
          .getPriceUsingBinanceApi(currentNetwork.binanceSymbol ?? "");
      if (!mounted) {
        throw Exception("Internal error");
      }
      final confirmedResponse = await askUserForConfirmation(
          crypto: crypto,
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

        if (!mounted) {
          throw Exception("Internal error");
        }

        String userPassword =
            await askPassword(context: context, colors: colors);

        if (userPassword.isNotEmpty) {
          if (!mounted) {
            throw Exception("No password provided");
          }

          final result = await sendTransaction(
                  colors: colors,
                  context: context,
                  transaction: transaction,
                  chainId: currentNetwork.chainId ?? 204,
                  rpcUrl: currentNetwork.rpc ??
                      "https://opbnb-mainnet-rpc.bnbchain.org",
                  password: userPassword,
                  address: data.from ?? "")
              .withLoading(context, colors);

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
