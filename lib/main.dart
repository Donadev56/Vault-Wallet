// ignore_for_file: deprecated_member_use

import 'dart:io';

import 'package:fast_cached_network_image/fast_cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_web3_webview/flutter_web3_webview.dart';
import 'package:moonwallet/logger/logger.dart';
import 'package:moonwallet/screens/dashboard/add_crypto.dart';
import 'package:moonwallet/screens/auth/add_private_key.dart';
import 'package:moonwallet/screens/auth/home.dart';
import 'package:moonwallet/screens/auth/pinManager.dart';
import 'package:moonwallet/screens/auth/private_key.dart';
import 'package:moonwallet/screens/dashboard/discover.dart';
import 'package:moonwallet/screens/dashboard/main.dart';
import 'package:moonwallet/screens/dashboard/page_manager.dart';
import 'package:moonwallet/screens/dashboard/wallet_actions/private/private_key_screen.dart';
import 'package:moonwallet/screens/dashboard/settings/change_colors.dart';
import 'package:moonwallet/screens/dashboard/settings/settings.dart';
import 'package:moonwallet/screens/dashboard/wallet_actions/add_w_o.dart';
import 'package:moonwallet/screens/dashboard/wallet_actions/add_mnemonic.dart';
import 'package:moonwallet/screens/dashboard/wallet_actions/add_private_key.dart';
import 'package:moonwallet/screens/dashboard/wallet_actions/create_private_key.dart';
import 'package:moonwallet/screens/test/test.dart';
import 'package:moonwallet/service/wallet_saver.dart';
import 'package:moonwallet/service/web3.dart';
import 'package:moonwallet/types/types.dart';
import 'package:moonwallet/utils/colors.dart';
import 'package:moonwallet/utils/prefs.dart';
import 'package:moonwallet/widgets/func/snackbar.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
    await InAppWebViewController.setWebContentsDebuggingEnabled(true);
  }

  await Web3Webview.initJs();
  WidgetsFlutterBinding.ensureInitialized();

  await FastCachedImageConfig.init(clearCacheAfter: const Duration(days: 15));
  Future.delayed(Duration(seconds: 2), () {
    runApp(ProviderScope(child: MyApp()));
  });
}

class Routes {
  static const String main = '/dashboard';
  static const String importWalletMain = '/importWalletMain';
  static const String createPrivateKeyMain = '/createPrivateKeyMain';
  static const String createAccountFromSed = '/createAccountFromSed';

  static const String discover = '/discover';
  static const String home = '/home';
  static const String addPrivateKey = '/addPrivateKey';
  static const String pinAuth = '/pinAuth';
  static const String addObservationWallet = '/addObservationWallet';
  static const String privateDataScreen = '/privateDataScreen';
  static const String settings = '/settings';

  static const String addCrypto = '/main/addCrypto';
  static const String pageManager = '/main/pageManager';
  static const String changeTheme = '/settings/changeColor';
  static const String test = '/tets';

  static const String privateKeyCreator = '/privatekeyCreator';
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  Color themeColor = Colors.greenAccent;
  AppColors colors = AppColors.defaultTheme;
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
      SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
        systemNavigationBarColor: colors.primaryColor,
        systemNavigationBarIconBrightness: Brightness.light,
      ));
    } catch (e) {
      logError(e.toString());
    }
  }

  Future<bool> hasAtLastOneAccount() async {
    try {
      final prefs = PublicDataManager();

      final hasAlreadyUpgraded =
          await prefs.getDataFromPrefs(key: "alreadyUpgraded");
      if (hasAlreadyUpgraded == null) {
        await upgradeDatabase();
      }
      final lastConnected = await prefs.getLastConnectedAddress();
      return lastConnected != null;
    } catch (e) {
      logError(e.toString());
      showCustomSnackBar(
          type: MessageType.error,
          context: context,
          message: e.toString(),
          colors: colors);

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
          final saved =
              await prefs.saveDataInPrefs(data: "true", key: "alreadyUpgraded");
          log("Data saved $saved");
        }
      }
    } catch (e) {
      logError(e.toString());
      showCustomSnackBar(
          type: MessageType.error,
          context: context,
          message: e.toString(),
          colors: colors);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
        future: hasAtLastOneAccount(),
        builder: (BuildContext ctx, AsyncSnapshot<bool> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Container(
              decoration: BoxDecoration(color: colors.primaryColor),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(10),
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                      color: colors.secondaryColor,
                      borderRadius: BorderRadius.circular(50)),
                ),
              ),
            );
          } else if (snapshot.hasData) {
            return MaterialApp(
                debugShowCheckedModeBanner: false,
                title: 'Moon Wallet',
                theme: ThemeData(
                  dialogTheme: DialogTheme(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                    backgroundColor: colors.primaryColor,
                  ),
                  textTheme: TextTheme(
                    displayLarge: TextStyle(
                      fontFamily: "roboto_reg",
                      fontSize: 57,
                      fontWeight: FontWeight.bold,
                      color: colors.textColor,
                      letterSpacing: -0.25,
                    ),
                    displayMedium: TextStyle(
                      fontFamily: "roboto_reg",
                      fontSize: 45,
                      fontWeight: FontWeight.bold,
                      color: colors.textColor,
                    ),
                    displaySmall: TextStyle(
                      fontFamily: "roboto_reg",
                      fontSize: 36,
                      fontWeight: FontWeight.w600,
                      color: colors.textColor,
                    ),
                    headlineLarge: TextStyle(
                      fontFamily: "roboto_reg",
                      fontSize: 32,
                      fontWeight: FontWeight.w600,
                      color: colors.textColor,
                    ),
                    headlineMedium: TextStyle(
                      fontFamily: "roboto_reg",
                      fontSize: 28,
                      fontWeight: FontWeight.w500,
                      color: colors.textColor,
                    ),
                    headlineSmall: TextStyle(
                      fontFamily: "roboto_reg",
                      fontSize: 24,
                      fontWeight: FontWeight.w500,
                      color: colors.textColor,
                    ),
                    titleLarge: TextStyle(
                      fontFamily: "roboto_reg",
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: colors.textColor,
                    ),
                    titleMedium: TextStyle(
                      fontFamily: "roboto_reg",
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: colors.textColor.withOpacity(0.9),
                    ),
                    titleSmall: TextStyle(
                      fontFamily: "roboto_reg",
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: colors.textColor.withOpacity(0.85),
                    ),
                    bodyLarge: TextStyle(
                      fontFamily: "roboto_reg",
                      fontSize: 16,
                      fontWeight: FontWeight.normal,
                      color: colors.textColor,
                    ),
                    bodyMedium: TextStyle(
                      fontFamily: "roboto_reg",
                      fontSize: 14,
                      fontWeight: FontWeight.normal,
                      color: colors.textColor.withOpacity(0.9),
                    ),
                    bodySmall: TextStyle(
                      fontFamily: "roboto_reg",
                      fontSize: 12,
                      fontWeight: FontWeight.normal,
                      color: colors.textColor.withOpacity(0.7),
                    ),
                    labelLarge: TextStyle(
                      fontFamily: "roboto_reg",
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: colors.textColor,
                    ),
                    labelMedium: TextStyle(
                      fontFamily: "roboto_reg",
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: colors.textColor.withOpacity(0.8),
                    ),
                    labelSmall: TextStyle(
                      fontFamily: "roboto_reg",
                      fontSize: 11,
                      fontWeight: FontWeight.w400,
                      color: colors.textColor.withOpacity(0.6),
                    ),
                  ),
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
                      foregroundColor: colors.textColor,
                    ),
                  ),
                  elevatedButtonTheme: ElevatedButtonThemeData(
                    style: ElevatedButton.styleFrom(
                      elevation: 0,
                      backgroundColor: colors.themeColor,
                      foregroundColor: colors.primaryColor,
                    ),
                  ),
                  outlinedButtonTheme: OutlinedButtonThemeData(
                    style: OutlinedButton.styleFrom(
                        foregroundColor: colors.themeColor,
                        side: BorderSide(color: colors.themeColor)),
                  ),
                ),
                initialRoute: snapshot.data! ? Routes.pageManager : Routes.home,
                routes: {
                  Routes.main: (context) => MainDashboardScreen(
                        colors: colors,
                      ),
                  Routes.discover: (context) => DiscoverScreen(
                        colors: colors,
                      ),
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
                  Routes.privateDataScreen: (context) => PrivateKeyScreen(
                        colors: colors,
                      ),
                  Routes.settings: (context) => SettingsPage(),
                  Routes.addCrypto: (context) => AddCryptoView(
                        colors: colors,
                      ),
                  Routes.pageManager: (context) => PagesManagerView(
                        colors: colors,
                      ),
                  Routes.changeTheme: (context) => ChangeThemeView(
                        colors: colors,
                      ),
                  Routes.test: (context) => LineChartSample12(),
                });
          } else {
            return Center(
                child: Text(
              "An error occurred.",
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: colors.redColor),
            ));
          }
        });
  }
}
