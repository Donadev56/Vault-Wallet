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

final List<Network> networks = [
  Network(
      rpc: "https://opbnb-mainnet-rpc.bnbchain.org",
      name: "opBNB",
      icon: "assets/b1.webp",
      binanceSymbol: "BNBUSDT",
      chainId: 204,
      color: Colors.orange),
  Network(
      rpc: "https://bsc-dataseed.binance.org",
      name: "BNB",
      binanceSymbol: "BNBUSDT",
      icon: "assets/bnb.png",
      chainId: 56,
      color: Colors.orange),
];
