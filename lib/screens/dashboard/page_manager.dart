import 'package:flutter/material.dart';
import 'package:moonwallet/logger/logger.dart';
import 'package:moonwallet/screens/dashboard/discover.dart';
import 'package:moonwallet/screens/dashboard/main.dart';
import 'package:moonwallet/service/vibration.dart';
import 'package:moonwallet/types/types.dart';
import 'package:moonwallet/utils/colors.dart';
import 'package:moonwallet/utils/prefs.dart';
import 'package:moonwallet/utils/themes.dart';
import 'package:moonwallet/widgets/navBar.dart';

class PagesManagerView extends StatefulWidget {
  final AppColors? colors;
  const PagesManagerView({super.key, this.colors});
  final pageIndex = 0;

  @override
  State<PagesManagerView> createState() => _PagesManagerViewState();
}

class _PagesManagerViewState extends State<PagesManagerView> {
  int currentIndex = 2;
  Color primaryColor = Color(0XFF1B1B1B);
  Color textColor = Color(0xFFF5F5F5);
  Color secondaryColor = Colors.greenAccent;
  Color actionsColor = Color(0XFF353535);
  Color surfaceTintColor = Color(0XFF454545);
  bool _isInitialized = false;
  final publicDataManager = PublicDataManager();
  bool isDarkMode = false;

  AppColors colors = AppColors.defaultTheme;
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
      DiscoverScreen(
        key: ValueKey<int>(1),
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
    return Scaffold(
      body: IndexedStack(
        index: currentIndex,
        children: _pages(),
      ),
      bottomNavigationBar: BottomNav(
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
