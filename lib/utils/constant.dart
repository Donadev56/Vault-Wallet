import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:moonwallet/types/types.dart';

final List<Map<String, dynamic>> options = [
  {"name": 'Refresh', "icon": LucideIcons.refreshCcw},
  {"name": 'Change Network', "icon": LucideIcons.globe},
  {"name": 'Full screen', "icon": FeatherIcons.maximize},
  {"name": 'Remove appBar', "icon": LucideIcons.appWindow},
  {"name": 'Share', "icon": LucideIcons.share},
];
final opBNbNetwork = Crypto(
  symbol: "OpBNB",
  apiBaseUrl: "api-opbnb.bscscan.com",
  apiKey: "6VUMQRRIHQEFKSEU1GH4WWNU1Q9ZYG2KRZ",
  canDisplay: true,
  valueUsd: 0,
  explorer: "https://opbnb.bscscan.com",
  rpc: "https://opbnb-mainnet-rpc.bnbchain.org",
  name: "opBNB",
  icon: "assets/b1.webp",
  binanceSymbol: "BNBUSDT",
  chainId: 204,
  type: CryptoType.network,
  color: Colors.orange,
  cryptoId: "a6717b9f-a1a9-4b48-82ed-d01c7d251794",
);
final binanceNetwork = Crypto(
    symbol: "BNB",
    apiBaseUrl: "api.bscscan.com",
    apiKey: "UKDSYXSDA8BJFT6QWP1IH161UQICTTJHHX",
    canDisplay: true,
    valueUsd: 0,
    type: CryptoType.network,
    explorer: "https://bscscan.com",
    rpc: "https://bsc-dataseed.binance.org",
    name: "BNB",
    binanceSymbol: "BNBUSDT",
    icon: "assets/bnb.png",
    chainId: 56,
    color: Colors.orange,
    cryptoId: "a2e6b128-616b-4702-af5f-453c9231cea8");

final polygonNetwork = Crypto(
    symbol: "POL",
    apiBaseUrl: "api.polygonscan.com",
    apiKey: "BUVQC2CWQXGZTPARK1215KQ7Y6CQ6A47QJ",
    canDisplay: false,
    valueUsd: 0,
    type: CryptoType.network,
    explorer: "https://polygonscan.com/",
    rpc: "https://polygon-rpc.com",
    name: "POL",
    binanceSymbol: "POLUSDT",
    icon: "assets/logos/pol.webp",
    chainId: 137,
    color: Colors.deepPurpleAccent,
    cryptoId: "a2e6b376-7263-4502-af5f-453c92316262");

final ethereumNetwork = Crypto(
    symbol: "ETH",
    apiBaseUrl: "api.etherscan.io",
    apiKey: "5IABWY62PY3RMGR9WT6547X7VW6CQIG1CN",
    canDisplay: false,
    valueUsd: 0,
    type: CryptoType.network,
    explorer: "https://etherscan.io/",
    rpc: "https://rpc.ankr.com/eth",
    name: "ETH",
    binanceSymbol: "ETHUSDT",
    icon: "assets/logos/eth.png",
    chainId: 1,
    color: Colors.grey,
    cryptoId: "42e6b336-616b-4502-af5f-453c9231ce09");

final List<Crypto> cryptos = [
  opBNbNetwork,
  binanceNetwork,
  polygonNetwork,
  ethereumNetwork,
  Crypto(
      symbol: "USDT",
      canDisplay: true,
      network: opBNbNetwork,
      valueUsd: 0,
      contractAddress: "0x9e5AAC1Ba1a2e6aEd6b32689DFcF62A509Ca96f3",
      type: CryptoType.token,
      explorer: opBNbNetwork.explorer,
      rpc: opBNbNetwork.rpc,
      name: "USDT",
      binanceSymbol: "USDCUSDT",
      icon: "assets/logos/usdt2.png",
      chainId: 0,
      color: Colors.greenAccent,
      cryptoId: "405909bc-9776-4296-8ef7-09ab8ce3741e"),
  Crypto(
      symbol: "BTCB",
      canDisplay: true,
      network: binanceNetwork,
      valueUsd: 0,
      contractAddress: "0x7130d2A12B9BCbFAe4f2634d864A1Ee1Ce3Ead9c",
      type: CryptoType.token,
      explorer: binanceNetwork.explorer,
      rpc: binanceNetwork.rpc,
      name: "BITCOIN BINANCE",
      binanceSymbol: "BTCUSDT",
      icon: "assets/logos/bitcoin.png",
      chainId: 0,
      color: Colors.orange,
      cryptoId: "76a6dd5a-31b7-4033-b192-b44ca8d34d48"),
  Crypto(
    symbol: "MOON",
    canDisplay: true,
    network: opBNbNetwork,
    valueUsd: 0,
    type: CryptoType.token,
    explorer: opBNbNetwork.explorer,
    rpc: opBNbNetwork.rpc,
    name: "Moon Token",
    binanceSymbol: "",
    icon: "assets/image.png",
    chainId: 0,
    cryptoId: "08881504-566f-41d8-8372-186244f6363e",
    color: Colors.orange,
  ),
  Crypto(
    symbol: "USDT",
    contractAddress: "0xc2132D05D31c914a87C6611C10748AEb04B58e8F",
    canDisplay: false,
    network: polygonNetwork,
    valueUsd: 0,
    type: CryptoType.token,
    explorer: polygonNetwork.explorer,
    rpc: polygonNetwork.rpc,
    name: "USDT",
    binanceSymbol: "USDCUSDT",
    icon: "assets/logos/usdt2.png",
    chainId: 0,
    cryptoId: "01991504-000f-41d8-8372-186244f63633",
    color: Colors.greenAccent,
  ),
  Crypto(
    symbol: "USDT",
    contractAddress: "0xdAC17F958D2ee523a2206206994597C13D831ec7",
    canDisplay: false,
    network: ethereumNetwork,
    valueUsd: 0,
    type: CryptoType.token,
    explorer: ethereumNetwork.explorer,
    rpc: ethereumNetwork.rpc,
    name: "USDT",
    binanceSymbol: "USDCUSDT",
    icon: "assets/logos/usdt2.png",
    chainId: 0,
    cryptoId: "00777664-566f-41d8-8372-186554f6363e",
    color: Colors.greenAccent,
  ),
  Crypto(
    symbol: "USDT",
    contractAddress: "0x55d398326f99059ff775485246999027b3197955",
    canDisplay: true,
    network: binanceNetwork,
    valueUsd: 0,
    type: CryptoType.token,
    explorer: binanceNetwork.explorer,
    rpc: binanceNetwork.rpc,
    name: "USDT",
    binanceSymbol: "USDCUSDT",
    icon: "assets/logos/usdt2.png",
    chainId: 0,
    cryptoId: "88996664-8653-41d8-8372-186244f6FZ52",
    color: Colors.orange,
  ),
];

String formatTimeElapsed(int timestamp) {
  DateTime eventDate = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
  Duration difference = DateTime.now().difference(eventDate);

  if (difference.inMinutes < 60) {
    return "${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''}";
  } else if (difference.inHours < 24) {
    return "${difference.inHours} hour${difference.inHours > 1 ? 's' : ''}";
  } else {
    return "${difference.inDays} day${difference.inDays > 1 ? 's' : ''}";
  }
}

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
