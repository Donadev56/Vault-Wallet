import 'package:flutter/material.dart';
import 'package:moonwallet/types/types.dart';

class Themes {
  Map<String, AppColors> get allColors => {
        "futuristicTheme": futuristicTheme,
        "futuristicThemeGreen": futuristicThemeGreen,
        "darkColors": darkColors,
        "dimColors": dimColors,
        "darkGrayColor": darkGrayColor,
        "sombreColors": sombreColors,
        "lightColors": lightColors,
        "modernColors": modernColors,
        "professionalColors": professionalColors,
        "neonColors": neonColors,
        "pastelColors": pastelColors,
        "contrastColors": contrastColors,
        "blueDarkTheme": blueDarkTheme,
        "redDarkTheme": redDarkTheme,
        "purpleTheme": purpleTheme,
        "tealTheme": tealTheme,
        "minimalTheme": minimalTheme,
        "elegantTheme": elegantTheme,
        "noirTheme": noirTheme,
        "industrialTheme": industrialTheme,
        "classicTheme": classicTheme,
        "redAccentBlack": redAccentBlack,
        "binance": binanceColors
      };
  AppColors darkGrayColor = AppColors(
      primaryColor: Color(0XFF1B1B1B),
      themeColor: const Color.fromARGB(255, 83, 250, 170),
      greenColor: Colors.greenAccent,
      secondaryColor: Color(0XFF454545),
      grayColor: Color(0XFF353535),
      textColor: Color(0xFFF5F5F5),
      redColor: Colors.pinkAccent,
      type: ColorType.dark);

  AppColors futuristicTheme = AppColors(
      primaryColor: Color(0XFF111015),
      themeColor: Colors.lightBlueAccent,
      greenColor: Colors.green,
      secondaryColor: Color(0XFF2C2D31),
      grayColor: Color(0XFF2A2A2A),
      textColor: Colors.white,
      redColor: Colors.deepOrangeAccent,
      type: ColorType.dark);

  AppColors futuristicThemeGreen = AppColors(
      primaryColor: Color(0XFF111015),
      themeColor: Color.fromARGB(255, 0, 193, 100),
      greenColor: Color.fromARGB(255, 0, 193, 100),
      secondaryColor: Color(0XFF2C2D31),
      grayColor: Color(0XFF2A2A2A),
      textColor: Colors.white,
      redColor: const Color.fromARGB(255, 222, 62, 13),
      type: ColorType.dark);

  AppColors darkColors = AppColors(
      primaryColor: Color(0XFF0D0D0D),
      themeColor: const Color.fromARGB(255, 83, 250, 170),
      greenColor: Colors.greenAccent,
      secondaryColor: Color(0XFF121212),
      grayColor: Color(0XFF353535),
      textColor: Colors.white,
      redColor: Colors.pinkAccent,
      type: ColorType.dark);

  AppColors dimColors = AppColors(
      primaryColor: Color(0XFF1A1A1A),
      themeColor: Colors.blueGrey,
      greenColor: Colors.lightGreen,
      secondaryColor: Color(0XFF2C2C2C),
      grayColor: Color(0XFF4F4F4F),
      textColor: Colors.white70,
      redColor: Colors.deepOrangeAccent,
      type: ColorType.dark);

  AppColors sombreColors = AppColors(
      primaryColor: Color(0XFF0A0A0A),
      themeColor: Colors.deepPurpleAccent,
      greenColor: Colors.tealAccent,
      secondaryColor: Color(0XFF151515),
      grayColor: Color(0XFF2E2E2E),
      textColor: Colors.white,
      redColor: Colors.redAccent,
      type: ColorType.dark);

  AppColors lightColors = AppColors(
      primaryColor: Color(0XFFFFFFFF),
      themeColor: Colors.lightBlueAccent,
      greenColor: const Color.fromARGB(255, 0, 175, 90),
      secondaryColor: Color(0XFFF0F0F0),
      grayColor: Color(0XFFBDBDBD),
      textColor: Colors.black,
      redColor: Colors.redAccent,
      type: ColorType.light);

  AppColors modernColors = AppColors(
      primaryColor: Color(0XFF101820),
      themeColor: Colors.cyanAccent,
      greenColor: Colors.greenAccent,
      secondaryColor: Color(0XFF1F2A37),
      grayColor: Color(0XFF3E4C59),
      textColor: Colors.white,
      redColor: Colors.deepOrangeAccent,
      type: ColorType.dark);

  AppColors professionalColors = AppColors(
      primaryColor: Color(0XFF202124),
      themeColor: Colors.indigoAccent,
      greenColor: Colors.teal,
      secondaryColor: Color(0XFF2C2F33),
      grayColor: Color(0XFF555555),
      textColor: Colors.white,
      redColor: Colors.redAccent,
      type: ColorType.dark);

  AppColors neonColors = AppColors(
      primaryColor: Color(0XFF000000),
      themeColor: Colors.pinkAccent,
      greenColor: Colors.limeAccent,
      secondaryColor: Color(0XFF121212),
      grayColor: Color(0XFF333333),
      textColor: Colors.white,
      redColor: Colors.amberAccent,
      type: ColorType.dark);

  AppColors pastelColors = AppColors(
      primaryColor: Color(0XFFF8F8F8),
      themeColor: Color.fromARGB(255, 0, 193, 100),
      greenColor: Color.fromARGB(255, 0, 193, 100),
      secondaryColor: Color(0XFFF0F0F0),
      grayColor: Color(0XFFBDBDBD),
      textColor: Colors.black87,
      redColor: Color.fromARGB(255, 248, 107, 64),
      type: ColorType.light);

  AppColors contrastColors = AppColors(
      primaryColor: Color(0XFF000000),
      themeColor: const Color.fromARGB(255, 255, 183, 0),
      greenColor: Colors.green,
      secondaryColor: Color(0XFF222222),
      grayColor: Color(0XFF555555),
      textColor: const Color.fromARGB(255, 255, 254, 252),
      redColor: Colors.redAccent,
      type: ColorType.dark);

  AppColors blueDarkTheme = AppColors(
      primaryColor: Color(0XFF0D1B2A),
      themeColor: Colors.blueAccent,
      greenColor: Colors.cyan,
      secondaryColor: Color(0XFF1B263B),
      grayColor: Color(0XFF415A77),
      textColor: Colors.white,
      redColor: Colors.redAccent,
      type: ColorType.dark);

  AppColors redDarkTheme = AppColors(
      primaryColor: Color(0XFF2B1B18),
      themeColor: Colors.redAccent,
      greenColor: Colors.green,
      secondaryColor: Color(0XFF3C2F2B),
      grayColor: Color(0XFF5A4D4C),
      textColor: Colors.white,
      redColor: Colors.deepOrange,
      type: ColorType.other);

  AppColors purpleTheme = AppColors(
      primaryColor: Color(0XFF1B0A3D),
      themeColor: Colors.purpleAccent,
      greenColor: Colors.teal,
      secondaryColor: Color(0XFF2C1B4B),
      grayColor: Color(0XFF584E68),
      textColor: Colors.white,
      redColor: Colors.pinkAccent,
      type: ColorType.other);

  AppColors tealTheme = AppColors(
      primaryColor: Color(0XFF003B46),
      themeColor: Colors.tealAccent,
      greenColor: Colors.teal,
      secondaryColor: Color(0XFF07575B),
      grayColor: Color(0XFF66A5AD),
      textColor: Colors.white,
      redColor: Colors.orangeAccent,
      type: ColorType.other);

  AppColors minimalTheme = AppColors(
      primaryColor: Color(0XFFFFFFFF),
      themeColor: const Color.fromARGB(255, 255, 183, 0),
      greenColor: Colors.grey,
      secondaryColor: Color(0XFFF0F0F0),
      grayColor: Color(0XFFBDBDBD),
      textColor: Colors.black,
      redColor: Colors.redAccent,
      type: ColorType.light);

  AppColors elegantTheme = AppColors(
      primaryColor: Color(0XFF2C2C2C),
      themeColor: Colors.blueAccent,
      greenColor: const Color.fromARGB(255, 0, 175, 90),
      secondaryColor: Color(0XFF3A3A3A),
      grayColor: Color(0XFF707070),
      textColor: Colors.white,
      redColor: Colors.pinkAccent,
      type: ColorType.dark);

  AppColors noirTheme = AppColors(
      primaryColor: Color(0XFF000000),
      themeColor: Colors.grey,
      greenColor: Colors.greenAccent,
      secondaryColor: Color(0XFF101010),
      grayColor: Color(0XFF1C1C1C),
      textColor: Colors.white,
      redColor: Colors.redAccent,
      type: ColorType.dark);

  AppColors industrialTheme = AppColors(
      primaryColor: Color(0XFF212121),
      themeColor: Colors.blueGrey,
      greenColor: Colors.green,
      secondaryColor: Color(0XFF424242),
      grayColor: Color(0XFF757575),
      textColor: Colors.white,
      redColor: Colors.redAccent,
      type: ColorType.dark);

  AppColors classicTheme = AppColors(
      primaryColor: Color(0XFF1A1A1A),
      themeColor: Colors.indigo,
      greenColor: Colors.green,
      secondaryColor: Color(0XFF2B2B2B),
      grayColor: Color(0XFF484848),
      textColor: Colors.white,
      redColor: Colors.redAccent,
      type: ColorType.dark);
}

AppColors redAccentBlack = AppColors(
    primaryColor: Color(0XFF000000),
    themeColor: Colors.redAccent,
    greenColor: Colors.green,
    secondaryColor: Color(0XFF101010),
    grayColor: Color(0XFF1C1C1C),
    textColor: Colors.white,
    redColor: Colors.deepOrange,
    type: ColorType.other);

AppColors binanceColors = AppColors(
    primaryColor: Color(0XFF1f242f),
    themeColor: Color(0XFFfbd23e),
    greenColor: Color(0XFF31e6a1),
    secondaryColor: Color(0XFF29313c),
    grayColor: Color(0XFF676c77),
    textColor: Colors.white,
    redColor: Color.fromARGB(255, 207, 31, 89),
    type: ColorType.dark);
/* AppColors lightColors = AppColors(
      primaryColor: Colors.white,
      themeColor: Colors.greenAccent,
      greenColor: Colors.greenAccent,
      secondaryColor: Colors.black,
      grayColor: Colors.white70,
      textColor: Colors.black,
      redColor: Colors.pinkAccent); */
