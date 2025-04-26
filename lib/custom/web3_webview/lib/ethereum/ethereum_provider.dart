// lib/ethereum/ethereum_provider.dart
import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:http/http.dart';
import 'package:moonwallet/logger/logger.dart';
import 'package:moonwallet/service/db/crypto_storage_manager.dart';
import 'package:moonwallet/service/db/known_host_manager.dart';
import 'package:moonwallet/service/web3_interactions/evm/eth_interaction_manager.dart';
import 'package:moonwallet/types/types.dart';
import 'package:moonwallet/utils/id_manager.dart';
import 'package:moonwallet/custom/web3_webview/lib/utils/loading.dart';
import 'package:moonwallet/custom/web3_webview/lib/widgets/alert.dart';
import 'package:moonwallet/widgets/func/security/ask_password.dart';
import 'package:web3dart/web3dart.dart';

import '../json_rpc_method.dart';
import '../exceptions.dart';
import '../models/models.dart';
import '../provider/provider_script.dart';
import '../signing/signing_handler.dart';
import '../transaction/transaction_handler.dart';
import '../utils/hex_utils.dart';
import 'wallet_dialog_service.dart';

class EthereumProvider {
  // Singleton pattern
  static final EthereumProvider _instance = EthereumProvider._internal();
  factory EthereumProvider() => _instance;
  EthereumProvider._internal();

  // Context
  BuildContext? _context;

  // Dialog service
  final WalletDialogService _dialogService = WalletDialogService.instance;

  // Core components
  late Web3Client _web3client;
  PublicData? currentAccount;
  final nullAccount = PublicData(
      keyId: "",
      creationDate: 0,
      walletName: "",
      address: "",
      isWatchOnly: true);

  // State
  WalletState? _state;
  final Map<String, NetworkConfig> _networks = {};
  InAppWebViewController? _webViewController;
  EIP6963ProviderInfo? _eip6963ProviderInfo;

  // Block number cache
  DateTime? _lastBlockFetch;
  String? _cachedBlockNumber;
  static const _blockNumberCacheDuration = Duration(seconds: 12);

  void setContext(BuildContext context) {
    _context = context;
  }

  void setWebViewController(InAppWebViewController controller) {
    _webViewController = controller;
  }

  Future<void> initialize({
    required NetworkConfig defaultNetwork,
    required String address,
    String? privateKey,
    required EIP6963ProviderInfo providerInfo,
    List<NetworkConfig> additionalNetworks = const [],
    WalletDialogTheme? theme,
    required PublicData account,
  }) async {
    // Configure dialog service theme
    _dialogService.configureTheme(theme ?? WalletDialogTheme());

    // Configure provider info
    _eip6963ProviderInfo = providerInfo;

    _updateNetwork(defaultNetwork);

    // Initialize Web3 client
    _web3client = Web3Client(
      defaultNetwork.rpcUrls.first,
      Client(),
    );

    // Initialize credentials

    // Initialize handlers

    // Setup initial state
    if (privateKey != null && privateKey.isNotEmpty) {
      _state = WalletState(
        chainId: defaultNetwork.chainId,
        address: getAddressFromPrivateKey(privateKey),
        isConnected: getAddressFromPrivateKey(privateKey) != null,
      );
      log("The current state with privatekey is ${_state?.toJson()}");
    } else {
      _state = WalletState(
        chainId: defaultNetwork.chainId,
        address: account.address,
        isConnected: account.address.isNotEmpty,
      );
      log("The current state with address only is ${_state?.toJson()}");
    }
    currentAccount = account;
    // Add networks
    log("Additional networks ${additionalNetworks.map((n) => n.toJson()).toList()}");
    _internalAddNetwork(defaultNetwork);
    for (var network in additionalNetworks) {
      _internalAddNetwork(network);
    }
  }

  getAddressFromPrivateKey(String privateKey) {
    final credentials = EthPrivateKey.fromHex(privateKey);
    final address = credentials.address;
    return address.hexEip55;
  }

  Future<dynamic> handleRequest(String method, List<dynamic>? params,
      AppColors colors, NetworkConfig network, BuildContext context) async {
    if (_context == null) {
      throw WalletException('Provider context not set');
    }
    log("Method : $method");
    try {
      switch (JsonRpcMethod.fromString(method)) {
        case JsonRpcMethod.ETH_REQUEST_ACCOUNTS:
          return await _handleConnect(colors);
        case JsonRpcMethod.ETH_ACCOUNTS:
          return _getConnectedAccounts();
        case JsonRpcMethod.ETH_BLOCK_NUMBER:
          return await _handleBlockNumber();
        case JsonRpcMethod.ETH_CHAIN_ID:
          if (_state == null) {
            throw WalletException('Wallet state not initialized');
          }
          return _state?.chainId;
        case JsonRpcMethod.NET_VERSION:
          if (_state == null) {
            throw WalletException('Wallet state not initialized');
          }
          return _state?.chainId;
        // from this point
        case JsonRpcMethod.ETH_CALL:
          if (currentAccount != null && currentAccount!.isWatchOnly) {
            sendWatchOnlyAlert(context, colors);
            throw WalletException('Watch-only wallet');
          }
          final txHandler = await getTxHandler(
              context: context,
              colors: colors,
              web3client: _web3client,
              network: network,
              state: _state);
          if (txHandler == null) {
            logError("Unable to get transaction handler");
            throw WalletException('Transaction handler error');
          }

          return await txHandler.handleTransaction(
              params?.first, context, colors);

        case JsonRpcMethod.ETH_SEND_TRANSACTION:
          if (currentAccount != null && currentAccount!.isWatchOnly) {
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
          if (currentAccount != null && currentAccount!.isWatchOnly) {
            sendWatchOnlyAlert(context, colors);
            throw WalletException('Watch-only wallet');
          }

          final txHandler = await getTxHandler(
              context: context,
              colors: colors,
              web3client: _web3client,
              network: network,
              state: _state);
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
          if (currentAccount != null && currentAccount!.isWatchOnly) {
            sendWatchOnlyAlert(context, colors);
            throw WalletException('Watch-only wallet');
          }
          return await _handleSignMessage(
              method, params, colors, context, network);
        case JsonRpcMethod.PERSONAL_EC_RECOVER:
          if (params == null || params.isEmpty) {
            throw WalletException('Missing sign parameters');
          }
          if (currentAccount != null && currentAccount!.isWatchOnly) {
            sendWatchOnlyAlert(context, colors);
            throw WalletException('Watch-only wallet');
          }

          final signingHandler = await getSigningHandler(
              context: context, colors: colors, state: _state);
          if (signingHandler == null) {
            logError("Unable to get signing handler");
            throw WalletException('Credentials error');
          }

          return signingHandler.personalEcRecover(params[0], params[1]);

        case JsonRpcMethod.WALLET_SWITCH_ETHEREUM_CHAIN:
          if (params?.isNotEmpty == true) {
            final newChainId = params?.first['chainId'];
            return await _handleSwitchNetwork(newChainId, colors, context);
          }
          throw WalletException('Invalid chain ID');
        case JsonRpcMethod.WALLET_ADD_ETHEREUM_CHAIN:
          if (params?.isNotEmpty == true) {
            return await _handleAddEthereumChain(params?.first, colors);
          }
          throw WalletException('Invalid network parameters');
        case JsonRpcMethod.WALLET_GET_PERMISSIONS:
          return [
            'eth_accounts',
            'eth_chainId',
            currentAccount?.isWatchOnly == null ? "" : 'personal_sign'
          ];
        case JsonRpcMethod.WALLET_REVOKE_PERMISSIONS:
          return true;
        default:
          print('=======================> Method $method not supported');
          return null;
        // throw WalletException('Method $method not supported');
      }
    } catch (e) {
      throw WalletException(e.toString());
    }
  }

  String getProviderScript() {
    return ProviderScriptGenerator.generate(
      chainId: _state?.chainId ?? "0x1",
      accounts: _getConnectedAccounts(),
      isConnected: _state?.isConnected ?? false,
      providerInfo: _eip6963ProviderInfo!,
    );
  }

  void dispose() {
    _web3client.dispose();
  }

  // Method handlers
  Future<List<String>> _handleConnect(AppColors colors) async {
    try {
      final hostManager = KnownHostManager();
      bool? confirmed = false;
      final host = (await _webViewController?.getUrl())?.host ?? '';
      final savedHosts =
          await hostManager.getKnownHost(address: _state?.address ?? "");
      if (savedHosts.isNotEmpty) {
        if (savedHosts.contains(host)) {
          log("Saved host already exists");
          confirmed = true;
        } else {
          log("Saved host dont exists");
          confirmed = await _dialogService.showConnectWallet(_context!,
              address: _state?.address! ?? "",
              ctrl: _webViewController!,
              appName: _eip6963ProviderInfo!.name,
              colors: colors);
        }
      } else {
        confirmed = await _dialogService.showConnectWallet(_context!,
            address: _state?.address! ?? "",
            ctrl: _webViewController!,
            appName: _eip6963ProviderInfo!.name,
            colors: colors);
      }

      if (confirmed != true) {
        throw WalletException('User rejected connection');
      }
      await hostManager.addSingleKnownHost(
          address: _state?.address ?? "", host: host);

      _updateState(
        address: _state?.address,
        isConnected: true,
      );

      return [_state?.address! ?? ""];
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
        _context!,
        message: message.toString(),
        address: _state?.address ?? "",
        ctrl: _webViewController!,
      );

      if (confirmed != true) {
        throw WalletException('User rejected signing message');
      }

      final signingHandler = await getSigningHandler(
          context: context, colors: colors, state: _state);
      if (signingHandler == null) {
        logError("credentials error");

        throw WalletException("credentials error");
      }

      final result = await signingHandler
          .signMessage(method, from, message, password)
          .withLoading(_context!, colors, 'Waiting for signature');
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
      log("current account name : ${currentAccount?.walletName}");
      if (currentAccount != null && currentAccount!.isWatchOnly) {
        sendWatchOnlyAlert(context, colors);
        throw WalletException('Watch-only wallet cannot send transactions');
      } else {
        log("Not a watch-only wallet");
      }

      final confirmed = await _dialogService.showTransactionConfirm(
        network: network,
        colors: colors,
        _context!,
        txParams: params,
        ctrl: _webViewController!,
      );

      if (confirmed == true) {
        TransactionHandler? txHandler = await getTxHandler(
            context: context,
            state: _state,
            colors: colors,
            web3client: _web3client,
            network: network);

        log("TransactionHandler ${txHandler.toString()}");
        if (txHandler != null) {
          return await txHandler
              .handleTransaction(params, context, colors)
              .withLoading(_context!, colors, 'Waiting for transaction');
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

  Future<bool> _handleSwitchNetwork(
      String newChainId, AppColors colors, BuildContext context) async {
    if (!_networks.containsKey(newChainId)) {
      throw WalletException('Network not supported: $newChainId');
    }
    try {
      final network = _networks[newChainId]!;

      final confirmed = await _dialogService.showSwitchNetwork(
        colors: colors,
        _context!,
        chain: network,
      );

      if (confirmed != true) {
        throw WalletException('User rejected network switch');
      }

      _updateState(chainId: newChainId);
      await _emitToWebView('chainChanged', newChainId);

      await _updateNetwork(network)
          .withLoading(_context!, colors, 'Switching network');
      return true;
    } catch (e) {
      throw WalletException('Network switch failed: $e');
    }
  }

  Future<bool> handleSwitchNetwork(
      String newChainId, AppColors colors, BuildContext context) async {
    if (!_networks.containsKey(newChainId)) {
      throw WalletException('Network not supported: $newChainId');
    }
    try {
      final network = _networks[newChainId]!;

      _updateState(chainId: newChainId);
      await _emitToWebView('chainChanged', newChainId);

      await _updateNetwork(network)
          .withLoading(_context!, colors, 'Switching network');
      return true;
    } catch (e) {
      throw WalletException('Network switch failed: $e');
    }
  }

  Future<bool> _handleAddEthereumChain(
      Map<String, dynamic> networkParams, AppColors colors) async {
    try {
      final config = NetworkConfig(
        chainId: networkParams['chainId'],
        chainName: networkParams['chainName'],
        nativeCurrency: NativeCurrency(
          name: networkParams['nativeCurrency']['name'],
          symbol: networkParams['nativeCurrency']['symbol'],
          decimals: networkParams['nativeCurrency']['decimals'],
        ),
        rpcUrls: List<String>.from(networkParams['rpcUrls']),
        blockExplorerUrls: networkParams['blockExplorerUrls'] != null
            ? List<String>.from(networkParams['blockExplorerUrls'])
            : null,
      );
      // Show add network confirmation
      final confirmed = await _dialogService.showAddNetwork(
        colors: colors,
        _context!,
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
    return _state?.address != null ? [_state?.address! ?? ""] : [];
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
  Future<void> _addNetwork(NetworkConfig network) async {
    try {
      if (currentAccount != null) {
        final manager = CryptoStorageManager();
        final savedCrypto = await manager.getSavedCryptos(
            wallet: currentAccount ?? nullAccount);
        if (savedCrypto != null) {
          final networks =
              savedCrypto.where((c) => c.type == CryptoType.native).toList();
          if (networks.isNotEmpty) {
            for (final net in networks) {
              if (int.parse(network.chainId) == net.chainId) {
                logError("Network already exists");
                throw WalletException('Network already exists');
              }
            }
            final newId = IdManager().generateUUID();
            final Crypto newCrypto = Crypto(
              decimals: 18,
              name: network.chainName,
              color: Colors.grey,
              type: CryptoType.native,
              valueUsd: 0,
              cryptoId: newId,
              canDisplay: true,
              symbol: network.chainName,
              explorers: network.blockExplorerUrls,
              rpcUrls: network.rpcUrls,
              chainId: int.parse(network.chainId),
              icon: network.iconUrls?[0],
            );
            await manager.addCrypto(
                crypto: newCrypto, wallet: currentAccount ?? nullAccount);
            log("Added wallet");
          }
        }
        for (final net in _networks.values.toList()) {
          if (net.chainId == network.chainId) {
            logError("Network already exists");
            throw WalletException('Network already exists');
          }
        }
        _networks[network.chainId] = network;
      } else {
        logError("No current account");
        throw WalletException('No current account');
      }
    } catch (e) {
      throw WalletException('Failed to add network: $e');
    }
  }

  // Methods helpers
  Future<void> _internalAddNetwork(NetworkConfig network) async {
    try {
      _networks[network.chainId] = network;
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
    /* _txHandler = TransactionHandler(
      _web3client,
      _credentials!,
      int.parse(network.chainId.substring(2), radix: 16),
    ); */
  }

  void _updateState({String? address, bool? isConnected, String? chainId}) {
    _state = _state?.copyWith(
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
}

Future<SigningHandler?> getSigningHandler(
    {required BuildContext context,
    required AppColors colors,
    WalletState? state}) async {
  try {
    final access =
        await getAccess(context: context, colors: colors, state: state);
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
    final access =
        await getAccess(context: context, colors: colors, state: state);
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

Future<AccountAccess?> getAccess(
    {required BuildContext context,
    required AppColors colors,
    WalletState? state}) async {
  try {
    final password = await askPassword(context: context, colors: colors);
    final address = state?.address;
    if (address == null) {
      throw WalletException("Invalid State : address is null");
    }
    if (password.isEmpty) {
      throw WalletException("Invalid Password");
    }
    final cred = await EthInteractionManager()
        .getAccess(password: password, address: address);
    if (cred == null) {
      throw WalletException("Invalid Password");
    }

    return AccountAccess(address: address, cred: cred.cred, key: cred.key);
  } catch (e) {
    logError("Error ${e.toString()}");
    throw WalletException('Failed to create signing handler: $e');
  }
}
