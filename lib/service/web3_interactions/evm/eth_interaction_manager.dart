import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:moonwallet/custom/web3_webview/lib/utils/loading.dart';
import 'package:moonwallet/logger/logger.dart';
import 'package:moonwallet/service/address_manager.dart';
import 'package:moonwallet/service/db/balance_database.dart';
import 'package:moonwallet/service/db/wallet_db_stateless.dart';
import 'package:moonwallet/service/external_data/price_manager.dart';
import 'package:moonwallet/service/internet_manager.dart';
import 'package:moonwallet/service/web3_interactions/evm/addresses.dart';
import 'package:moonwallet/service/web3_interactions/evm/token_manager.dart';
import 'package:moonwallet/service/db/wallet_db.dart';
import 'package:moonwallet/types/account_related_types.dart';
import 'package:moonwallet/types/types.dart';
import 'package:moonwallet/widgets/func/security/ask_derivate_key.dart';
import 'package:moonwallet/widgets/func/transactions/evm/ask_user_evm.dart';
import 'package:moonwallet/widgets/func/security/ask_password.dart';
import 'package:moonwallet/widgets/func/snackbar.dart';
import 'package:web3dart/web3dart.dart';
import 'package:http/http.dart';

import 'utils.dart';

class EthInteractionManager {
  var httpClient = Client();
  final walletStorage = WalletDbStateLess();

  final priceManager = PriceManager();
  final tokenManager = TokenManager();
  final addressManager = AddressManager();
  final EthAddresses ethAddresses = EthAddresses();
  Future<String?> fetchBalanceUsingRpc(
      PublicAccount account, Crypto crypto) async {
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

  Future<String> getUserBalance(PublicAccount account, Crypto crypto) async {
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

  Future<AccountAccess?> getAccessUsingKey(
      {required String deriveKey, required PublicAccount account}) async {
    try {
      final privateAccount = await walletStorage.getPrivateAccountUsingKey(
          deriveKey: deriveKey, account: account);
      if (privateAccount == null) {
        throw InvalidPasswordException();
      }
      String privateKey = "";
      if (privateAccount.origin.isMnemonic) {
        final privateKeyResult = addressManager.ethAddress
            .derivateEthereumKeyFromMnemonic(privateAccount.keyOrigin);
        if (privateKeyResult == null) {
          throw InvalidPasswordException();
        }
        privateKey = privateKeyResult;
      }

      if (privateAccount.origin.isPrivateKey) {
        privateKey = privateAccount.keyOrigin;
      }

      final Credentials fromHex = EthPrivateKey.fromHex(privateKey);

      final keyAddr = fromHex.address.hex;

      return AccountAccess(address: keyAddr, cred: fromHex, key: privateKey);
    } catch (e) {
      logError(e.toString());
      return null;
    }
  }

  Future<String> sendTransaction(
      {required Transaction transaction,
      required int chainId,
      required String rpcUrl,
      required PublicAccount account,
      required AppColors colors,
      required BuildContext context}) async {
    try {
      if (rpcUrl.isEmpty) {
        log("rpc url is empty");
        throw Exception("Internal error : rpcUrl is empty");
      }
      var ethClient = Web3Client(rpcUrl, httpClient);
      final deriveKey = await askDerivateKey(context: context, colors: colors);
      if (deriveKey == null) {
        throw InvalidPasswordException();
      }
      final access =
          await getAccessUsingKey(deriveKey: deriveKey, account: account);
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

      if (nativeBalanceDecimal < amountDecimal) {
        throw Exception("Insufficient balance");
      }

      final to = data.addressTo;

      final valueWei = EthUtils()
          .ethToBigInt(amountDecimal.toString(), data.crypto.decimals);
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
      final baseFees = Decimal.fromBigInt((estimatedGas * gasPrice));
      final feesCostWei = baseFees * Decimal.parse('1.5');
      final feesCostEth = feesCostWei /
          Decimal.fromInt(10).pow(data.crypto.decimals).toDecimal();
      final totalCost = feesCostEth.toDecimal() + amountDecimal;
      log("Fees cost : ${feesCostEth.toDecimal()}");

      log("Total cost : ${totalCost.toString()}");
      String amountToTransferHex = "0x0";
      BigInt valueBigIntToTransfer = valueWei;
      Decimal amountEthToTransfer = amountDecimal;

      final canAffordTotalCost = totalCost <= nativeBalanceDecimal;
      log("Can afford total cost : $canAffordTotalCost");
      final canSubtractFeesFromBalance =
          (nativeBalanceDecimal - feesCostEth.toDecimal()) > Decimal.zero;

      log("Can subtract fees from balance : $canSubtractFeesFromBalance");
      if (canAffordTotalCost) {
        amountToTransferHex = EthUtils().bigIntToHex(valueWei);
      } else if (!canAffordTotalCost && canSubtractFeesFromBalance) {
        valueBigIntToTransfer =
            (Decimal.fromBigInt(valueWei) - feesCostWei).toBigInt();

        amountToTransferHex = EthUtils().bigIntToHex((valueBigIntToTransfer));
        amountEthToTransfer = amountDecimal - feesCostEth.toDecimal();
      } else {
        throw Exception("Amount too low after gas fees");
      }

      log("Possible transfer : ${amountToTransferHex.toString()}");

      final transaction = TransactionToConfirm(
          gasPrice: gasPrice,
          valueBigInt: valueBigIntToTransfer,
          cryptoPrice: cryptoPrice ?? 0,
          gasHex: EthUtils().bigIntToHex(estimatedGas),
          gasBigint: estimatedGas,
          valueHex: amountToTransferHex,
          valueEth: amountEthToTransfer.toString(),
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

  Future<BigInt?> simulateTransaction(
      Crypto crypto, PublicAccount account) async {
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

  Future<String?> transferHandler(BasicTransactionData transaction,
      AppColors colors, BuildContext context) async {
    try {
      if (transaction.crypto.isNative) {
        return await buildAndSendNativeTransaction(
            transaction, colors, context);
      } else {
        return await buildAndSendStandardToken(transaction, colors, context);
      }
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

      final confirmedResponse = await askUserEvm(
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

      final result = await sendTransaction(
              colors: colors,
              context: context,
              transaction: transaction,
              chainId: crypto.chainId ?? 1,
              rpcUrl: crypto.rpcUrls?.firstOrNull ?? "",
              account: data.account)
          .withLoading(context, colors);

      return result;
    } catch (e) {
      logError('Error sending Ethereum transaction: $e');
      throw Exception(e.toString());
    }
  }
}
