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
import 'package:moonwallet/types/types.dart' as types;
import 'package:moonwallet/utils/colors.dart';
import 'package:moonwallet/utils/prefs.dart';
import 'package:moonwallet/utils/themes.dart';
import 'package:moonwallet/widgets/navBar.dart';
import 'package:moonwallet/widgets/view/show_transaction_details.dart';

class PagesManagerView extends StatefulHookConsumerWidget {
  final types.AppColors? colors;
  final types.PublicData? currentAccount;
  final types.Crypto? crypto;
  final types.TransactionDetails? transaction;

  const PagesManagerView(
      {super.key,
      this.colors,
      this.currentAccount,
      this.crypto,
      this.transaction});
  final pageIndex = 0;

  @override
  ConsumerState<PagesManagerView> createState() => _PagesManagerViewState();
}

class _PagesManagerViewState extends ConsumerState<PagesManagerView> {
  int currentIndex = 2;

  bool _isInitialized = false;
  types.PublicData? currentAccount;
  types.Crypto? crypto;
  types.TransactionDetails? transaction;
  final publicDataManager = PublicDataManager();
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
    if (widget.colors != null) {
      setState(() {
        colors = widget.colors!;
      });
    }
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
              address: currentAccount?.address ?? "",
              tr: transaction!,
              currentNetwork: crypto!);
        } else {
          logger.w("Transaction details data is missing");
        }
      } catch (e) {
        logError(e.toString());
      }
    });

    getSavedTheme();
    setState(() {
      currentIndex = widget.pageIndex;
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      final data = ModalRoute.of(context)?.settings.arguments;
      if (data != null && (data as Map<String, dynamic>)["pageIndex"] != null) {
        final index = data["pageIndex"];
        setState(() {
          currentIndex = index;
        });
      }
      _isInitialized = true;
    }
  }

  @override
  Widget build(BuildContext context) {
   final uiConfig = useState<types.AppUIConfig>(types.AppUIConfig.defaultConfig);
    final appUIConfigAsync = ref.watch(appUIConfigProvider);



     useEffect(() {
      appUIConfigAsync.whenData((data) {
        uiConfig.value = data;
      });
      return null;
    }, [appUIConfigAsync]);

     double fontSizeOf(double size) {
      return size * uiConfig.value.styles.fontSizeScaleFactor;
    }
 

     double iconSizeOf(double size) {
      return size * uiConfig.value.styles.iconSizeScaleFactor;
    }

    double roundedOf(double size) {
      return size * uiConfig.value.styles.radiusScaleFactor;
    }


    return Scaffold(
      body: IndexedStack(
        index: currentIndex,
        children: _pages(),
      ),
      bottomNavigationBar: BottomNav(
          roundedOf: roundedOf,
          fontSizeOf: fontSizeOf,
           iconSizeOf: iconSizeOf,
          onTap: (index) async {
            await vibrate();

            setState(() {
              currentIndex = index;
            });
          },
          currentIndex: currentIndex,
          primaryColor: colors.primaryColor,
          textColor: colors.textColor,
          secondaryColor: colors.themeColor),
    );
  }
}
