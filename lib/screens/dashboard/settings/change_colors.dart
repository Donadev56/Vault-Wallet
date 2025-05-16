import 'package:flutter/material.dart';
import 'package:moonwallet/logger/logger.dart';
import 'package:moonwallet/routes.dart';
import 'package:moonwallet/types/types.dart';
import 'package:moonwallet/utils/colors.dart';
import 'package:moonwallet/utils/themes.dart';
import 'package:moonwallet/widgets/dialogs/show_custom_snackbar.dart';

class ChangeThemeView extends StatefulWidget {
  final AppColors? colors;

  const ChangeThemeView({super.key, this.colors});

  @override
  State<ChangeThemeView> createState() => _ChangeThemeViewState();
}

class _ChangeThemeViewState extends State<ChangeThemeView> {
  AppColors colors = AppColors.defaultTheme;

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
      } else {
        throw Exception("An error occurred");
      }
    } catch (e) {
      logError(e.toString());
      notifyError(e.toString(), context);
    }
  }

  @override
  void initState() {
    super.initState();
    getSavedTheme();
    if (widget.colors != null) {
      setState(() {
        colors = widget.colors!;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
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
                  Icons.chevron_left,
                  color: colors.textColor,
                )),
            centerTitle: true,
            title: Text(
              "Change Theme",
              style: textTheme.bodyMedium
                  ?.copyWith(fontSize: 18, fontWeight: FontWeight.w400),
            )),
        body: GlowingOverscrollIndicator(
          axisDirection: AxisDirection.down,
          color: colors.themeColor,
          child: GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  mainAxisSpacing: 5, crossAxisSpacing: 5, crossAxisCount: 3),
              itemCount: themes.allColors.length,
              itemBuilder: (context, index) {
                String themeName = themes.allColors.keys.toList()[index];
                final value = themes.allColors.values.toList()[index];

                return Padding(
                    padding: const EdgeInsets.all(5),
                    child: ClipRRect(
                        borderRadius: BorderRadius.circular(15),
                        child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment(0.8, 1),
                                colors: <Color>[
                                  value.themeColor,
                                  value.primaryColor
                                ],
                                //  tileMode: TileMode.mirror,
                              ),
                            ),
                            child: ClipRRect(
                                child: ColoredBox(
                                    color: Colors.black87.withOpacity(0.5),
                                    child: Center(
                                      child: Column(
                                        spacing: 10,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          TextButton(
                                            onPressed: () {
                                              setState(() {
                                                colors = themes.allColors.values
                                                    .toList()[index];
                                                savedThemeName = themeName;
                                              });
                                              saveTheme(themeName: themeName);
                                            },
                                            style: ElevatedButton.styleFrom(
                                                visualDensity: VisualDensity(
                                                    horizontal: 0,
                                                    vertical: -4),
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        vertical: 2,
                                                        horizontal: 1),
                                                elevation:
                                                    savedThemeName == themeName
                                                        ? 10
                                                        : 0,
                                                backgroundColor:
                                                    savedThemeName == themeName
                                                        ? colors.themeColor
                                                        : Colors.white),
                                            child: Text(
                                              savedThemeName == themeName
                                                  ? "Selected"
                                                  : "Select",
                                              style: textTheme.bodyMedium
                                                  ?.copyWith(
                                                      fontSize: 10,
                                                      color: Colors.black87,
                                                      fontWeight:
                                                          savedThemeName ==
                                                                  themeName
                                                              ? FontWeight.bold
                                                              : FontWeight
                                                                  .normal),
                                            ),
                                          )
                                        ],
                                      ),
                                    ))))));
              }),
        ));
  }
}
