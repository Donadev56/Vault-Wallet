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
  isNetworkIcon: false,
  symbol: "OpBNB",
  apiBaseUrl: "api-opbnb.bscscan.com/api",
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
    isNetworkIcon: false,
    symbol: "BNB",
    apiBaseUrl: "api.bscscan.com/api",
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
    isNetworkIcon: false,
    symbol: "POL",
    apiBaseUrl: "api.polygonscan.com/api",
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
    isNetworkIcon: false,
    symbol: "ETH",
    apiBaseUrl: "api.etherscan.io/api",
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

final moonbeamNetwork = Crypto(
    icon: "https://cryptologos.cc/logos/moonbeam-glmr-logo.png?v=040",
    apiKey: "FBDH47RQPNYSV29NGND73D8SJ2N1USCDWK",
    isNetworkIcon: false,
    symbol: "GLMR",
    apiBaseUrl: "api-moonbeam.moonscan.io/api", // API fictive pour l'exemple
    canDisplay: false,
    valueUsd: 0,
    type: CryptoType.network,
    explorer: "https://moonbeam.moonscan.io/",
    rpc: "https://rpc.api.moonbeam.network",
    name: "Moonbeam",
    binanceSymbol: "GLMRUSDT",
    chainId: 1284,
    color: Colors.amber,
    cryptoId: "42e6b336-616b-4502-af5f-453792319e09");
final celoNetwork = Crypto(
    icon: "https://cryptologos.cc/logos/celo-celo-logo.png?v=040",
    apiKey: "HQ3SHXHI1B2W6HCW8F82FGTMEYVT8MS1H4",
    isNetworkIcon: true,
    symbol: "CELO",
    apiBaseUrl: "api.celoscan.io/api", // API fictive pour l'exemple
    canDisplay: false,
    valueUsd: 0,
    type: CryptoType.network,
    explorer: "https://explorer.celo.org/",
    rpc: "https://forno.celo.org/",
    name: "Celo",
    binanceSymbol: "CELOUSDT",
    chainId: 42220,
    color: Colors.yellow,
    cryptoId: "42e88336-616b-4502-af5f-453799919e09");
final gnosisNetwork = Crypto(
    icon:
        "https://altcoinsbox.com/wp-content/uploads/2023/03/gnosis-logo-600x600.webp",
    apiKey: "Q39BRD8Y43D2XIJHCNTGNBRURQ8A5M4CBQ",
    isNetworkIcon: true,
    symbol: "xDAI",
    apiBaseUrl: "api.gnosisscan.io/api", // API fictive pour l'exemple
    canDisplay: false,
    valueUsd: 0,
    type: CryptoType.network,
    explorer: "https://blockscout.com/xdai/mainnet/",
    rpc: "https://rpc.gnosischain.com/",
    name: "Gnosis Chain",
    binanceSymbol: "USDCUSDT",
    chainId: 100,
    color: Colors.green,
    cryptoId: "42e88336-7636-4502-af5f-499799919e09");

final optimismNetwork = Crypto(
    icon: "https://cryptologos.cc/logos/optimism-ethereum-op-logo.png?v=040",
    apiKey: "GC1XFZI399Z713ZHAA5B6GF9C5YQJP2WF6",
    isNetworkIcon: true,
    symbol: "ETH",
    apiBaseUrl: "api-optimistic.etherscan.io/api",
    canDisplay: false,
    valueUsd: 0,
    type: CryptoType.network,
    explorer: "https://optimistic.etherscan.io/",
    rpc: "https://mainnet.optimism.io",
    name: "Optimism",
    binanceSymbol: "ETHUSDT",
    chainId: 10,
    color: Colors.pinkAccent,
    cryptoId: "4828376-7636-4502-af5f-49339919e09");

final arbitrumNetwork = Crypto(
    icon: "https://cryptologos.cc/logos/arbitrum-arb-logo.png?v=040",
    apiKey: "5ZFPH1J554X4X7TUFHVTZ4CRYXYNFBTK9F",
    isNetworkIcon: true,
    symbol: "ETH",
    apiBaseUrl: "api.arbiscan.io/api",
    canDisplay: false,
    valueUsd: 0,
    type: CryptoType.network,
    explorer: "https://arbiscan.io/",
    rpc: "https://arb1.arbitrum.io/rpc",
    name: "Arbitrum One",
    binanceSymbol: "ETHUSDT",
    chainId: 42161,
    color: Colors.orange,
    cryptoId: "26363736-7636-4502-af5f-49339919e09");

final avalancheNetwork = Crypto(
  symbol: "AVAX",
  apiBaseUrl: "api.routescan.io/v2/network/mainnet/evm/",
  canDisplay: false,
  valueUsd: 0,
  type: CryptoType.network,
  explorer: "https://snowtrace.io/",
  rpc: "https://api.avax.network/ext/bc/C/rpc",
  name: "Avalanche C-Chain",
  binanceSymbol: "AVAXUSDT",
  apiKey: "YourApiKeyToken",
  chainId: 43114,
  color: Colors.red,
  cryptoId: "33377736-7636-4502-af5f-49339919e09",
  isNetworkIcon: true,
  icon: "https://cryptologos.cc/logos/avalanche-avax-logo.png?v=040",
);

final List<Crypto> cryptos = [
  opBNbNetwork,
  binanceNetwork,
  polygonNetwork,
  ethereumNetwork,
  moonbeamNetwork,
  avalancheNetwork,
  optimismNetwork,
  gnosisNetwork,
  celoNetwork,
  arbitrumNetwork,
  Crypto(
      isNetworkIcon: false,
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
      isNetworkIcon: false,
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
      isNetworkIcon: false,
      symbol: "BTCB",
      canDisplay: true,
      network: opBNbNetwork,
      valueUsd: 0,
      contractAddress: "0x7c6b91D9Be155A6Db01f749217d76fF02A7227F2",
      type: CryptoType.token,
      explorer: opBNbNetwork.explorer,
      rpc: opBNbNetwork.rpc,
      name: "BITCOIN BINANCE",
      binanceSymbol: "BTCUSDT",
      icon: "assets/logos/bitcoin.png",
      chainId: 0,
      color: Colors.orange,
      cryptoId: "76a6btcba-31b7-4033-b192-b44cauni34d48"),
  Crypto(
    isNetworkIcon: false,
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
    isNetworkIcon: false,
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
    isNetworkIcon: false,
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
    isNetworkIcon: false,
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

List<Color> colorList = [
  Colors.amberAccent,
  Colors.lightBlueAccent,
  Colors.greenAccent,
  Colors.amber,
  Colors.pinkAccent,
  Colors.deepPurple,
  Colors.lightGreenAccent,
  Colors.deepOrange,
  Colors.deepOrangeAccent,
  Colors.white,
  Colors.grey,

  // Primary Colors + Accents
  Colors.red,
  Colors.redAccent,
  Colors.pink,
  Colors.purple,
  Colors.purpleAccent,
  Colors.deepPurpleAccent,
  Colors.indigo,
  Colors.indigoAccent,
  Colors.blue,
  Colors.blueAccent,
  Colors.lightBlue,
  Colors.cyan,
  Colors.cyanAccent,
  Colors.teal,
  Colors.tealAccent,
  Colors.green,
  Colors.lightGreen,
  Colors.lime,
  Colors.limeAccent,
  Colors.yellow,
  Colors.yellowAccent,
  Colors.orange,
  Colors.orangeAccent,
  Colors.brown,
  Colors.blueGrey,

  Colors.red.shade100,
  Colors.red.shade700,
  Colors.blue.shade200,
  Colors.blue.shade800,
  Colors.green.shade300,
  Colors.green.shade600,
  Colors.amber.shade200,
  Colors.amber.shade800,
  Colors.deepPurple.shade100,
  Colors.deepPurple.shade400,
  Colors.orange.shade300,
  Colors.orange.shade700,
  Colors.teal.shade200,
  Colors.teal.shade500,

  Colors.black,
  Colors.purple.shade300,
  Colors.cyan.shade100,
  Colors.yellow.shade600,
  Colors.transparent
];
