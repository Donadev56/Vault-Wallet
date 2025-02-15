import 'package:flutter/material.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:moonwallet/types/types.dart';
import 'package:fl_chart/fl_chart.dart';

final List<Map<String, dynamic>> options = [
  {"name": 'Refresh', "icon": LucideIcons.refreshCcw},
  {"name": 'Change Network', "icon": LucideIcons.globe},
  {"name": 'Full screen', "icon": FeatherIcons.maximize},
  {"name": 'Remove appBar', "icon": LucideIcons.appWindow},
  {"name": 'Share', "icon": LucideIcons.share},
];

final List<Network> networks = [
  Network(
      explorer: "https://opbnb.bscscan.com",
      rpc: "https://opbnb-mainnet-rpc.bnbchain.org",
      name: "opBNB",
      icon: "assets/b1.webp",
      binanceSymbol: "BNBUSDT",
      chainId: 204,
      color: Colors.orange),
  Network(
      explorer: "https://bscscan.com",
      rpc: "https://bsc-dataseed.binance.org",
      name: "BNB",
      binanceSymbol: "BNBUSDT",
      icon: "assets/bnb.png",
      chainId: 56,
      color: Colors.orange),
  Network(
      explorer: "https://bscscan.com",
      rpc: "https://bsc-dataseed.binance.org",
      name: "Moon Token",
      binanceSymbol: "",
      icon: "assets/image.png",
      chainId: 0,
      color: Colors.orange),
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


