import 'dart:io';

import 'package:fast_cached_network_image/fast_cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_web3_webview/flutter_web3_webview.dart';
import 'package:moonwallet/logger/logger.dart';
import 'package:moonwallet/screens/dashboard/add_crypto.dart';
import 'package:moonwallet/screens/dashboard/auth/add_private_key.dart';
import 'package:moonwallet/screens/dashboard/auth/home.dart';
import 'package:moonwallet/screens/dashboard/auth/pinManager.dart';
import 'package:moonwallet/screens/dashboard/auth/private_key.dart';
import 'package:moonwallet/screens/dashboard/browser.dart';
import 'package:moonwallet/screens/dashboard/discover.dart';
import 'package:moonwallet/screens/dashboard/main.dart';
import 'package:moonwallet/screens/dashboard/page_manager.dart';
import 'package:moonwallet/screens/dashboard/private/private_key_screen.dart';
import 'package:moonwallet/screens/dashboard/settings/change_colors.dart';
import 'package:moonwallet/screens/dashboard/settings/settings.dart';
import 'package:moonwallet/screens/dashboard/view/recieve.dart';
import 'package:moonwallet/screens/dashboard/view/send.dart';
import 'package:moonwallet/screens/dashboard/view/wallet_overview.dart';
import 'package:moonwallet/screens/dashboard/wallet_actions/add_WO.dart';
import 'package:moonwallet/screens/dashboard/wallet_actions/add_mnemonic.dart';
import 'package:moonwallet/screens/dashboard/wallet_actions/add_private_key.dart';
import 'package:moonwallet/screens/dashboard/wallet_actions/private_key.dart';
import 'package:moonwallet/service/wallet_saver.dart';
import 'package:moonwallet/service/web3.dart';
import 'package:moonwallet/types/types.dart';
import 'package:moonwallet/utils/colors.dart';
import 'package:moonwallet/utils/prefs.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
    await InAppWebViewController.setWebContentsDebuggingEnabled(true);
  }

  await Web3Webview.initJs();
  WidgetsFlutterBinding.ensureInitialized();

  await FastCachedImageConfig.init(clearCacheAfter: const Duration(days: 15));
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
  static const String addObservationWallet = '/addObservationWallet';
  static const String privateDataScreen = '/privateDataScreen';
  static const String receiveScreen = '/receiveScreen';
  static const String sendScreen = '/sendScreen';
  static const String settings = '/settings';
  static const String addCrypto = '/main/addCrypto';
  static const String pageManager = '/main/pageManager';
  static const String changeTheme = '/settings/changeColor';

  static const String privateKeyCreator = '/privatekeyCreator';
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  Color themeColor = Colors.greenAccent;
  AppColors colors = AppColors(
      primaryColor: Color(0XFF0D0D0D),
      themeColor: Colors.greenAccent,
      greenColor: Colors.greenAccent,
      secondaryColor: Color(0XFF121212),
      grayColor: Color(0XFF353535),
      textColor: Colors.white,
      redColor: Colors.pinkAccent);
  String savedThemeName = "";

  @override
  void initState() {
    super.initState();
    getSavedTheme();
  }

  Future<void> getSavedTheme() async {
    try {
      final manager = ColorsManager();
      final savedName = await manager.getThemeName();
      setState(() {
        savedThemeName = savedName ?? "";
      });
      final savedTheme = await manager.getDefaultTheme();
      setState(() {
        themeColor = savedTheme.themeColor;
        colors = savedTheme;
      });
    } catch (e) {
      logError(e.toString());
    }
  }

  Future<bool> hasAtLastOneAccount() async {
    try {
      final prefs = PublicDataManager();

      final hasAlreadyUpgraded =
          await prefs.getDataFromPrefs(key: "hasAlreadyUpgraded");
      if (hasAlreadyUpgraded == null) {
        await upgradeDatabase();
      }
      final lastConnected = await prefs.getLastConnectedAddress();
      return lastConnected != null;
    } catch (e) {
      logError(e.toString());
      return false;
    }
  }

  Future<void> upgradeDatabase() async {
    try {
      final lastDbManager = Web3Manager();
      final newDbManager = WalletSaver();
      final prefs = PublicDataManager();

      final savedPassword = await lastDbManager.getSavedPassword();
      if (savedPassword != null) {
        final savedData = await lastDbManager.getPublicData();
        final decryptedData =
            await lastDbManager.getDecryptedData(savedPassword);

        int savedTimes = 0;
        if (savedData != null) {
          final saved = await newDbManager.saveListPublicDataJson(savedData);
          if (saved) {
            savedTimes++;
          }
        }
        if (decryptedData != null) {
          final saved = await newDbManager.saveListPrivateKeyData(
              decryptedData, savedPassword);
          if (saved) {
            savedTimes++;
          }
        }
        if (savedTimes > 0) {
          final saved = await prefs.saveDataInPrefs(
              data: "true", key: "hasAlreadyUpgraded");
          log("Data saved $saved");
        }
      }
    } catch (e) {
      logError(e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
        future: hasAtLastOneAccount(),
        builder: (BuildContext ctx, AsyncSnapshot<bool> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Container(
              decoration: BoxDecoration(color: const Color(0XFF0D0D0D)),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(10),
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                      color: const Color(0XFF212121),
                      borderRadius: BorderRadius.circular(50)),
                ),
              ),
            );
          } else if (snapshot.hasData) {
            return MaterialApp(
                debugShowCheckedModeBanner: false,
                title: 'Moon Wallet',
                theme: ThemeData(
                  splashFactory: InkRipple.splashFactory,
                  primaryColor: colors.primaryColor,
                  dividerColor: colors.textColor,
                  pageTransitionsTheme: PageTransitionsTheme(
                    builders: {
                      for (var platform in TargetPlatform.values)
                        platform: CupertinoPageTransitionsBuilder(),
                    },
                  ),
                  colorScheme: ColorScheme.fromSeed(
                    seedColor: themeColor,
                    brightness: Brightness.dark,
                  ),
                  useMaterial3: true,
                  textButtonTheme: TextButtonThemeData(
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white,
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
                  ),
                ),
                initialRoute: snapshot.data! ? Routes.pageManager : Routes.home,
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
                  Routes.createAccountFromSed: (context) => AddMnemonicScreen(),
                  Routes.addObservationWallet: (context) =>
                      AddObservationWallet(),
                  Routes.privateDataScreen: (context) => PrivateKeyScreen(),
                  Routes.receiveScreen: (context) => ReceiveScreen(),
                  Routes.sendScreen: (context) => SendTransactionScreen(),
                  Routes.settings: (context) => SettingsPage(),
                  Routes.addCrypto: (context) => AddCryptoView(),
                  Routes.pageManager: (context) => PagesManagerView(),
                  Routes.changeTheme: (context) => ChangeThemeView(),
                });
          } else {
            return const Center(child: Text("An error occurred."));
          }
        });
  }
}
