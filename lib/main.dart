import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_web3_webview/flutter_web3_webview.dart';
import 'package:moonwallet/logger/logger.dart';
import 'package:moonwallet/screens/dashboard/auth/add_private_key.dart';
import 'package:moonwallet/screens/dashboard/auth/home.dart';
import 'package:moonwallet/screens/dashboard/auth/pinManager.dart';
import 'package:moonwallet/screens/dashboard/auth/private_key.dart';
import 'package:moonwallet/screens/dashboard/browser.dart';
import 'package:moonwallet/screens/dashboard/discover.dart';
import 'package:moonwallet/screens/dashboard/main.dart';
import 'package:moonwallet/screens/dashboard/view/wallet_overview.dart';
import 'package:moonwallet/screens/dashboard/wallet_actions/add_WO.dart';
import 'package:moonwallet/screens/dashboard/wallet_actions/add_mnemonic.dart';
import 'package:moonwallet/screens/dashboard/wallet_actions/add_private_key.dart';
import 'package:moonwallet/screens/dashboard/wallet_actions/private_key.dart';
import 'package:moonwallet/utils/prefs.dart';

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
  static const String createAccountFromSed = '/createAccountFromSed';

  static const String discover = '/discover';
  static const String browser = '/browser';
  static const String home = '/home';
  static const String addPrivateKey = '/addPrivateKey';
  static const String pinAuth = '/pinAuth';
  static const String walletOverview = '/walletOverview';
  static const String addObservationWallet = '/addObservationWallet';

  static const String privateKeyCreator = '/privatekeyCreator';
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  Future<bool> hasAtLastOneAccount() async {
    try {
      final prefs = PublicDataManager();
      final lastConnected = await prefs.getLastConnectedAddress();
      if (lastConnected != null) {
        return true;
      } else {
        return false;
      }
    } catch (e) {
      logError(e.toString());
      return false;
    }
  }

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        future: hasAtLastOneAccount(),
        builder: (BuildContext ctx, AsyncSnapshot result) {
          if (result.hasData) {
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
                    
                    colorScheme:
                        ColorScheme.fromSeed(seedColor: Colors.greenAccent ,     brightness: Brightness.dark,
 ),


                    useMaterial3: true,  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: Colors.white, // Couleur du texte
    ),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: Colors.white, 
      foregroundColor: Colors.black, 
    ),
  ),
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      foregroundColor: Colors.white,
    ),
  ),),

                initialRoute: result.data ? Routes.main : Routes.home,
                routes: {
                  Routes.main: (context) => MainDashboardScreen(),
                  Routes.discover: (context) => DiscoverScreen(),
                  Routes.browser: (context) => Web3BrowserScreen(),
                  Routes.home: (context) => HomeScreen(),
                  Routes.privateKeyCreator: (context) => CreatePrivateKey(),
                  Routes.addPrivateKey: (context) => AddPrivateKey(),
                  Routes.pinAuth: (context) => PinManagerScreen(),
                  Routes.importWalletMain: (context) => AddPrivateKeyInMain(),
                  Routes.createPrivateKeyMain: (context) =>
                      CreatePrivateKeyMain(),
                  Routes.walletOverview: (context) => WalletViewScreen(),
                  Routes.createAccountFromSed: (context) => AddMnemonicScreen(),
                  Routes.addObservationWallet: (context) =>
                      AddObservationWallet(),
                });
          } else {
            return Container(
              decoration: BoxDecoration(color: Color(0XFF0D0D0D)),
              child: Center(
                child: Container(
                    width: 160,
                    height: 160,
                    decoration: BoxDecoration(
                        color: Color(0XFF212121),
                        borderRadius: BorderRadius.circular(10)),
                    child: Center(
                      child: SizedBox(
                        width: 100,
                        height: 100,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                        ),
                      ),
                    )),
              ),
            );
          }
        });
  }
}
