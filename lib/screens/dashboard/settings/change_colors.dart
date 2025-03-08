import 'package:delightful_toast/delight_toast.dart';
import 'package:delightful_toast/toast/components/toast_card.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:moonwallet/logger/logger.dart';
import 'package:moonwallet/main.dart';
import 'package:moonwallet/types/types.dart';
import 'package:moonwallet/utils/colors.dart';
import 'package:moonwallet/utils/themes.dart';

class ChangeThemeView extends StatefulWidget {
  const ChangeThemeView({super.key});

  @override
  State<ChangeThemeView> createState() => _ChangeThemeViewState();
}

class _ChangeThemeViewState extends State<ChangeThemeView> {
  AppColors colors = AppColors(
      primaryColor: Color(0XFF0D0D0D),
      themeColor: Colors.greenAccent,
      greenColor: Colors.greenAccent,
      secondaryColor: Color(0XFF121212),
      grayColor: Color(0XFF353535),
      textColor: Colors.white,
      redColor: Colors.pinkAccent);
  bool saved = false;
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

  Future<void> saveTheme({required String themeName}) async {
    try {
      final manager = ColorsManager();
      final save = await manager.saveDefaultTheme(theme: themeName);
      if (save) {
        saved = true;
        DelightToastBar(
          autoDismiss: true,
          builder: (context) => ToastCard(
            color: colors.secondaryColor,
            leading: Icon(
              color: colors.themeColor,
              Icons.check_circle,
              size: 28,
            ),
            title: Text(
              "Theme saved successfully",
              style: TextStyle(
                color: colors.textColor,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
          ),
        ).show(context);
      } else {
        throw Exception("An error occurred");
      }
    } catch (e) {
      logError(e.toString());
      DelightToastBar(
        autoDismiss: true,
        builder: (context) => ToastCard(
          color: colors.secondaryColor,
          leading: Icon(
            color: colors.redColor,
            Icons.error,
            size: 28,
          ),
          title: Text(
            "An error occurred",
            style: TextStyle(
              color: colors.textColor,
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
        ),
      ).show(context);
    }
  }

  @override
  void initState() {
    super.initState();
    getSavedTheme();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: colors.primaryColor,
        appBar: AppBar(
          surfaceTintColor: colors.grayColor,
          backgroundColor: colors.primaryColor,
          leading: IconButton(
              onPressed: () {
                saved
                    ? Navigator.pushNamed(context, Routes.pageManager)
                    : Navigator.pop(context);
              },
              icon: Icon(
                Icons.arrow_back,
                color: colors.textColor,
              )),
          title: Text(
            "Change color",
            style: GoogleFonts.roboto(color: colors.textColor),
          ),
        ),
        body: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2),
            itemCount: themes.allColors.length,
            itemBuilder: (context, index) {
              AppColors themeColors = themes.allColors.values.toList()[index];
              String themeName = themes.allColors.keys.toList()[index];

              return Container(
                  decoration: BoxDecoration(color: themeColors.themeColor),
                  child: Center(
                    child: Column(
                      spacing: 10,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          themeName,
                          style: GoogleFonts.roboto(color: Colors.blueAccent),
                        ),
                        TextButton(
                          onPressed: () {
                            setState(() {
                              colors = themes.allColors.values.toList()[index];
                              savedThemeName = themeName;
                            });
                            saveTheme(themeName: themeName);
                          },
                          style: ElevatedButton.styleFrom(
                              elevation: savedThemeName == themeName ? 10 : 0,
                              backgroundColor: colors.grayColor),
                          child: Text(
                            savedThemeName == themeName
                                ? "Selected"
                                : "Select theme",
                            style: GoogleFonts.roboto(
                                color: savedThemeName == themeName
                                    ? colors.themeColor
                                    : colors.textColor,
                                fontWeight: savedThemeName == themeName
                                    ? FontWeight.bold
                                    : FontWeight.normal),
                          ),
                        )
                      ],
                    ),
                  ));
            }));
  }
}
