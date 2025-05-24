import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:moonwallet/logger/logger.dart';
import 'package:moonwallet/notifiers/providers.dart';
import 'package:moonwallet/screens/dashboard/discover.dart';
import 'package:moonwallet/screens/dashboard/main.dart';
import 'package:moonwallet/screens/dashboard/swap.dart';
import 'package:moonwallet/screens/dashboard/trending.dart';
import 'package:moonwallet/service/vibration.dart';
import 'package:moonwallet/types/account_related_types.dart' as types;
import 'package:moonwallet/types/transaction.dart';
import 'package:moonwallet/types/types.dart' as types;
import 'package:moonwallet/utils/colors.dart';
import 'package:moonwallet/utils/themes.dart';
import 'package:moonwallet/widgets/func/security/show_passkey_prompt.dart';
import 'package:moonwallet/widgets/navBar.dart';
import 'package:moonwallet/widgets/func/transactions/history/show_transaction_details.dart';
import 'package:moonwallet/widgets/theme/theme_overlay.dart';

class PagesManagerView extends StatefulHookConsumerWidget {
  final types.AppColors colors;
  final types.PublicAccount? currentAccount;
  final types.Crypto? crypto;
  final Transaction? transaction;

  const PagesManagerView(
      {super.key,
      required this.colors,
      this.currentAccount,
      this.crypto,
      this.transaction});

  @override
  ConsumerState<PagesManagerView> createState() => _PagesManagerViewState();
}

class _PagesManagerViewState extends ConsumerState<PagesManagerView> {
  types.PublicAccount? currentAccount;
  types.Crypto? crypto;
  Transaction? transaction;
  bool isDarkMode = false;

  types.AppColors colors = types.AppColors.defaultTheme;
  Themes themes = Themes();
  String savedThemeName = "";
  Future<void> getSavedTheme() async {
    try {
      final manager = ColorsManager();
      final savedName = await manager.getThemeName();
      setState(() {
        savedThemeName = savedName ?? "";
      });
      final savedTheme = await manager.getDefaultTheme();
      setState(() {
        colors = savedTheme;
      });
    } catch (e) {
      logError(e.toString());
    }
  }

  List<Widget> _pages() {
    return [
      MainDashboardScreen(
        key: ValueKey<int>(0),
        colors: widget.colors,
      ),
      SwapScreen(
        key: ValueKey<int>(1),
      ),
      TrendingScreen(
        colors: colors,
        key: ValueKey<int>(2),
      ),
      DiscoverScreen(
        key: ValueKey<int>(3),
      ),
    ];
  }

  @override
  void initState() {
    super.initState();
    colors = widget.colors;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        if (widget.transaction != null &&
            widget.crypto != null &&
            widget.currentAccount != null) {
          setState(() {
            crypto = widget.crypto;
            transaction = widget.transaction;
            currentAccount = widget.currentAccount;
          });
          showTransactionDetails(
              isFrom: true,
              context: context,
              colors: colors,
              address: currentAccount?.addressByToken(crypto!) ?? "",
              tr: transaction!,
              token: crypto!);
        } else {
          logger.w("Transaction details data is missing");
        }
      } catch (e) {
        logError(e.toString());
      }
    });

    getSavedTheme();
  }

  @override
  Widget build(BuildContext context) {
    final pageIndexProviderNotifier =
        ref.watch(currentPageIndexNotifierProvider.notifier);

    final pageIndexProvider = ref.watch(currentPageIndexNotifierProvider);
    final currentIndexState = useState<int>(0);

    final uiConfig =
        useState<types.AppUIConfig>(types.AppUIConfig.defaultConfig);
    final appUIConfigAsync = ref.watch(appUIConfigProvider);
    final secureConfigAsync = ref.watch(appSecureConfigProvider);
    final hasRunCheck = useState<bool>(false);
    final sessionAsync = ref.watch(sessionProviderNotifier);
    final sessionNotifier = ref.watch(sessionProviderNotifier.notifier);

    useEffect(() {
      appUIConfigAsync.whenData((data) {
        uiConfig.value = data;
      });
      return null;
    }, [appUIConfigAsync]);

    useEffect(() {
      pageIndexProvider.whenData((index) {
        currentIndexState.value = index;
      });
      return null;
    }, [pageIndexProvider]);

    double fontSizeOf(double size) {
      return size * uiConfig.value.styles.fontSizeScaleFactor;
    }

    double iconSizeOf(double size) {
      return size * uiConfig.value.styles.iconSizeScaleFactor;
    }

    double roundedOf(double size) {
      return size * uiConfig.value.styles.radiusScaleFactor;
    }

    final pageManagerBody = ThemedOverlay(
      colors: colors,
      child: Scaffold(
        body: IndexedStack(
          index: currentIndexState.value,
          children: _pages(),
        ),
        bottomNavigationBar: BottomNav(
            roundedOf: roundedOf,
            fontSizeOf: fontSizeOf,
            iconSizeOf: iconSizeOf,
            onTap: (index) async {
              vibrate();
              await pageIndexProviderNotifier.savePageIndex(index);
            },
            currentIndex: currentIndexState.value,
            primaryColor: colors.primaryColor,
            textColor: colors.textColor,
            secondaryColor: colors.themeColor),
      ),
    );
    final loadingView = Material(
      color: colors.primaryColor,
      child: Center(child: CircularProgressIndicator(color: colors.themeColor)),
    );
    return sessionAsync.when(
      data: (data) {
        final secureData = secureConfigAsync.value;

        if (secureData?.lockAtStartup == true &&
                data == null &&
                !hasRunCheck.value ||
            data != null && data.hasExpired) {
          hasRunCheck.value = true;

          // Schedule the async logic to run after the frame
          WidgetsBinding.instance.addPostFrameCallback((_) async {
            final key = await showPassKeyPromptScreen(context, colors);
            if (key != null) {
              await sessionNotifier.startSession(key);
            }
          });

          return loadingView;
        } else if (secureData?.lockAtStartup == true &&
            data != null &&
            (data.endTime == 0 || data.hasExpired == false)) {
          return pageManagerBody;
        } else if (secureData?.lockAtStartup == false) {
          return pageManagerBody;
        }

        return loadingView;
      },
      loading: () {
        return loadingView;
      },
      error: (obj, trace) {
        return Center(
          child: Text("Error : $trace"),
        );
      },
    );
  }
}
