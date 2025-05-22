// lib/ethereum/ethereum_provider.dart
// ignore_for_file: unnecessary_null_comparison

import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart';
import 'package:moonwallet/logger/logger.dart';
import 'package:moonwallet/notifiers/providers.dart';
import 'package:moonwallet/service/db/crypto_storage_manager.dart';
import 'package:moonwallet/service/db/known_host_manager.dart';
import 'package:moonwallet/service/web3_interactions/evm/eth_interaction_manager.dart';
import 'package:moonwallet/types/account_related_types.dart';
import 'package:moonwallet/types/types.dart';
import 'package:moonwallet/utils/id_manager.dart';
import 'package:moonwallet/custom/web3_webview/lib/utils/loading.dart';
import 'package:moonwallet/custom/web3_webview/lib/widgets/alert.dart';
import 'package:moonwallet/widgets/func/security/ask_derivate_key.dart';
import 'package:web3dart/web3dart.dart';

import '../json_rpc_method.dart';
import '../exceptions.dart';
import '../models/models.dart';
import '../provider/provider_script.dart';
import '../signing/signing_handler.dart';
import '../transaction/transaction_handler.dart';
import '../utils/hex_utils.dart';
import 'wallet_dialog_service.dart';

class EthereumProvider extends StateNotifier<WalletState> {
  // Singleton pattern
  EthereumProvider(this.ref) : super(WalletState.initial());

  final Ref ref;
  // Dialog service
  final WalletDialogService _dialogService = WalletDialogService.instance;

  // Core components
  late Web3Client _web3client;
  InAppWebViewController? _webViewController;
  EIP6963ProviderInfo? _eip6963ProviderInfo;

  // Block number cache
  DateTime? _lastBlockFetch;
  String? _cachedBlockNumber;
  static const _blockNumberCacheDuration = Duration(seconds: 12);

  void setWebViewController(InAppWebViewController controller) {
    _webViewController = controller;
  }

  Future<void> initialize({
    required NetworkConfig? defaultNetwork,
    required String address,
    required EIP6963ProviderInfo providerInfo,
    List<NetworkConfig> additionalNetworks = const [],
    WalletDialogTheme? theme,
    required PublicAccount account,
  }) async {
    // Configure dialog service theme
    _dialogService.configureTheme(theme ?? WalletDialogTheme());
    if (defaultNetwork == null) {
      throw WalletException("The default network is required");
    }

    Map<String, NetworkConfig> networks = {};
    networks[defaultNetwork.chainId] = defaultNetwork;
    for (final net in additionalNetworks) {
      networks[net.chainId] = net;
    }

    // Configure provider info
    _eip6963ProviderInfo = providerInfo;

    _updateNetwork(defaultNetwork);

    // Initialize Web3 client
    _web3client = Web3Client(
      defaultNetwork.rpcUrls.first,
      Client(),
    );

    state = WalletState(
      account: account,
      networks: networks,
      chainId: defaultNetwork.chainId,
      address: account.evmAddress,
      isConnected: account.evmAddress?.isNotEmpty == false,
    );
    log("The current state with address only is ${state.toJson()}");
  }

  Future<dynamic> handleRequest(String method, List<dynamic>? params,
      AppColors colors, NetworkConfig? network, BuildContext context) async {
    if (network == null) {
      throw WalletException("Network is required");
    }

    log("Method : $method");
    try {
      switch (JsonRpcMethod.fromString(method)) {
        case JsonRpcMethod.ETH_REQUEST_ACCOUNTS:
          return await _handleConnect(colors, context);
        case JsonRpcMethod.ETH_ACCOUNTS:
          return _getConnectedAccounts();
        case JsonRpcMethod.ETH_BLOCK_NUMBER:
          return await _handleBlockNumber();
        case JsonRpcMethod.ETH_CHAIN_ID:
          return state.chainId;
        case JsonRpcMethod.NET_VERSION:
          return state.chainId;
        // from this point
        case JsonRpcMethod.ETH_CALL:
          if (state.account.isWatchOnly) {
            sendWatchOnlyAlert(context, colors);
            throw WalletException('Watch-only wallet');
          }
          final txHandler = await getTxHandler(
              context: context,
              colors: colors,
              web3client: _web3client,
              network: network,
              state: state);
          if (txHandler == null) {
            logError("Unable to get transaction handler");
            throw WalletException('Transaction handler error');
          }

          return await txHandler.handleTransaction(
              params?.first, context, colors);

        case JsonRpcMethod.ETH_SEND_TRANSACTION:
          if (state.account != null && state.account.isWatchOnly) {
            sendWatchOnlyAlert(context, colors);
            throw WalletException('Watch-only wallet');
          }
          if (params == null || params.isEmpty) {
            throw WalletException('Missing call parameters');
          }

          return await _handleSignTransaction(
              params.first, colors, network, context);

        case JsonRpcMethod.ETH_GET_BALANCE:
          final address = params?.first;
          final balance = await _web3client.getBalance(
            EthereumAddress.fromHex(address),
          );
          return balance.getInEther.toString();

        case JsonRpcMethod.ETH_GAS_PRICE:
          final gasPrice = await _web3client.getGasPrice();
          return gasPrice.getInWei.toString();
        case JsonRpcMethod.ETH_ESTIMATE_GAS:
          if (params == null || params.isEmpty) {
            throw WalletException('Missing transaction parameters');
          }
          if (state.account != null && state.account.isWatchOnly) {
            sendWatchOnlyAlert(context, colors);
            throw WalletException('Watch-only wallet');
          }

          final txHandler = await getTxHandler(
              context: context,
              colors: colors,
              web3client: _web3client,
              network: network,
              state: state);
          if (txHandler == null) {
            logError("Unable to get transaction handler");
            throw WalletException('Transaction handler error');
          }

          return await txHandler.estimateGas(params[0]);

        case JsonRpcMethod.PERSONAL_SIGN:
        case JsonRpcMethod.ETH_SIGN:
        case JsonRpcMethod.ETH_SIGN_TYPED_DATA:
        case JsonRpcMethod.ETH_SIGN_TYPED_DATA_V1:
        case JsonRpcMethod.ETH_SIGN_TYPED_DATA_V3:
        case JsonRpcMethod.ETH_SIGN_TYPED_DATA_V4:
          if (params == null || params.isEmpty) {
            throw WalletException('Missing sign parameters');
          }
          if (state.account != null && state.account.isWatchOnly) {
            sendWatchOnlyAlert(context, colors);
            throw WalletException('Watch-only wallet');
          }
          return await _handleSignMessage(
              method, params, colors, context, network);
        case JsonRpcMethod.PERSONAL_EC_RECOVER:
          if (params == null || params.isEmpty) {
            throw WalletException('Missing sign parameters');
          }
          if (state.account != null && state.account.isWatchOnly) {
            sendWatchOnlyAlert(context, colors);
            throw WalletException('Watch-only wallet');
          }

          final signingHandler = await getSigningHandler(
              context: context, colors: colors, state: state);
          if (signingHandler == null) {
            logError("Unable to get signing handler");
            throw WalletException('Credentials error');
          }

          return signingHandler.personalEcRecover(params[0], params[1]);

        case JsonRpcMethod.WALLET_SWITCH_ETHEREUM_CHAIN:
          if (params?.isNotEmpty == true) {
            final newChainId = params?.first['chainId'];
            return await handleSwitchNetwork(newChainId, colors, context);
          }
          throw WalletException('Invalid chain ID');
        case JsonRpcMethod.WALLET_ADD_ETHEREUM_CHAIN:
          if (params?.isNotEmpty == true) {
            return await _handleAddEthereumChain(
                params?.first, colors, context);
          }
          throw WalletException('Invalid network parameters');
        case JsonRpcMethod.WALLET_GET_PERMISSIONS:
          return [
            'eth_accounts',
            'eth_chainId',
            state.account.isWatchOnly == null ? "" : 'personal_sign'
          ];
        case JsonRpcMethod.WALLET_REVOKE_PERMISSIONS:
          return true;
        case JsonRpcMethod.WALLET_WATCH_ASSET:
          log("----------- Params ------------\n");
          log("$params");
        case JsonRpcMethod.ETH_GET_TRANSACTION_RECEIPT:
          return await getEthTransactionReceipt(params?.firstOrNull ?? "");

        default:
          print('=======================> Method $method not supported');
          return null;
        // throw WalletException('Method $method not supported');
      }
    } catch (e) {
      throw WalletException(e.toString());
    }
  }

  Future<Map<dynamic, dynamic>> getEthTransactionReceipt(String hash) async {
    try {
      final response = await _web3client.getTransactionReceipt(hash);
      if (response == null) {
        throw Exception("Invalid response");
      }
      return {
        "jsonrpc": "2.0",
        "id": "1",
        "transactionHash": HexUtils.bytesToHex(response.transactionHash),
        "transactionIndex": HexUtils.numberToHex(response.transactionIndex),
        "blockHash": HexUtils.bytesToHex(response.blockHash),
        "blockNumber": HexUtils.numberToHex(response.blockNumber.blockNum),
        "logs": [],
        "from": response.from?.hex,
        "to": response.to?.hex,
        "cumulativeGasUsed": HexUtils.numberToHex(response.cumulativeGasUsed),
        "gasUsed": HexUtils.numberToHex(response.gasUsed),
        "status": response.status != null
            ? HexUtils.numberToHex(response.status == true ? 1 : 0)
            : null,
        "type": null,
      };
    } catch (e) {
      logError(e.toString());
      throw WalletException('Error while getting eth receipt');
    }
  }

  String getProviderScript() {
    return ProviderScriptGenerator.generate(
      chainId: state.chainId,
      accounts: _getConnectedAccounts(),
      isConnected: state.isConnected,
      providerInfo: _eip6963ProviderInfo!,
    );
  }
/*
  void dispose() {
    _web3client.dispose();
  }*/

  // Method handlers
  Future<List<String>> _handleConnect(
      AppColors colors, BuildContext context) async {
    try {
      final hostManager = KnownHostManager();
      bool? confirmed = false;
      final host = (await _webViewController?.getUrl())?.host ?? '';
      final savedHosts =
          await hostManager.getKnownHost(address: state.address ?? "");

      if (savedHosts.isNotEmpty) {
        if (savedHosts.contains(host)) {
          log("Saved host already exists");
          return [state.address!];
        }
      }

      confirmed = await _dialogService.showConnectWallet(context,
          address: state.address!,
          ctrl: _webViewController!,
          appName: _eip6963ProviderInfo!.name,
          colors: colors);

      if (confirmed != true) {
        throw WalletException('User rejected connection');
      }
      await hostManager.addSingleKnownHost(
          address: state.address ?? "", host: host);

      _updateState(
        address: state.address,
        isConnected: true,
      );

      return [state.address!];
    } catch (e) {
      _updateState(
        address: null,
        isConnected: false,
      );
      rethrow;
    }
  }

  Future<String> _handleSignMessage(String method, List<dynamic> params,
      AppColors colors, BuildContext context, NetworkConfig network) async {
    try {
      log("Params : ${params.map((p) => p.toString()).toList()}");

      var message = params.first;
      String from = params[1];
      String password = params.length > 2 ? params[2] : '';
      if (JsonRpcMethod.ETH_SIGN == JsonRpcMethod.fromString(method) ||
          JsonRpcMethod.ETH_SIGN_TYPED_DATA_V3 ==
              JsonRpcMethod.fromString(method) ||
          JsonRpcMethod.ETH_SIGN_TYPED_DATA_V4 ==
              JsonRpcMethod.fromString(method)) {
        from = params.first;
        message = params[1];
      }
      final confirmed = await _dialogService.showSignMessage(
        colors: colors,
        context,
        message: message.toString(),
        address: state.address ?? "",
        ctrl: _webViewController!,
      );

      if (confirmed != true) {
        throw WalletException('User rejected signing message');
      }

      final signingHandler = await getSigningHandler(
          context: context, colors: colors, state: state);
      if (signingHandler == null) {
        logError("credentials error");

        throw WalletException("credentials error");
      }

      final result = await signingHandler
          .signMessage(method, from, message)
          .withLoading(context, colors, 'Waiting for signature');
      log("Data $method , from $from , message $message , password $password");
      log("result :  $result");
      return result;
    } catch (e) {
      throw WalletException('Failed to sign message: $e');
    }
  }

  Future _handleSignTransaction(Map<String, dynamic> params, AppColors colors,
      NetworkConfig network, BuildContext context) async {
    try {
      log("current account name : ${state.account.walletName}");
      if (state.account != null && state.account.isWatchOnly) {
        sendWatchOnlyAlert(context, colors);
        throw WalletException('Watch-only wallet cannot send transactions');
      } else {
        log("Not a watch-only wallet");
      }

      final confirmed = await _dialogService.showTransactionConfirm(
        network: network,
        colors: colors,
        context,
        txParams: params,
        ctrl: _webViewController!,
      );

      if (confirmed == true) {
        TransactionHandler? txHandler = await getTxHandler(
            context: context,
            state: state,
            colors: colors,
            web3client: _web3client,
            network: network);

        log("TransactionHandler ${txHandler.toString()}");
        if (txHandler != null) {
          return await txHandler
              .handleTransaction(params, context, colors)
              .withLoading(context, colors, 'Waiting for transaction');
        }
        log("Invalid credentials");
        throw WalletException("credentials error");
      } else {
        throw WalletException('User rejected signing transaction');
      }
    } catch (e) {
      throw WalletException('Failed to sign transaction: $e');
    }
  }

  Future<bool> handleSwitchNetwork(
      String newChainId, AppColors colors, BuildContext context) async {
    if (!state.networks.containsKey(newChainId)) {
      throw WalletException('Network not supported: $newChainId');
    }
    try {
      final network = state.networks[newChainId]!;

      _updateState(chainId: newChainId);
      await _emitToWebView('chainChanged', newChainId);

      await _updateNetwork(network)
          .withLoading(context, colors, 'Switching network');
      return true;
    } catch (e) {
      throw WalletException('Network switch failed: $e');
    }
  }

  Future<bool> _handleAddEthereumChain(Map<String, dynamic> networkParams,
      AppColors colors, BuildContext context) async {
    try {
      final config = NetworkConfig(
        chainId: networkParams['chainId'],
        chainName: networkParams['chainName'],
        nativeCurrency: Crypto(
            name: networkParams['nativeCurrency']['name'],
            color: Colors.grey,
            type: CryptoType.native,
            decimals: networkParams['nativeCurrency']['decimals'],
            cryptoId: IdManager().generateUUID(),
            canDisplay: true,
            symbol: networkParams['nativeCurrency']['symbol'],
            rpcUrls: List<String>.from(networkParams['rpcUrls']),
            networkType: NetworkType.evm,
            chainId: int.parse(networkParams['chainId']),
            explorers: networkParams['blockExplorerUrls'] != null
                ? List<String>.from(networkParams['blockExplorerUrls'])
                : []),
        rpcUrls: List<String>.from(networkParams['rpcUrls']),
        blockExplorerUrls: networkParams['blockExplorerUrls'] != null
            ? List<String>.from(networkParams['blockExplorerUrls'])
            : null,
      );
      // Show add network confirmation
      final confirmed = await _dialogService.showAddNetwork(
        colors: colors,
        context,
        network: config,
      );

      if (confirmed != true) {
        throw WalletException('User rejected adding network');
      }
      _addNetwork(config);
      return true;
    } catch (e) {
      throw WalletException('Failed to add network: ${e.toString()}');
    }
  }

  List<String> _getConnectedAccounts() {
    return state.address != null ? [state.address!] : [];
  }

  Future<String> _handleBlockNumber() async {
    try {
      if (_isBlockNumberCacheValid()) {
        return _cachedBlockNumber!;
      }

      final blockNumber = await _fetchBlockNumber();
      _updateBlockNumberCache(blockNumber);
      return blockNumber;
    } catch (e) {
      throw WalletException('Failed to get block number: $e');
    }
  }

  // Methods helpers
  Future<void> _addNetwork(NetworkConfig targetNetwork) async {
    try {
      final storage = ref.watch(savedCryptosProviderNotifier.notifier);
      if (state.account == null) {
        throw WalletException('No current account');
      }

      if (state.account != null) {
        final manager = CryptoStorageManager();
        final savedCrypto =
            await manager.getSavedCryptos(wallet: state.account);

        if (savedCrypto != null) {
          final networks =
              savedCrypto.where((c) => c.type == CryptoType.native).toList();

          if (networks
              .any((e) => e.chainId == targetNetwork.nativeCurrency.chainId)) {
            throw WalletException("Network already exist");
          }
          // add the network to the browser current network list
          state.networks[targetNetwork.chainId] = targetNetwork;
          // save the network
          await storage.addCrypto(targetNetwork.nativeCurrency);
          log("Added wallet");
        }
      }
    } catch (e) {
      throw WalletException('Failed to add network: $e');
    }
  }

  bool _isBlockNumberCacheValid() {
    if (_lastBlockFetch == null || _cachedBlockNumber == null) {
      return false;
    }
    return DateTime.now().difference(_lastBlockFetch!) <
        _blockNumberCacheDuration;
  }

  void _updateBlockNumberCache(String blockNumber) {
    _cachedBlockNumber = blockNumber;
    _lastBlockFetch = DateTime.now();
  }

  Future<String> _fetchBlockNumber() async {
    try {
      final blockNumber = await _web3client.getBlockNumber();
      return HexUtils.numberToHex(blockNumber);
    } catch (e) {
      throw WalletException('Failed to fetch block number: $e');
    }
  }

  Future<void> _updateNetwork(NetworkConfig network) async {
    _web3client.dispose();
    _web3client = Web3Client(
      network.rpcUrls.first,
      Client(),
    );
  }

  void _updateState({String? address, bool? isConnected, String? chainId}) {
    state = state.copyWith(
      address: address,
      isConnected: isConnected,
      chainId: chainId,
    );
  }

  Future<void> _emitToWebView(String eventName, dynamic data) async {
    if (_webViewController != null) {
      final js = """
        if (window.ethereum) {
          window.ethereum._emit('$eventName', ${jsonEncode(data)});
        }
      """;
      await _webViewController!.evaluateJavascript(source: js);
    }
  }

  Future<SigningHandler?> getSigningHandler(
      {required BuildContext context,
      required AppColors colors,
      WalletState? state}) async {
    try {
      final access = await getAccess(
        context: context,
        colors: colors,
      );
      if (access != null) {
        return SigningHandler(access.cred, access.key);
      } else {
        logError("Incorrect password ${access?.address}");
        throw WalletException('Incorrect password');
      }
    } catch (e) {
      logError('Error ${e.toString()}');

      throw WalletException('Failed to create transaction handler: $e');
    }
  }

  Future<TransactionHandler?> getTxHandler({
    required BuildContext context,
    required AppColors colors,
    required Web3Client web3client,
    required NetworkConfig network,
    WalletState? state,
  }) async {
    try {
      final access = await getAccess(context: context, colors: colors);
      if (access != null) {
        final handler = TransactionHandler(
          web3client,
          access.cred,
          int.parse(network.chainId),
        );
        log("Handler ${handler.toString()}");

        return handler;
      } else {
        logError("An internal error occurred");
        throw WalletException('An internal error occurred');
      }
    } catch (e) {
      logError('Error ${e.toString()}');
      throw WalletException('Failed to create signing handler: $e');
    }
  }

  Future<AccountAccess?> getAccess({
    required BuildContext context,
    required AppColors colors,
  }) async {
    try {
      final deriveKey = await askDerivateKey(context: context, colors: colors);
      final address = state.address;
      if (address == null) {
        throw WalletException("Invalid State : address is null");
      }

      if (deriveKey == null) {
        throw WalletException("Invalid Password");
      }
      final cred = await EthInteractionManager()
          .getAccessUsingKey(deriveKey: deriveKey, account: state.account);
      if (cred == null) {
        throw WalletException("Invalid Password");
      }

      return AccountAccess(address: address, cred: cred.cred, key: cred.key);
    } catch (e) {
      logError("Error ${e.toString()}");
      throw WalletException('Failed to create signing handler: $e');
    }
  }
}

final ethereumProviderNotifier =
    StateNotifierProvider<EthereumProvider, WalletState>((ref) {
  return EthereumProvider(ref);
});
