import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:moonwallet/logger/logger.dart';
import 'package:moonwallet/screens/auth/home.dart';
import 'package:moonwallet/types/types.dart';
import 'package:share_plus/share_plus.dart';

final List<Map<String, dynamic>> browserModalOptions = [
  {"name": 'Refresh', "icon": LucideIcons.refreshCcw},
  {"name": 'Change Network', "icon": LucideIcons.globe},
  {"name": 'Full screen', "icon": FeatherIcons.maximize},
  {"name": 'Share', "icon": LucideIcons.share},
  {"name": 'Close', "icon": Icons.close_fullscreen_outlined},
];

final List<Map<String, dynamic>> fixedAppBarOptions = [
  {"name": "Sort by Value", "icon": LucideIcons.coins},
  {"name": "Sort by Name", "icon": LucideIcons.arrowDownAZ},
  {"name": "Only Native", "icon": LucideIcons.circleDollarSign},
  {"name": "Only Tokens", "icon": LucideIcons.blend},
  {"name": "Manage crypto", "icon": LucideIcons.settings2}
];

String formatTimeElapsed(int timestamp) {
  DateTime eventDate = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
  Duration difference = DateTime.now().difference(eventDate);
  if (difference.inSeconds < 60) {
    return "${difference.inSeconds} second${difference.inSeconds > 1 ? 's' : ''}";
  } else if (difference.inMinutes < 60) {
    return "${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''}";
  } else if (difference.inHours < 24) {
    return "${difference.inHours} hour${difference.inHours > 1 ? 's' : ''}";
  } else {
    return "${difference.inDays} day${difference.inDays > 1 ? 's' : ''}";
  }
}

void goToHome(BuildContext context) {
  Navigator.push(
      context, MaterialPageRoute(builder: (context) => HomeScreen()));
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

final List<Map<String, dynamic>> appBarButtonOptions = [
  {
    'icon': LucideIcons.pencil,
    'name': 'Edit name',
  },
  {
    'icon': LucideIcons.palette,
    'name': 'Edit Color',
  },
  {
    'icon': LucideIcons.copy,
    'name': 'Copy address',
  },
  {
    'icon': LucideIcons.key,
    'name': 'View private data',
  },
  {
    'icon': LucideIcons.trash,
    'name': 'Delete wallet',
    'color': Colors.pinkAccent
  },
];

/*Future<void> checkUserExistence () async {
    try {
      DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
      AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
      final deviceId = androidInfo.id;
      final model = androidInfo.model;
      final version = androidInfo.version;
      final fingerprint = androidInfo.fingerprint;
      final brand = androidInfo.brand;
      final regUrl = Uri.https("https://moon.opennode.tech/users/${deviceId}");
      final regResponse  = await http.get(regUrl);
      if (regResponse.statusCode == 200) {
        final responseJson = json.decode(regResponse.body);
        log("The response ${regResponse}");
      }

    } catch (e) {
      log("Error checking user existence: $e");
      
    }
  } */

final opBNbNetwork = Crypto(
  symbol: "OpBNB",
  decimals: 18,
  canDisplay: true,
  valueUsd: 0,
  explorers: ["https://opbnb.bscscan.com"],
  rpcUrls: ["https://opbnb-mainnet-rpc.bnbchain.org"],
  name: "opBNB",
  icon: "assets/b1.webp",
  chainId: 204,
  type: CryptoType.native,
  color: Color(0xFFFFA500), // Colors.orange.value
  cryptoId: "a6717b9f-a1a9-4b48-82ed-d01c7d251794",
);

final binanceNetwork = Crypto(
  decimals: 18,
  symbol: "BNB",

  canDisplay: true,
  valueUsd: 0,
  type: CryptoType.native,
  explorers: ["https://bscscan.com"],
  rpcUrls: ["https://bsc-dataseed.binance.org"],
  name: "BNB",
  icon: "assets/bnb.png",
  chainId: 56,
  color: Color(0xFFFFA500), // Colors.orange.value
  cryptoId: "a2e6b128-616b-4702-af5f-453c9231cea8",
);

final polygonNetwork = Crypto(
  decimals: 18,

  symbol: "POL",

  canDisplay: false,
  valueUsd: 0,
  type: CryptoType.native,
  explorers: ["https://polygonscan.com/"],
  rpcUrls: ["https://polygon-rpc.com"],
  name: "POL",
  icon: "assets/logos/pol.webp",
  chainId: 137,
  color: Color(0xFF7E57C2), // Colors.deepPurpleAccent.value
  cryptoId: "a2e6b376-7263-4502-af5f-453c92316262",
);

final ethereumNetwork = Crypto(
  decimals: 18,

  symbol: "ETH",

  canDisplay: false,
  valueUsd: 0,
  type: CryptoType.native,
  explorers: ["https://etherscan.io/"],
  rpcUrls: ["https://rpc.ankr.com/eth"],
  name: "ETH",
  icon: "assets/logos/eth.png",
  chainId: 1,
  color: Color(0xFF9E9E9E), // Colors.grey.value
  cryptoId: "42e6b336-616b-4502-af5f-453c9231ce09",
);

List<Crypto> popularCrypto = [
  binanceNetwork,
  opBNbNetwork,
  polygonNetwork,
  ethereumNetwork,
];

Future<void> share(
    {required String text,
    required String subject,
    VoidCallback? onError}) async {
  try {
    Share.share(text, subject: subject);
  } catch (e) {
    logError(e.toString());
    if (onError != null) {
      onError();
    }
  }
}

final List<DApp> dapps = [
  DApp(
    description: "Moon BNB is Global smart contract for global earnings",
    icon: "assets/image.png",
    name: 'Moon BNB',
    link: "https://moonbnb.pro",
    isNetworkImage: false,
  ),
  DApp(
    description: "Trade, earn, and own crypto on the all-in-one multichain DEX",
    icon:
        "https://tokens.pancakeswap.finance/images/0x0E09FaBB73Bd3Ade0a17ECC321fD13a19e81cE82.png",
    name: 'Pancakeswap',
    link: "https://pancakeswap.finance",
    isNetworkImage: true,
  ),
  DApp(
    description: "Buy, sell & trade Ethereum and other top tokens on Uniswap",
    icon:
        "https://raw.githubusercontent.com/trustwallet/assets/master/blockchains/ethereum/assets/0x1f9840a85d5aF5bf1D1762F925BDADdC4201F984/logo.png",
    name: 'Uniswap',
    link: "https://app.uniswap.org/swap",
    isNetworkImage: true,
  ),
];
