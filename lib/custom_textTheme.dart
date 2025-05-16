import 'package:flutter/material.dart';

TextTheme customTextTheme(colors) => TextTheme(
      displayLarge: TextStyle(
        fontFamily: "custom_inter",
        fontSize: 57,
        fontWeight: FontWeight.bold,
        color: colors.textColor,
        letterSpacing: -0.25,
      ),
      displayMedium: TextStyle(
        fontFamily: "custom_inter",
        fontSize: 45,
        fontWeight: FontWeight.bold,
        color: colors.textColor,
      ),
      displaySmall: TextStyle(
        fontFamily: "custom_inter",
        fontSize: 36,
        fontWeight: FontWeight.w600,
        color: colors.textColor,
      ),
      headlineLarge: TextStyle(
        fontFamily: "custom_inter",
        fontSize: 32,
        fontWeight: FontWeight.w600,
        color: colors.textColor,
      ),
      headlineMedium: TextStyle(
        fontFamily: "custom_inter",
        fontSize: 28,
        fontWeight: FontWeight.w500,
        color: colors.textColor,
      ),
      headlineSmall: TextStyle(
        fontFamily: "custom_inter",
        fontSize: 24,
        fontWeight: FontWeight.w500,
        color: colors.textColor,
      ),
      titleLarge: TextStyle(
        fontFamily: "custom_inter",
        fontSize: 22,
        fontWeight: FontWeight.bold,
        color: colors.textColor,
      ),
      titleMedium: TextStyle(
        fontFamily: "custom_inter",
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: colors.textColor.withOpacity(0.9),
      ),
      titleSmall: TextStyle(
        fontFamily: "custom_inter",
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: colors.textColor.withOpacity(0.85),
      ),
      bodyLarge: TextStyle(
        fontFamily: "custom_inter",
        fontSize: 16,
        fontWeight: FontWeight.normal,
        color: colors.textColor,
      ),
      bodyMedium: TextStyle(
        fontFamily: "custom_inter",
        fontSize: 14,
        fontWeight: FontWeight.normal,
        color: colors.textColor.withOpacity(0.9),
      ),
      bodySmall: TextStyle(
        fontFamily: "custom_inter",
        fontSize: 12,
        fontWeight: FontWeight.normal,
        color: colors.textColor.withOpacity(0.7),
      ),
      labelLarge: TextStyle(
        fontFamily: "custom_inter",
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: colors.textColor,
      ),
      labelMedium: TextStyle(
        fontSize: 12,
        fontFamily: "custom_inter",
        fontWeight: FontWeight.w500,
        color: colors.textColor.withOpacity(0.8),
      ),
      labelSmall: TextStyle(
        fontFamily: "custom_inter",
        fontSize: 11,
        fontWeight: FontWeight.w400,
        color: colors.textColor.withOpacity(0.6),
      ),
    );
