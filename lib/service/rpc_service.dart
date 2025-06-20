import 'package:flutter/material.dart';
import 'package:moonwallet/logger/logger.dart';
import 'package:moonwallet/service/web3_interactions/evm/eth_interaction_manager.dart';
import 'package:moonwallet/service/web3_interactions/evm/web3_client.dart';
import 'package:moonwallet/service/web3_interactions/svm/solana_interaction_manager.dart';
import 'package:moonwallet/types/account_related_types.dart';
import 'package:moonwallet/types/types.dart';
import 'package:web3dart/web3dart.dart';

class RpcService {
  final EthInteractionManager _ethClient = EthInteractionManager();
  final SolanaInteractionManager _solanaClient = SolanaInteractionManager();

  Future<String?> generatePrivateKe(
      NetworkType ecosystem, String mnemonic) async {
    try {
      switch (ecosystem) {
        case NetworkType.evm:
          return _ethClient.ethAddresses
              .derivateEthereumKeyFromMnemonic(mnemonic);

        case NetworkType.svm:
          return (await _solanaClient.solAddress.getPrivateKey(mnemonic));
           
           

          break;
        default:
          return null;
      }
    } catch (e) {
      logError(e.toString());
      return null;
    }
  }

  Future<String> getBalance(Crypto crypto, PublicAccount account) async {
    try {
      final networkType = crypto.getNetworkType;
      switch (networkType) {
        case NetworkType.evm:
          final balance = await _ethClient.getUserBalance(account, crypto);
          return balance;

        case NetworkType.svm:
          final balance = await _solanaClient.getBalance(account, crypto);

          return balance;
      }
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

  Future<String> generateSolanaAddress(String mnemonic) async {
    try {
      final address = await _solanaClient.solAddress.generateAddress(mnemonic);
      return address ?? "";
    } catch (e) {
      logError(e.toString());
      return "";
    }
  }

  Future<String?> sentTransaction(
    BasicTransactionData transactionData,
    AppColors colors,
    BuildContext context,
  ) async {
    try {
      final networkType = transactionData.crypto.getNetworkType;
      switch (networkType) {
        case NetworkType.evm:
          return _ethClient.handleTransfer(transactionData, colors, context);
        case NetworkType.svm:
          return _solanaClient.handleTransfer(transactionData, colors, context);
      }
    } catch (e) {
      logError(e.toString());
      rethrow;
    }
  }

  Future<TransactionReceiptData?> getTransactionReceipt(
      String transactionId, Crypto crypto) async {
    try {
      final networkType = crypto.getNetworkType;
      switch (networkType) {
        case NetworkType.evm:
          final receipt = await getEthReceipt(transactionId, crypto);
          if (receipt == null) {
            return null;
          }
          return TransactionReceiptData(
              from: receipt.from?.hex ?? "",
              to: receipt.to?.hex ?? "",
              transactionId: transactionId,
              block: receipt.blockNumber.toString(),
              status: receipt.status);
        case NetworkType.svm:
          // TODO: Implement SVM transaction receipt handling
          return null;
      }
    } catch (e) {
      logError(e.toString());
      rethrow;
    }
  }

  Future<TransactionReceipt?> getEthReceipt(String? tx, Crypto crypto) async {
    try {
      final web3Client = DynamicWeb3Client(
          rpcUrl: (!crypto.isNative == true
                  ? crypto.network?.rpcUrls?.firstOrNull
                  : crypto.rpcUrls?.firstOrNull) ??
              "");
      final receipt = await web3Client.getReceipt(tx ?? "");
      return receipt;
    } catch (e) {
      logError(e.toString());
      return null;
    }
  }

  String? validateAddress(String address, Crypto crypto) {
    try {
      final networkType = crypto.getNetworkType;
      switch (networkType) {
        case NetworkType.evm:
          return _ethClient.ethAddresses.isAddressValid(address)
              ? null
              : "Invalid address";
        case NetworkType.svm:
          return _solanaClient.solAddress.isAddressValid(address)
              ? null
              : "Invalid Solana address";
      }
    } catch (e) {
      logError(e.toString());
      return "Invalid address";
    }
  }

  bool? validateAddressUsingType(String address, NetworkType networkType) {
    try {
      switch (networkType) {
        case NetworkType.evm:
          return _ethClient.ethAddresses.isAddressValid(address);
        case NetworkType.svm:
          return _solanaClient.solAddress.isAddressValid(address);
      }
    } catch (e) {
      logError(e.toString());
      return false;
    }
  }

  Future<bool?> validatePrivateKey(
      String privateKey, NetworkType networkType) async {
    try {
      switch (networkType) {
        case NetworkType.evm:
          return _ethClient.ethAddresses.isPrivateKeyValid(privateKey);
        case NetworkType.svm:
          return await _solanaClient.solAddress.isPrivateKeyValid(privateKey);
      }
    } catch (e) {
      logError(e.toString());
      return false;
    }
  }
}
