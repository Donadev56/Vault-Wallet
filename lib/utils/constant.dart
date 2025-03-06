import 'dart:typed_data';

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

final List<Crypto> networks = [
  Crypto(
      explorer: "https://opbnb.bscscan.com",
      rpc: "https://opbnb-mainnet-rpc.bnbchain.org",
      name: "opBNB",
      icon: "assets/b1.webp",
      binanceSymbol: "BNBUSDT",
      chainId: 204,
      type: CryptoType.network,
      color: Colors.orange),
  Crypto(
     type: CryptoType.network,
      explorer: "https://bscscan.com",
      rpc: "https://bsc-dataseed.binance.org",
      name: "BNB",
      binanceSymbol: "BNBUSDT",
      icon: "assets/bnb.png",
      chainId: 56,
      color: Colors.orange),
  Crypto(
    type: CryptoType.token,
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
