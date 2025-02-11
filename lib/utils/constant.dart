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
      name: "opBNB",
      icon: "assets/b1.webp",
      chainId: 204,
      color: Colors.orange),
  Network(
      name: "BNB", icon: "assets/bnb.png", chainId: 56, color: Colors.orange),
];
