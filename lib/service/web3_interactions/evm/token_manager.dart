import 'package:flutter/material.dart';
import 'package:moonwallet/custom/web3_webview/lib/utils/loading.dart';
import 'package:moonwallet/logger/logger.dart';
import 'package:moonwallet/service/external_data/price_manager.dart';
import 'package:moonwallet/service/web3_interactions/evm/eth_interaction_manager.dart';
import 'package:moonwallet/types/types.dart';
import 'package:moonwallet/widgets/func/ask_user_for_conf.dart';
import 'package:moonwallet/widgets/func/ask_password.dart';
import 'package:moonwallet/widgets/func/show_watch_only_warning.dart';
import 'package:web3dart/web3dart.dart';
import 'package:http/http.dart';

class TokenManager {
  final httpClient = Client();
  final priceManager = PriceManager();

  Future<double> getTokenBalance(Crypto token, String address) async {
    try {
      if (token.network?.rpcUrls == null || token.rpcUrls?.isEmpty == true) {
        throw Exception('RPC URL  is not provided');
      }

      if (token.contractAddress == null ||
          (token.contractAddress as String).isEmpty) {
        logError('Contract address is not provided');
        return 0;
      }
      final client = Web3Client(
          token.network?.rpcUrls?.first ?? token.rpcUrls?.first ?? "",
          httpClient);
      final EthereumAddress contractAddr =
          EthereumAddress.fromHex(token.contractAddress as String);
      final contract = DeployedContract(
          ContractAbi.fromJson(standardTokenAbi, ""), contractAddr);
      final balanceFunction = contract.function("balanceOf");
      final result = await client.call(
          contract: contract,
          function: balanceFunction,
          params: [EthereumAddress.fromHex(address)]);
      return ((result.first as BigInt) / BigInt.from(10).pow(token.decimals));
    } catch (e) {
      logError(e.toString());
      return 0;
    }
  }

  Future<String?> getTokenName(
      {required Crypto network, required String contractAddress}) async {
    try {
      if (network.rpcUrls == null) {
        throw Exception('RPC URL  is not provided');
      }

      final client = Web3Client(network.rpcUrls?.first ?? "", httpClient);
      final EthereumAddress contractAddr =
          EthereumAddress.fromHex(contractAddress);
      final contract = DeployedContract(
          ContractAbi.fromJson(standardTokenAbi, ""), contractAddr);
      final balanceFunction = contract.function("name");
      final result = await client
          .call(contract: contract, function: balanceFunction, params: []);
      return (result.first as String);
    } catch (e) {
      logError(e.toString());
      return null;
    }
  }

  Future<BigInt?> getTokenDecimals(
      {required Crypto network, required String contractAddress}) async {
    try {
      if (network.rpcUrls == null) {
        throw Exception('RPC URL  is not provided');
      }

      final client = Web3Client(network.rpcUrls?.first ?? "", httpClient);
      final EthereumAddress contractAddr =
          EthereumAddress.fromHex(contractAddress);
      final contract = DeployedContract(
          ContractAbi.fromJson(standardTokenAbi, ""), contractAddr);
      final balanceFunction = contract.function("decimals");
      final result = await client
          .call(contract: contract, function: balanceFunction, params: []);
      return (result.first as BigInt);
    } catch (e) {
      logError(e.toString());
      return null;
    }
  }

  Future<String?> getTokenSymbol(
      {required Crypto network, required String contractAddress}) async {
    try {
      if (network.rpcUrls == null) {
        throw Exception('RPC URL  is not provided');
      }

      final client = Web3Client(network.rpcUrls?.first ?? "", httpClient);
      final EthereumAddress contractAddr =
          EthereumAddress.fromHex(contractAddress);
      final contract = DeployedContract(
          ContractAbi.fromJson(standardTokenAbi, ""), contractAddr);
      final balanceFunction = contract.function("symbol");
      final result = await client
          .call(contract: contract, function: balanceFunction, params: []);
      return (result.first as String);
    } catch (e) {
      logError(e.toString());
      return null;
    }
  }

  Future<SearchingContractInfo?> getCryptoInfo(
      {required String address, required Crypto network}) async {
    try {
      SearchingContractInfo? info;
      final name =
          await getTokenName(network: network, contractAddress: address);
      final decimals =
          await getTokenDecimals(network: network, contractAddress: address);
      final symbol =
          await getTokenSymbol(network: network, contractAddress: address);
      if (symbol != null || decimals != null || name != null) {
        info = SearchingContractInfo(
            name: name ?? "Unknown",
            symbol: symbol ?? "Unknown",
            decimals: BigInt.from(18));
      }
      return info;
    } catch (e) {
      logError(e.toString());
      return null;
    }
  }

  Future<String?> approveTokenTransfer(
      {required TransactionToConfirm data,
      required BuildContext context,
      required AppColors colors,
      required int operationType}) async {
    try {
      final web3InteractionManager = EthInteractionManager();
      final from = data.account.address;
      final to = data.addressTo;
      final token = data.crypto;
      final account = data.account;

      final network = token.network;

      final EthereumAddress sender = EthereumAddress.fromHex(from);
      final EthereumAddress receiver = EthereumAddress.fromHex(to);
      final EthereumAddress tokenContract =
          EthereumAddress.fromHex(token.contractAddress ?? "");

      final contract = DeployedContract(
        ContractAbi.fromJson(standardTokenAbi, "Token"),
        tokenContract,
      );
      final transferFunction = contract.function("transfer");

      if (account.isWatchOnly) {
        showWatchOnlyWaring(colors: colors, context: context);
        throw Exception(
            "This account is a watch-only account, you can't send transactions.");
      }

      if (network?.rpcUrls == null) {
        throw Exception('RPC URL is not provided');
      }

      BigInt? estimatedGas = data.gasBigint;

      log("Estimated gas ${estimatedGas.toString()}");

      BigInt valueInWei = data.value.isNotEmpty
          ? BigInt.parse(data.value.replaceFirst("0x", ""), radix: 16)
          : BigInt.zero;

      log("value wei $valueInWei");
      if (estimatedGas == null) {
        throw Exception("Failed to estimate gas");
      }
      BigInt? gasLimit = (estimatedGas * BigInt.from(130)) ~/ BigInt.from(100);

      log("Gas limit: $gasLimit");

      final gasPriceResult = await web3InteractionManager.getGasPrice(
          network?.rpcUrls?.first ?? "https://opbnb-mainnet-rpc.bnbchain.org");
      BigInt gasPrice =
          gasPriceResult != BigInt.zero ? gasPriceResult : BigInt.from(100000);

      final cryptoPrice =
          await priceManager.getTokenMarketData(network?.cgSymbol ?? "");

      final confirmedResponse = await askUserForConfirmation(
        crypto: token,
        operationType: operationType,
        cryptoPrice: cryptoPrice?.currentPrice ?? 0,
        estimatedGas: estimatedGas,
        gasPrice: gasPrice,
        gasLimit: gasLimit,
        valueInWei: valueInWei,
        txData: data,
        context: context,
        colors: colors,
        currentAccount: account,
      );

      final confirmed = confirmedResponse.ok;

      if (!confirmed) {
        throw Exception("Transaction rejected by user");
      }
      log("confirmed Response ${confirmedResponse.gasLimit.toInt()}");
      log("EtherAmount Response ${EtherAmount.inWei(confirmedResponse.gasPrice)}");

      final Transaction transaction = Transaction.callContract(
        contract: contract,
        function: transferFunction,
        parameters: [receiver, valueInWei],
        from: sender,
        maxGas: confirmedResponse.gasLimit.toInt() > 0
            ? confirmedResponse.gasLimit.toInt() * 2
            : null,
        gasPrice: confirmedResponse.gasPrice > BigInt.zero
            ? EtherAmount.inWei(confirmedResponse.gasPrice)
            : null,
      );

      String userPassword = "";
      userPassword =
          await askPassword(context: context, colors: colors, useBio: true);

      if (userPassword.isNotEmpty) {
        final result = await web3InteractionManager
            .sendTransaction(
                colors: colors,
                context: context,
                transaction: transaction,
                chainId: network?.chainId ?? 204,
                rpcUrl: network?.rpcUrls?.firstOrNull ?? "",
                password: userPassword,
                address: from)
            .withLoading(context, colors);

        return result;
      } else {
        throw Exception("An error occurred while trying to get the password");
      }
    } catch (e) {
      logError(e.toString());
      rethrow;
    }
  }
}

String standardTokenAbi = """
[{"inputs":[],"payable":false,"stateMutability":"nonpayable","type":"constructor"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"owner","type":"address"},{"indexed":true,"internalType":"address","name":"spender","type":"address"},{"indexed":false,"internalType":"uint256","name":"value","type":"uint256"}],"name":"Approval","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"previousOwner","type":"address"},{"indexed":true,"internalType":"address","name":"newOwner","type":"address"}],"name":"OwnershipTransferred","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"from","type":"address"},{"indexed":true,"internalType":"address","name":"to","type":"address"},{"indexed":false,"internalType":"uint256","name":"value","type":"uint256"}],"name":"Transfer","type":"event"},{"constant":true,"inputs":[],"name":"_decimals","outputs":[{"internalType":"uint8","name":"","type":"uint8"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":true,"inputs":[],"name":"_name","outputs":[{"internalType":"string","name":"","type":"string"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":true,"inputs":[],"name":"_symbol","outputs":[{"internalType":"string","name":"","type":"string"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":true,"inputs":[{"internalType":"address","name":"owner","type":"address"},{"internalType":"address","name":"spender","type":"address"}],"name":"allowance","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":false,"inputs":[{"internalType":"address","name":"spender","type":"address"},{"internalType":"uint256","name":"amount","type":"uint256"}],"name":"approve","outputs":[{"internalType":"bool","name":"","type":"bool"}],"payable":false,"stateMutability":"nonpayable","type":"function"},{"constant":true,"inputs":[{"internalType":"address","name":"account","type":"address"}],"name":"balanceOf","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":false,"inputs":[{"internalType":"uint256","name":"amount","type":"uint256"}],"name":"burn","outputs":[{"internalType":"bool","name":"","type":"bool"}],"payable":false,"stateMutability":"nonpayable","type":"function"},{"constant":true,"inputs":[],"name":"decimals","outputs":[{"internalType":"uint8","name":"","type":"uint8"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":false,"inputs":[{"internalType":"address","name":"spender","type":"address"},{"internalType":"uint256","name":"subtractedValue","type":"uint256"}],"name":"decreaseAllowance","outputs":[{"internalType":"bool","name":"","type":"bool"}],"payable":false,"stateMutability":"nonpayable","type":"function"},{"constant":true,"inputs":[],"name":"getOwner","outputs":[{"internalType":"address","name":"","type":"address"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":false,"inputs":[{"internalType":"address","name":"spender","type":"address"},{"internalType":"uint256","name":"addedValue","type":"uint256"}],"name":"increaseAllowance","outputs":[{"internalType":"bool","name":"","type":"bool"}],"payable":false,"stateMutability":"nonpayable","type":"function"},{"constant":false,"inputs":[{"internalType":"uint256","name":"amount","type":"uint256"}],"name":"mint","outputs":[{"internalType":"bool","name":"","type":"bool"}],"payable":false,"stateMutability":"nonpayable","type":"function"},{"constant":true,"inputs":[],"name":"name","outputs":[{"internalType":"string","name":"","type":"string"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":true,"inputs":[],"name":"owner","outputs":[{"internalType":"address","name":"","type":"address"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":false,"inputs":[],"name":"renounceOwnership","outputs":[],"payable":false,"stateMutability":"nonpayable","type":"function"},{"constant":true,"inputs":[],"name":"symbol","outputs":[{"internalType":"string","name":"","type":"string"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":true,"inputs":[],"name":"totalSupply","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":false,"inputs":[{"internalType":"address","name":"recipient","type":"address"},{"internalType":"uint256","name":"amount","type":"uint256"}],"name":"transfer","outputs":[{"internalType":"bool","name":"","type":"bool"}],"payable":false,"stateMutability":"nonpayable","type":"function"},{"constant":false,"inputs":[{"internalType":"address","name":"sender","type":"address"},{"internalType":"address","name":"recipient","type":"address"},{"internalType":"uint256","name":"amount","type":"uint256"}],"name":"transferFrom","outputs":[{"internalType":"bool","name":"","type":"bool"}],"payable":false,"stateMutability":"nonpayable","type":"function"},{"constant":false,"inputs":[{"internalType":"address","name":"newOwner","type":"address"}],"name":"transferOwnership","outputs":[],"payable":false,"stateMutability":"nonpayable","type":"function"}]""";
