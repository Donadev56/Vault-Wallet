import 'package:flutter/material.dart';
import 'package:flutter_web3_webview/flutter_web3_webview.dart';
import 'package:moonwallet/logger/logger.dart';
import 'package:moonwallet/service/price_manager.dart';
import 'package:moonwallet/service/web3.dart';
import 'package:moonwallet/service/web3_interaction.dart';
import 'package:moonwallet/types/types.dart';
import 'package:moonwallet/widgets/askUserforconf.dart';
import 'package:moonwallet/widgets/bottom_pin_copy.dart';
import 'package:web3dart/web3dart.dart';
import 'package:http/http.dart';

class TokenManager {
  final httpClient = Client();
  final priceManager = PriceManager();
  final web3manager = Web3Manager();

  Future<double> getTokenBalance(Crypto token, String address) async {
    try {
      if (token.network?.rpc == null && token.rpc == null) {
        throw Exception('RPC URL  is not provided');
      }
      if (token.contractAddress == null ||
          (token.contractAddress as String).isEmpty) {
        logError('Contract address is not provided');
        return 0;
      }
      final client =
          Web3Client(token.network?.rpc ?? token.rpc ?? "", httpClient);
      final EthereumAddress contractAddr =
          EthereumAddress.fromHex(token.contractAddress as String);
      final contract = DeployedContract(
          ContractAbi.fromJson(standardTokenAbi, ""), contractAddr);
      final balanceFunction = contract.function("balanceOf");
      final result = await client.call(
          contract: contract,
          function: balanceFunction,
          params: [EthereumAddress.fromHex(address)]);
      return ((result.first as BigInt).toDouble() / 1e18);
    } catch (e) {
      logError(e.toString());
      return 0;
    }
  }

  Future<String?> getTokenName(
      {required Crypto network, required String contractAddress}) async {
    try {
      if (network.rpc == null) {
        throw Exception('RPC URL  is not provided');
      }

      final client = Web3Client(network.rpc ?? "", httpClient);
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
      if (network.rpc == null) {
        throw Exception('RPC URL  is not provided');
      }

      final client = Web3Client(network.rpc ?? "", httpClient);
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
      if (network.rpc == null) {
        throw Exception('RPC URL  is not provided');
      }

      final client = Web3Client(network.rpc ?? "", httpClient);
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

  Future<String?> transferToken(
      {required JsTransactionObject data,
      required bool mounted,
      required BuildContext context,
      required PublicData currentAccount,
      required Crypto currentNetwork,
      required Color primaryColor,
      required Color textColor,
      required Color secondaryColor,
      required AppColors colors,
      required Color actionsColor,
      required int operationType}) async {
    try {
      final web3InteractionManager = Web3InteractionManager();

      final EthereumAddress sender = EthereumAddress.fromHex(data.from ?? "");
      final EthereumAddress receiver = EthereumAddress.fromHex(data.to ?? "");
      final EthereumAddress tokenContract =
          EthereumAddress.fromHex(currentNetwork.contractAddress ?? "");

      final contract = DeployedContract(
        ContractAbi.fromJson(standardTokenAbi, "Token"),
        tokenContract,
      );
      final transferFunction = contract.function("transfer");

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

      if (currentNetwork.network?.rpc == null) {
        throw Exception('RPC URL is not provided');
      }

      BigInt estimatedGas = await web3InteractionManager.estimateGas(
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

      BigInt? gasLimit = data.gas != null
          ? BigInt.parse(data.gas!.replaceFirst("0x", ""), radix: 16)
          : (estimatedGas * BigInt.from(130)) ~/ BigInt.from(100);
      final gasPriceResult = await web3InteractionManager.getGasPrice(
          currentNetwork.network?.rpc ??
              "https://opbnb-mainnet-rpc.bnbchain.org");
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
          crypto: currentNetwork,
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
        log("confirmed Response ${confirmedResponse.gasLimit.toInt()}");
        log("EtherAmount Response ${EtherAmount.inWei(confirmedResponse.gasPrice)}");

        final Transaction transaction = Transaction.callContract(
          contract: contract,
          function: transferFunction,
          parameters: [receiver, valueInWei],
          from: sender,
          maxGas: confirmedResponse.gasLimit.toInt(),
          gasPrice: EtherAmount.inWei(confirmedResponse.gasPrice),
        );

        String userPassword = "";

        if (!mounted) {
          throw Exception("Internal error");
        }

        final response = await showPinModalBottomSheet(
            colors: colors,
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
          final result = await web3InteractionManager.sendTransaction(
              transaction: transaction,
              chainId: currentNetwork.network?.chainId ?? 204,
              rpcUrl: currentNetwork.network?.rpc ??
                  "https://opbnb-mainnet-rpc.bnbchain.org",
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
      logError(e.toString());
      return null;
    }
  }
}

String standardTokenAbi = """
[{"inputs":[],"payable":false,"stateMutability":"nonpayable","type":"constructor"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"owner","type":"address"},{"indexed":true,"internalType":"address","name":"spender","type":"address"},{"indexed":false,"internalType":"uint256","name":"value","type":"uint256"}],"name":"Approval","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"previousOwner","type":"address"},{"indexed":true,"internalType":"address","name":"newOwner","type":"address"}],"name":"OwnershipTransferred","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"from","type":"address"},{"indexed":true,"internalType":"address","name":"to","type":"address"},{"indexed":false,"internalType":"uint256","name":"value","type":"uint256"}],"name":"Transfer","type":"event"},{"constant":true,"inputs":[],"name":"_decimals","outputs":[{"internalType":"uint8","name":"","type":"uint8"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":true,"inputs":[],"name":"_name","outputs":[{"internalType":"string","name":"","type":"string"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":true,"inputs":[],"name":"_symbol","outputs":[{"internalType":"string","name":"","type":"string"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":true,"inputs":[{"internalType":"address","name":"owner","type":"address"},{"internalType":"address","name":"spender","type":"address"}],"name":"allowance","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":false,"inputs":[{"internalType":"address","name":"spender","type":"address"},{"internalType":"uint256","name":"amount","type":"uint256"}],"name":"approve","outputs":[{"internalType":"bool","name":"","type":"bool"}],"payable":false,"stateMutability":"nonpayable","type":"function"},{"constant":true,"inputs":[{"internalType":"address","name":"account","type":"address"}],"name":"balanceOf","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":false,"inputs":[{"internalType":"uint256","name":"amount","type":"uint256"}],"name":"burn","outputs":[{"internalType":"bool","name":"","type":"bool"}],"payable":false,"stateMutability":"nonpayable","type":"function"},{"constant":true,"inputs":[],"name":"decimals","outputs":[{"internalType":"uint8","name":"","type":"uint8"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":false,"inputs":[{"internalType":"address","name":"spender","type":"address"},{"internalType":"uint256","name":"subtractedValue","type":"uint256"}],"name":"decreaseAllowance","outputs":[{"internalType":"bool","name":"","type":"bool"}],"payable":false,"stateMutability":"nonpayable","type":"function"},{"constant":true,"inputs":[],"name":"getOwner","outputs":[{"internalType":"address","name":"","type":"address"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":false,"inputs":[{"internalType":"address","name":"spender","type":"address"},{"internalType":"uint256","name":"addedValue","type":"uint256"}],"name":"increaseAllowance","outputs":[{"internalType":"bool","name":"","type":"bool"}],"payable":false,"stateMutability":"nonpayable","type":"function"},{"constant":false,"inputs":[{"internalType":"uint256","name":"amount","type":"uint256"}],"name":"mint","outputs":[{"internalType":"bool","name":"","type":"bool"}],"payable":false,"stateMutability":"nonpayable","type":"function"},{"constant":true,"inputs":[],"name":"name","outputs":[{"internalType":"string","name":"","type":"string"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":true,"inputs":[],"name":"owner","outputs":[{"internalType":"address","name":"","type":"address"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":false,"inputs":[],"name":"renounceOwnership","outputs":[],"payable":false,"stateMutability":"nonpayable","type":"function"},{"constant":true,"inputs":[],"name":"symbol","outputs":[{"internalType":"string","name":"","type":"string"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":true,"inputs":[],"name":"totalSupply","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":false,"inputs":[{"internalType":"address","name":"recipient","type":"address"},{"internalType":"uint256","name":"amount","type":"uint256"}],"name":"transfer","outputs":[{"internalType":"bool","name":"","type":"bool"}],"payable":false,"stateMutability":"nonpayable","type":"function"},{"constant":false,"inputs":[{"internalType":"address","name":"sender","type":"address"},{"internalType":"address","name":"recipient","type":"address"},{"internalType":"uint256","name":"amount","type":"uint256"}],"name":"transferFrom","outputs":[{"internalType":"bool","name":"","type":"bool"}],"payable":false,"stateMutability":"nonpayable","type":"function"},{"constant":false,"inputs":[{"internalType":"address","name":"newOwner","type":"address"}],"name":"transferOwnership","outputs":[],"payable":false,"stateMutability":"nonpayable","type":"function"}]""";
