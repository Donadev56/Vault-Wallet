// ignore_for_file: deprecated_member_use

import 'dart:async';
import 'dart:io';

import 'package:fast_cached_network_image/fast_cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_web3_webview/flutter_web3_webview.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:moonwallet/custom_textTheme.dart';
import 'package:moonwallet/logger/logger.dart';
import 'package:moonwallet/notifiers/accounts_notifier.dart';
import 'package:moonwallet/notifiers/providers.dart';
import 'package:moonwallet/routes.dart';
import 'package:moonwallet/screens/dashboard/add_crypto.dart';
import 'package:moonwallet/screens/auth/home.dart';
import 'package:moonwallet/screens/dashboard/discover.dart';
import 'package:moonwallet/screens/dashboard/main.dart';
import 'package:moonwallet/screens/dashboard/page_manager.dart';
import 'package:moonwallet/screens/dashboard/settings/change_colors.dart';
import 'package:moonwallet/screens/dashboard/settings/settings.dart';
import 'package:moonwallet/screens/dashboard/wallet_actions/add_mnemonic.dart';
import 'package:moonwallet/screens/dashboard/wallet_actions/create_mnemonic_key.dart';
import 'package:moonwallet/types/types.dart';
import 'package:moonwallet/utils/colors.dart';
import 'package:moonwallet/widgets/dialogs/show_custom_snackbar.dart';

void main() {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    FlutterError.onError = (FlutterErrorDetails details) {
      FlutterError.presentError(details);
      logError("FlutterError: ${details.exceptionAsString()}");
    };

    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
      await InAppWebViewController.setWebContentsDebuggingEnabled(true);
    }

    await Web3Webview.initJs();
    await FastCachedImageConfig.init(clearCacheAfter: const Duration(days: 15));

    runApp(ProviderScope(child: MyApp()));
  }, (Object error, StackTrace stack) {
    logError("Caught by runZonedGuarded: $error\n$stack");
  });
}

class MyApp extends StatefulHookConsumerWidget {
  const MyApp({super.key});

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> with WidgetsBindingObserver {
  Color themeColor = Colors.greenAccent;
  AppColors colors = AppColors.defaultTheme;
  String savedThemeName = "";

  @override
  void initState() {
    super.initState();
    getSavedTheme();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    super.dispose();
    WidgetsBinding.instance.removeObserver(this);
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
      final accounts = await AccountsNotifier().getPublicAccount();
      return accounts.isNotEmpty;
    } catch (e) {
      logError(e.toString());
      notifyError(e.toString(), context);

      return false;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      ref.read(sessionProviderNotifier.notifier).endSession();
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
                title: 'Vault Wallet',
                theme: ThemeData(
                  dialogTheme: DialogTheme(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                    backgroundColor: colors.primaryColor,
                  ),
                  textTheme: customTextTheme(colors),
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
                  Routes.createPrivateKeyMain: (context) =>
                      CreateMnemonicMain(),
                  Routes.createAccountFromSed: (context) => AddMnemonicScreen(),
                  Routes.settings: (context) => SettingsPage(
                        colors: colors,
                      ),
                  Routes.addCrypto: (context) => AddCryptoView(
                        colors: colors,
                      ),
                  Routes.pageManager: (context) => PagesManagerView(
                        colors: colors,
                      ),
                  Routes.changeTheme: (context) => ChangeThemeView(
                        colors: colors,
                      ),
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
