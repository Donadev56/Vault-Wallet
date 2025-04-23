import 'package:flutter/material.dart';
import 'package:moonwallet/custom/web3_webview/lib/utils/loading.dart';
import 'package:moonwallet/logger/logger.dart';
import 'package:moonwallet/service/external_data/price_manager.dart';
import 'package:moonwallet/service/web3_interactions/evm/token_manager.dart';
import 'package:moonwallet/service/db/wallet_saver.dart';
import 'package:moonwallet/types/types.dart';
import 'package:moonwallet/widgets/func/transactions/ask_user_for_conf.dart';
import 'package:moonwallet/widgets/func/security/ask_password.dart';
import 'package:moonwallet/widgets/func/snackbar.dart';
import 'package:web3dart/web3dart.dart';
import 'package:http/http.dart';

import 'utils.dart';

class EthInteractionManager {
  var httpClient = Client();
  final web3Manager = WalletSaver();
  final priceManager = PriceManager();
  final tokenManager = TokenManager();

  Future<double> getBalance(PublicData account, Crypto crypto) async {
    try {
      final address = account.address;
      final rpc = crypto.type == CryptoType.native
          ? crypto.rpcUrls?.firstOrNull
          : crypto.network?.rpcUrls?.firstOrNull;

      if (crypto.type == CryptoType.token) {
        return await tokenManager.getTokenBalance(crypto, address);
      }

      if (address.isEmpty || rpc == null || rpc.isEmpty) {
        log("address or rpc is empty");
        return 0;
      }
      var ethClient = Web3Client(rpc, httpClient);
      final balance =
          await ethClient.getBalance(EthereumAddress.fromHex(address));
      return balance.getValueInUnit(EtherUnit.ether);
    } catch (e) {
      logError(e.toString());
      return 0;
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
      final password =
          await askPassword(context: context, colors: colors, useBio: true);
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

  Future<String?> buildAndSendNativeTransaction(
      BasicTransactionData data, AppColors colors, BuildContext context) async {
    try {
      final nativeBalance = await getBalance(data.account, data.crypto)
          .withLoading(context, colors);

      if (nativeBalance <= data.amount) {
        throw Exception("Insufficient balance");
      }

      final to = data.addressTo;
      final from = data.account.address;
      final amount = data.amount;

      final valueWei = (BigInt.from(amount * 1e8) *
              BigInt.from(10).pow(data.crypto.decimals)) ~/
          BigInt.from(100000000);

      final valueHex = valueWei.toRadixString(16);
      log("Value : $valueHex and value wei $valueWei");

      final estimatedGas = await estimateGas(
          rpcUrl: data.crypto.rpcUrls?.firstOrNull ?? "",
          sender: from,
          to: to,
          value: valueHex,
          data: "");

      log("Gas : ${estimatedGas.toString()}");
      if (estimatedGas == null) {
        throw Exception("Gas estimation error");
      }
      final transaction = TransactionToConfirm(
          gasHex: "0x${(estimatedGas).toRadixString(16)}",
          gasBigint: estimatedGas,
          value: valueHex,
          account: data.account,
          addressTo: to,
          crypto: data.crypto,
          data: "");

      //  Navigator.pop(context);
      return await approveEthTransaction(
          crypto: data.crypto,
          colors: colors,
          data: transaction,
          context: context,
          operationType: 1);
    } catch (e) {
      logError(e.toString());
      rethrow;
    }
  }

  Future<BigInt?> simulateTransaction(Crypto crypto, PublicData account) async {
    return estimateGas(
        rpcUrl: crypto.type == CryptoType.token
            ? crypto.network?.rpcUrls?.firstOrNull ?? ""
            : crypto.rpcUrls?.firstOrNull ?? "",
        sender: account.address,
        to: account.address,
        value: "0x0",
        data: "");
  }

  Future<String?> buildAndSendStandardToken(
      BasicTransactionData data, AppColors colors, BuildContext context) async {
    try {
      final amount = data.amount;
      final to = data.addressTo;
      final network = data.crypto.network;
      final token = data.crypto;

      if (network == null) {
        throw "Network Cannot be null";
      }

      final requests = await Future.wait([
        getBalance(data.account, data.crypto),
        getBalance(data.account, network),
        simulateTransaction(data.crypto, data.account),
        getGasPrice(token.network?.rpcUrls?.first ?? ""),
      ]).withLoading(context, colors);

      final tokenBalance = requests[0] as double;
      final nativeTokenBalance = requests[1] as double;
      final estimatedGas = requests[2] as BigInt?;
      final gasPrice = requests[3] as BigInt;

      final BigInt gas = estimatedGas != null
          ? (estimatedGas * BigInt.from(2))
          : BigInt.from(21000);

      final double gasPriceDouble = gasPrice.toDouble();
      final transactionFee = ((gas * BigInt.from(gasPriceDouble.toInt())) /
          BigInt.from(10).pow(data.crypto.decimals));
      log("Fees ${transactionFee.toStringAsFixed(8)}");

      double roundedAmount = double.parse(amount.toStringAsFixed(8));

      if (roundedAmount > tokenBalance) {
        throw Exception("Insufficient balance");
      }
      if (nativeTokenBalance < transactionFee) {
        throw Exception(
            "Insufficient ${network.symbol} balance , add ${(transactionFee - nativeTokenBalance).toStringAsFixed(8)}");
      }

      final value = (BigInt.from((roundedAmount * 1e8).round()) *
          BigInt.from(10).pow(18) ~/
          BigInt.from(100000000));
      log("Value before parsing $value");
      final valueWei = value;
      log("valueWei $valueWei");

      final valueHex = (valueWei).toRadixString(16);
      if (estimatedGas == null) {
        throw Exception("Gas estimation error");
      }
      final transaction = TransactionToConfirm(
          gasHex: "0x${((estimatedGas * BigInt.from(2))).toRadixString(16)}",
          value: valueHex,
          account: data.account,
          addressTo: to,
          gasBigint: estimatedGas,
          crypto: data.crypto);

      return await tokenManager.approveTokenTransfer(
          colors: colors,
          data: transaction,
          context: context,
          operationType: 1);
    } catch (e) {
      logError(e.toString());
      rethrow;
    }
  }

  Future<String> approveEthTransaction(
      {required Crypto crypto,
      required TransactionToConfirm data,
      required AppColors colors,
      required BuildContext context,
      required int operationType}) async {
    try {
      final from = data.account.address;
      final to = data.addressTo;
      final value = data.value;
      final rpcUrls = data.crypto.rpcUrls;
      final estimatedGas = data.gasBigint;
      log("Data value ${value}");

      log("Estimated gas ${estimatedGas.toString()}");

      BigInt valueInWei = data.value.isNotEmpty
          ? BigInt.parse(data.value.replaceFirst("0x", ""), radix: 16)
          : BigInt.zero;

      log("value wei $valueInWei");

      if (estimatedGas == null) {
        throw Exception("An error occurred when trying to estimate the gas.");
      }

      BigInt? gasLimit = (estimatedGas * BigInt.from(30)) ~/ BigInt.from(100);

      final gasPriceResult = await getGasPrice(rpcUrls?.firstOrNull ?? "");
      BigInt gasPrice =
          gasPriceResult != BigInt.zero ? gasPriceResult : BigInt.from(100000);

      final cryptoPrice =
          await priceManager.getTokenMarketData(crypto.cgSymbol ?? "");

      final confirmedResponse = await askUserForConfirmation(
        crypto: crypto,
        operationType: operationType,
        cryptoPrice: cryptoPrice?.currentPrice ?? 0,
        estimatedGas: estimatedGas,
        gasPrice: gasPrice,
        gasLimit: gasLimit,
        valueInWei: valueInWei,
        txData: data,
        colors: colors,
        context: context,
        currentAccount: data.account,
      );

      final confirmed = confirmedResponse.ok;

      if (!confirmed) {
        throw Exception("Transaction rejected by user");
      }

      final transData = data.data ?? "";
      final transaction = Transaction(
        from: EthereumAddress.fromHex(from),
        to: EthereumAddress.fromHex(to),
        value: EtherAmount.inWei(valueInWei),
        maxGas: confirmedResponse.gasLimit.toInt(),
        gasPrice: EtherAmount.inWei(confirmedResponse.gasPrice),
        data: transData.isEmpty ? null : hexToUint8List(transData),
      );

      String userPassword =
          await askPassword(context: context, colors: colors, useBio: true);

      if (userPassword.isNotEmpty) {
        final result = await sendTransaction(
                colors: colors,
                context: context,
                transaction: transaction,
                chainId: crypto.chainId ?? 1,
                rpcUrl: crypto.rpcUrls?.firstOrNull ?? "",
                password: userPassword,
                address: from)
            .withLoading(context, colors);

        return result;
      } else {
        throw Exception("An error occurred while trying to enter the password");
      }
    } catch (e) {
      logError('Error sending Ethereum transaction: $e');
      throw Exception(e.toString());
    }
  }
}
