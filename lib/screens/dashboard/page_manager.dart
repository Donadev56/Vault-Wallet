import 'package:flutter/material.dart';
import 'package:moonwallet/logger/logger.dart';
import 'package:moonwallet/screens/dashboard/discover.dart';
import 'package:moonwallet/screens/dashboard/main.dart';
import 'package:moonwallet/service/vibration.dart';
import 'package:moonwallet/utils/prefs.dart';
import 'package:moonwallet/widgets/navBar.dart';

class PagesManagerView extends StatefulWidget {
  const PagesManagerView({super.key});
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

  final List<Widget> _pages = [
    MainDashboardScreen(
      key: ValueKey<int>(0),
    ),
    DiscoverScreen(
      key: ValueKey<int>(1),
    ),
  ];

  @override
  void initState() {
    super.initState();
    getThemeMode();
    setState(() {
      currentIndex = widget.pageIndex;
    });
  }

  void setLightMode() {
    setState(() {
      isDarkMode = !isDarkMode;
      primaryColor = Color(0xFFE4E4E4);
      textColor = Color(0xFF0A0A0A);
      actionsColor = Color(0xFFCACACA);
      surfaceTintColor = Color(0xFFBABABA);
      secondaryColor = Color(0xFF960F51);
    });
  }

  void setDarkMode() {
    setState(() {
      isDarkMode = !isDarkMode;
      primaryColor = Color(0XFF1B1B1B);
      textColor = Color.fromARGB(255, 255, 255, 255);
      secondaryColor = Colors.greenAccent;
      actionsColor = Color(0XFF353535);
      surfaceTintColor = Color(0XFF454545);
    });
  }

  Future<void> getThemeMode() async {
    try {
      final savedMode =
          await publicDataManager.getDataFromPrefs(key: "isDarkMode");
      if (savedMode == null) {
        return;
      }
      if (savedMode == "true") {
        setDarkMode();
      } else {
        setLightMode();
      }
    } catch (e) {
      logError(e.toString());
    }
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
        children: _pages,
      ),
      bottomNavigationBar: BottomNav(
          onTap: (index) async {
            await vibrate();

            setState(() {
              currentIndex = index;
            });
          },
          currentIndex: currentIndex,
          primaryColor: primaryColor,
          textColor: textColor,
          secondaryColor: secondaryColor),
    );
  }
}
