import 'package:flutter/material.dart';
import 'package:moonwallet/custom/web3_webview/lib/utils/loading.dart';
import 'package:moonwallet/logger/logger.dart';
import 'package:moonwallet/service/db/balance_database.dart';
import 'package:moonwallet/service/external_data/price_manager.dart';
import 'package:moonwallet/service/internet_manager.dart';
import 'package:moonwallet/service/web3_interactions/evm/token_manager.dart';
import 'package:moonwallet/service/db/wallet_db.dart';
import 'package:moonwallet/types/types.dart';
import 'package:moonwallet/widgets/func/transactions/ask_user_for_conf.dart';
import 'package:moonwallet/widgets/func/security/ask_password.dart';
import 'package:moonwallet/widgets/func/snackbar.dart';
import 'package:web3dart/web3dart.dart';
import 'package:http/http.dart';

import 'utils.dart';

class EthInteractionManager {
  var httpClient = Client();
  final walletStorage = WalletDatabase();
  final priceManager = PriceManager();
  final tokenManager = TokenManager();
  Future<String?> fetchBalanceUsingRpc(
      PublicData account, Crypto crypto) async {
    try {
      final address = account.evmAddress;
      final rpc = crypto.isNative
          ? crypto.rpcUrls?.firstOrNull
          : crypto.network?.rpcUrls?.firstOrNull;

      if (!crypto.isNative) {
        final balance = await tokenManager.getTokenBalance(crypto, address);
        return balance;
      }

      if (address.isEmpty || rpc == null || rpc.isEmpty) {
        log("address or rpc is empty");
        return "0";
      }
      var ethClient = Web3Client(rpc, httpClient);
      final balance =
          await ethClient.getBalance(EthereumAddress.fromHex(address));
      final balanceEther = balance.getValueInUnit(EtherUnit.ether);
      return balanceEther.toString();
    } catch (e) {
      logError(e.toString());
      return null;
    }
  }

  Future<String> getUserBalance(PublicData account, Crypto crypto) async {
    try {
      final db = BalanceDatabase(account: account, crypto: crypto);
      final savedBalanceFunc = db.getBalance();

      final internet = InternetManager();

      if (!await internet.isConnected()) {
        final savedBalance = await savedBalanceFunc;
        log("Saved balance : $savedBalance");
        return savedBalance;
      }

      String balance = "0";

      try {
        final currentBalance = await fetchBalanceUsingRpc(account, crypto);
        if (currentBalance == null) {
          throw "Balance is Null";
        }
        balance = currentBalance;
        await db.saveData(balance);
      } catch (e) {
        logError(e.toString());
        balance = await savedBalanceFunc;
      }

      return balance;
    } catch (e) {
      logError(e.toString());
      return "0";
    }
  }

  Future<AccountAccess?> getAccess(
      {required String password, required String address}) async {
    try {
      final savedPrivateKeys = await walletStorage.getDecryptedData(password);
      if (savedPrivateKeys != null) {
        if (savedPrivateKeys.isNotEmpty) {
          for (final privatekey in savedPrivateKeys) {
            final key = privatekey["privatekey"];
            final Credentials fromHex = EthPrivateKey.fromHex(key);

            final keyAddr = fromHex.address.hex;
            if (keyAddr.trim().toLowerCase() == address.trim().toLowerCase()) {
              log("Key found for address $address");
              return AccountAccess(address: address, cred: fromHex, key: key);
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
      final access = await getAccess(password: password, address: address);
      final credentials = access?.cred;

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
              message: "Transfer Sent",
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
        value: EtherAmount.inWei(EthUtils().parseHex(value)),
        data: EthUtils().hexToUint8List(data),
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
      final nativeBalance = await getUserBalance(data.account, data.crypto)
          .withLoading(context, colors);
      final nativeBalanceDecimal = (nativeBalance).toDecimal();
      final amountDecimal = (data.amount).toDecimal();

      if (nativeBalanceDecimal <= amountDecimal) {
        throw Exception("Insufficient balance");
      }

      final to = data.addressTo;
      final amount = data.amount;
      log("Amount $amount");

      final valueWei = EthUtils().ethToBigInt(amount, data.crypto.decimals);
      final valueHex = EthUtils().bigIntToHex(valueWei);
      final cryptoPrice =
          (await priceManager.getTokenMarketData(data.crypto.cgSymbol ?? ""))
              ?.currentPrice;

      final estimatedGas = ((await estimateGas(
                  rpcUrl: data.crypto.rpcUrls?.firstOrNull ?? "",
                  sender: data.account.evmAddress,
                  to: to,
                  value: valueHex,
                  data: "") ??
              BigInt.from(21000)) +
          BigInt.from(10000));

      final gasPrice =
          await getGasPrice(data.crypto.rpcUrls?.firstOrNull ?? "");

      log("Gas : ${estimatedGas.toString()}");

      final transaction = TransactionToConfirm(
          gasPrice: gasPrice,
          valueBigInt: valueWei,
          cryptoPrice: cryptoPrice ?? 0,
          gasHex: EthUtils().bigIntToHex(estimatedGas),
          gasBigint: estimatedGas,
          valueHex: valueHex,
          valueEth: amount,
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
        rpcUrl: !crypto.isNative
            ? crypto.network?.rpcUrls?.firstOrNull ?? ""
            : crypto.rpcUrls?.firstOrNull ?? "",
        sender: account.evmAddress,
        to: account.evmAddress,
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
        getUserBalance(data.account, data.crypto),
        getGasPrice(token.network?.rpcUrls?.first ?? ""),
      ]).withLoading(context, colors);

      final tokenBalance = requests[0] as String;
      final gasPrice = requests[1] as BigInt;
      final tokenBalanceDecimal = tokenBalance.toDecimal();
      final amountDecimal = amount.toDecimal();

      if (amountDecimal > tokenBalanceDecimal) {
        throw Exception("Insufficient balance");
      }

      final cryptoPrice = (await priceManager
              .getTokenMarketData(data.crypto.network?.cgSymbol ?? ""))
          ?.currentPrice;

      final valueWei = EthUtils().ethToBigInt(amount, data.crypto.decimals);

      log("valueWei $valueWei");

      final valueHex = EthUtils().bigIntToHex(valueWei);

      final transaction = TransactionToConfirm(
          gasPrice: gasPrice,
          cryptoPrice: cryptoPrice ?? 0,
          gasHex: EthUtils().bigIntToHex(BigInt.from(0)),
          valueHex: valueHex,
          valueEth: amount,
          valueBigInt: valueWei,
          account: data.account,
          addressTo: to,
          gasBigint: BigInt.from(0),
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
      if (!context.mounted) {
        throw "No Context";
      }

      final confirmedResponse = await askUserForConfirmation(
        crypto: crypto,
        txData: data,
        colors: colors,
        context: context,
      );
      if (confirmedResponse == null || !confirmedResponse.ok) {
        throw Exception("Transaction rejected by user");
      }

      final transaction = Transaction(
        from: EthereumAddress.fromHex(data.account.evmAddress),
        to: EthereumAddress.fromHex(data.addressTo),
        value: EtherAmount.inWei(data.valueBigInt),
        maxGas: confirmedResponse.gasLimit?.toInt() ?? data.gasBigint?.toInt(),
        gasPrice:
            EtherAmount.inWei(confirmedResponse.gasPrice ?? data.gasPrice),
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
                address: data.account.evmAddress)
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
