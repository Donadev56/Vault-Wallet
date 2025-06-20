import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:moonwallet/logger/logger.dart';
import 'package:moonwallet/service/external_data/price_manager.dart';
import 'package:moonwallet/service/web3_interactions/evm/eth_interaction_manager.dart';
import 'package:moonwallet/types/account_related_types.dart';
import 'package:moonwallet/types/types.dart';
import 'package:moonwallet/widgets/func/transactions/evm/ask_user_evm.dart';
import 'package:moonwallet/widgets/func/account_related/show_watch_only_warning.dart';
import 'package:web3dart/web3dart.dart';
import 'package:http/http.dart';

class TokenManager {
  final httpClient = Client();
  final priceManager = PriceManager();

  Future<BigInt?> getBalance({
    required Web3Client client,
    required Crypto token,
    required String address,
  }) async {
    try {
      final contractAddress = token.contractAddress;

      if (contractAddress == null || contractAddress.isEmpty) {
        logError("Missing contract address for token: ${token.name}");
        return null;
      }

      final ethAddress = EthereumAddress.fromHex(address);
      final contractAddr = EthereumAddress.fromHex(contractAddress);

      final standardContract = DeployedContract(
        ContractAbi.fromJson(standardTokenAbi, ""),
        contractAddr,
      );

      final balanceOfFn = standardContract.function("balanceOf");
      final result = await client.call(
        contract: standardContract,
        function: balanceOfFn,
        params: [ethAddress],
      );
      if (result.isNotEmpty) return result.first as BigInt;
      return null;
    } catch (e) {
      logError("tryGetBalance exception for ${token.name}: $e");
      return null;
    }
  }

  Future<String> getTokenBalance(Crypto token, String address) async {
    try {
      if (token.network?.rpcUrls == null || token.rpcUrls?.isEmpty == true) {
        throw Exception('RPC URL  is not provided');
      }

      if (token.contractAddress == null ||
          (token.contractAddress as String).isEmpty) {
        logError('Contract address is not provided');
        return "0";
      }
      final client =
          Web3Client(token.network?.rpcUrls?.first ?? "", httpClient);
      final result =
          await getBalance(client: client, token: token, address: address);
      if (result == null) {
        throw "No result found";
      }
      Decimal resultDecimal = (Decimal.fromBigInt(result) /
              (Decimal.fromInt(10).pow(token.decimals).toDecimal()))
          .toDecimal();
      return resultDecimal.toString();
    } catch (e) {
      logError(e.toString());
      return "0";
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
            decimals: decimals ?? BigInt.from(18));
      }
      return info;
    } catch (e) {
      logError(e.toString());
      return null;
    }
  }

  _validateAccount(
      PublicAccount account, BuildContext context, AppColors colors) {
    if (account.isWatchOnly) {
      showWatchOnlyWaring(colors: colors, context: context);
      throw Exception(
          "This account is a watch-only account, you can't send transactions.");
    }
  }

  _validRpcUrl(Crypto network) {
    if (network.rpcUrls == null) {
      throw Exception('RPC URL is not provided');
    }
  }

  _validateNativeBalance(BigInt estimatedGas, TransactionToConfirm data) async {
    final nativeTokenBalance = await EthInteractionManager()
        .getUserBalance(data.account, data.crypto.network!);
    final nativeBalanceDecimal = nativeTokenBalance.toDecimal();

    final transactionFee =
        (estimatedGas * data.gasPrice) / BigInt.from(10).pow(18);

    log("Fees ${transactionFee.toStringAsFixed(8)}");

    if (nativeBalanceDecimal.toDouble() < transactionFee) {
      throw Exception(
          "Insufficient ${data.crypto.network?.symbol} balance , add ${(transactionFee - nativeBalanceDecimal.toDouble()).toStringAsFixed(8)}");
    }
  }

  Future<String?> approveTokenTransfer(
      {required TransactionToConfirm data,
      required BuildContext context,
      required AppColors colors,
      required int operationType}) async {
    try {
      final web3InteractionManager = EthInteractionManager();
      final from = data.account.evmAddress;
      final to = data.addressTo;
      final token = data.crypto;
      final account = data.account;

      final network = token.network;
      if (network == null) {
        throw "Network not found";
      }

      if (from == null) {
        throw ArgumentError("From cannot be null");
      }

      final EthereumAddress sender = EthereumAddress.fromHex(from);
      final EthereumAddress receiver = EthereumAddress.fromHex(to);
      final EthereumAddress tokenContract =
          EthereumAddress.fromHex(token.contractAddress ?? "");

      final contract = DeployedContract(
        ContractAbi.fromJson(standardTokenAbi, "Token"),
        tokenContract,
      );
      final transferFunction = contract.function("transfer");

      _validateAccount(account, context, colors);
      _validRpcUrl(network);

      final estimatedGas = await Web3Client(
                  data.crypto.network?.rpcUrls?.firstOrNull ?? "", httpClient)
              .estimateGas(
            sender: sender,
            to: tokenContract,
            data: transferFunction.encodeCall([receiver, data.valueBigInt]),
          ) +
          BigInt.from(10000);

      _validateNativeBalance(estimatedGas, data);

      log("Estimated gas ${estimatedGas.toString()}");

      BigInt valueInWei = data.valueBigInt;

      log("value wei $valueInWei");

      final confirmedResponse = await askUserEvm(
        crypto: token,
        txData: data,
        context: context,
        colors: colors,
      );

      if (confirmedResponse == null || !confirmedResponse.ok) {
        throw Exception("Transaction rejected by user");
      }
      final Transaction transaction = Transaction.callContract(
        contract: contract,
        function: transferFunction,
        parameters: [receiver, valueInWei],
        from: sender,
        maxGas: confirmedResponse.gasLimit?.toInt() ?? estimatedGas.toInt(),
        gasPrice:
            EtherAmount.inWei(confirmedResponse.gasPrice ?? data.gasPrice),
      );

      final result = await web3InteractionManager.sendTransaction(
          colors: colors,
          context: context,
          transaction: transaction,
          chainId: network.chainId ?? 1,
          rpcUrl: network.rpcUrls?.firstOrNull ?? "",
          account: data.account);

      return result;
    } catch (e) {
      logError(e.toString());
      rethrow;
    }
  }
}

String standardTokenAbi = """
[{"inputs":[],"payable":false,"stateMutability":"nonpayable","type":"constructor"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"owner","type":"address"},{"indexed":true,"internalType":"address","name":"spender","type":"address"},{"indexed":false,"internalType":"uint256","name":"value","type":"uint256"}],"name":"Approval","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"previousOwner","type":"address"},{"indexed":true,"internalType":"address","name":"newOwner","type":"address"}],"name":"OwnershipTransferred","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"from","type":"address"},{"indexed":true,"internalType":"address","name":"to","type":"address"},{"indexed":false,"internalType":"uint256","name":"value","type":"uint256"}],"name":"Transfer","type":"event"},{"constant":true,"inputs":[],"name":"_decimals","outputs":[{"internalType":"uint8","name":"","type":"uint8"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":true,"inputs":[],"name":"_name","outputs":[{"internalType":"string","name":"","type":"string"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":true,"inputs":[],"name":"_symbol","outputs":[{"internalType":"string","name":"","type":"string"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":true,"inputs":[{"internalType":"address","name":"owner","type":"address"},{"internalType":"address","name":"spender","type":"address"}],"name":"allowance","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":false,"inputs":[{"internalType":"address","name":"spender","type":"address"},{"internalType":"uint256","name":"amount","type":"uint256"}],"name":"approve","outputs":[{"internalType":"bool","name":"","type":"bool"}],"payable":false,"stateMutability":"nonpayable","type":"function"},{"constant":true,"inputs":[{"internalType":"address","name":"account","type":"address"}],"name":"balanceOf","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":false,"inputs":[{"internalType":"uint256","name":"amount","type":"uint256"}],"name":"burn","outputs":[{"internalType":"bool","name":"","type":"bool"}],"payable":false,"stateMutability":"nonpayable","type":"function"},{"constant":true,"inputs":[],"name":"decimals","outputs":[{"internalType":"uint8","name":"","type":"uint8"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":false,"inputs":[{"internalType":"address","name":"spender","type":"address"},{"internalType":"uint256","name":"subtractedValue","type":"uint256"}],"name":"decreaseAllowance","outputs":[{"internalType":"bool","name":"","type":"bool"}],"payable":false,"stateMutability":"nonpayable","type":"function"},{"constant":true,"inputs":[],"name":"getOwner","outputs":[{"internalType":"address","name":"","type":"address"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":false,"inputs":[{"internalType":"address","name":"spender","type":"address"},{"internalType":"uint256","name":"addedValue","type":"uint256"}],"name":"increaseAllowance","outputs":[{"internalType":"bool","name":"","type":"bool"}],"payable":false,"stateMutability":"nonpayable","type":"function"},{"constant":false,"inputs":[{"internalType":"uint256","name":"amount","type":"uint256"}],"name":"mint","outputs":[{"internalType":"bool","name":"","type":"bool"}],"payable":false,"stateMutability":"nonpayable","type":"function"},{"constant":true,"inputs":[],"name":"name","outputs":[{"internalType":"string","name":"","type":"string"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":true,"inputs":[],"name":"owner","outputs":[{"internalType":"address","name":"","type":"address"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":false,"inputs":[],"name":"renounceOwnership","outputs":[],"payable":false,"stateMutability":"nonpayable","type":"function"},{"constant":true,"inputs":[],"name":"symbol","outputs":[{"internalType":"string","name":"","type":"string"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":true,"inputs":[],"name":"totalSupply","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":false,"inputs":[{"internalType":"address","name":"recipient","type":"address"},{"internalType":"uint256","name":"amount","type":"uint256"}],"name":"transfer","outputs":[{"internalType":"bool","name":"","type":"bool"}],"payable":false,"stateMutability":"nonpayable","type":"function"},{"constant":false,"inputs":[{"internalType":"address","name":"sender","type":"address"},{"internalType":"address","name":"recipient","type":"address"},{"internalType":"uint256","name":"amount","type":"uint256"}],"name":"transferFrom","outputs":[{"internalType":"bool","name":"","type":"bool"}],"payable":false,"stateMutability":"nonpayable","type":"function"},{"constant":false,"inputs":[{"internalType":"address","name":"newOwner","type":"address"}],"name":"transferOwnership","outputs":[],"payable":false,"stateMutability":"nonpayable","type":"function"}]""";
