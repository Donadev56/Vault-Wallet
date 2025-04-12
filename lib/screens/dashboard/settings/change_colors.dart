import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:moonwallet/logger/logger.dart';
import 'package:moonwallet/main.dart';
import 'package:moonwallet/types/types.dart';
import 'package:moonwallet/utils/colors.dart';
import 'package:moonwallet/utils/themes.dart';
import 'package:moonwallet/widgets/func/snackbar.dart';
import 'package:photo_view/photo_view.dart';

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

        showCustomSnackBar(
            context: context,
            message: "Theme saved successfully",
            colors: colors,
            type: MessageType.success,
            iconColor: colors.greenColor,
            icon: Icons.check);
      } else {
        throw Exception("An error occurred");
      }
    } catch (e) {
      logError(e.toString());
      showCustomSnackBar(
          context: context,
          message: "${e.toString()}",
          colors: colors,
          type: MessageType.error);
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
                Icons.arrow_back,
                color: colors.textColor,
              )),
          title: Text(
            "Change color",
            style: textTheme.headlineMedium
                ?.copyWith(color: colors.textColor, fontSize: 20),
          ),
        ),
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
                                          ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(40),
                                            child: TextButton.icon(
                                              icon: Icon(Icons.remove_red_eye,
                                                  color: colors.themeColor),
                                              onPressed: () {
                                                showCupertinoModalBottomSheet(
                                                    backgroundColor:
                                                        Colors.transparent,
                                                    shape:
                                                        RoundedRectangleBorder(
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        40)),
                                                    context: context,
                                                    builder: (ctx) {
                                                      return StatefulBuilder(
                                                          builder: (ctx, st) {
                                                        return ClipRRect(
                                                            child: Dialog
                                                                .fullscreen(
                                                          child: Scaffold(
                                                            backgroundColor:
                                                                colors
                                                                    .primaryColor,
                                                            appBar: AppBar(
                                                              backgroundColor:
                                                                  colors
                                                                      .primaryColor,
                                                              title: Text(
                                                                themeName,
                                                                style: textTheme
                                                                    .bodyMedium
                                                                    ?.copyWith(
                                                                        color: colors
                                                                            .textColor),
                                                              ),
                                                              actions: [
                                                                IconButton(
                                                                  icon: Icon(
                                                                      Icons
                                                                          .check,
                                                                      color: colors
                                                                          .themeColor),
                                                                  onPressed:
                                                                      () {
                                                                    setState(
                                                                        () {
                                                                      colors = themes
                                                                          .allColors
                                                                          .values
                                                                          .toList()[index];
                                                                      savedThemeName =
                                                                          themeName;
                                                                    });
                                                                    saveTheme(
                                                                        themeName:
                                                                            themeName);
                                                                    st(() {});
                                                                  },
                                                                ),
                                                              ],
                                                            ),
                                                            body: Center(
                                                                child:
                                                                    PhotoView(
                                                              minScale:
                                                                  PhotoViewComputedScale
                                                                      .covered,
                                                              imageProvider:
                                                                  AssetImage(
                                                                "assets/screens/${index + 1}.png",
                                                              ),
                                                            )),
                                                          ),
                                                        ));
                                                      });
                                                    });
                                              },
                                              style: ElevatedButton.styleFrom(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                      vertical: 0,
                                                      horizontal: 0),
                                                  elevation: savedThemeName ==
                                                          themeName
                                                      ? 10
                                                      : 0,
                                                  backgroundColor:
                                                      Colors.transparent),
                                              label: Text(
                                                "View",
                                                style: textTheme.bodyMedium
                                                    ?.copyWith(
                                                        fontSize: 10,
                                                        color:
                                                            colors.themeColor),
                                              ),
                                            ),
                                          ),
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
