import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_web3_webview/flutter_web3_webview.dart';
import 'package:moonwallet/screens/dashboard/auth/add_private_key.dart';
import 'package:moonwallet/screens/dashboard/auth/home.dart';
import 'package:moonwallet/screens/dashboard/auth/pinManager.dart';
import 'package:moonwallet/screens/dashboard/auth/private_key.dart';
import 'package:moonwallet/screens/dashboard/browser.dart';
import 'package:moonwallet/screens/dashboard/discover.dart';
import 'package:moonwallet/screens/dashboard/main.dart';
import 'package:moonwallet/screens/dashboard/wallet_actions/add_private_key.dart';
import 'package:moonwallet/screens/dashboard/wallet_actions/private_key.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
    await InAppWebViewController.setWebContentsDebuggingEnabled(true);
  }

  await Web3Webview.initJs();
  WidgetsFlutterBinding.ensureInitialized();

  runApp(const MyApp());
}

class Routes {
  static const String main = '/dashboard';
  static const String importWalletMain = '/importWalletMain';
  static const String createPrivateKeyMain = '/createPrivateKeyMain';

  static const String discover = '/discover';
  static const String browser = '/browser';
  static const String home = '/home';
  static const String addPrivateKey = '/addPrivateKey';
  static const String pinAuth = '/pinAuth';

  static const String privateKeyCreator = '/privatekeyCreator';
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Moon Wallet',
        theme: ThemeData(
            pageTransitionsTheme: PageTransitionsTheme(
              builders: {
                for (var platform in TargetPlatform.values)
                  platform: CupertinoPageTransitionsBuilder(),
              },
            ),
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.greenAccent),
            useMaterial3: true),
        initialRoute: Routes.main,
        routes: {
          Routes.main: (context) => MainDashboardScreen(),
          Routes.discover: (context) => DiscoverScreen(),
          Routes.browser: (context) => Web3BrowserScreen(),
          Routes.home: (context) => HomeScreen(),
          Routes.privateKeyCreator: (context) => CreatePrivateKey(),
          Routes.addPrivateKey: (context) => AddPrivateKey(),
          Routes.pinAuth: (context) => PinManagerScreen(),
          Routes.importWalletMain: (context) => AddPrivateKeyInMain(),
          Routes.createPrivateKeyMain: (context) => CreatePrivateKeyMain(),
        });
  }
}
