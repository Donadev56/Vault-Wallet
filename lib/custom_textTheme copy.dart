import 'package:flutter/material.dart';
import 'package:moonwallet/types/types.dart';

TextTheme customTextTheme(AppColors colors) => TextTheme(
      displayLarge: TextStyle(
        fontFamily: "ibm_plex_sans",
        fontSize: 57,
        fontWeight: FontWeight.bold,
        color: colors.textColor,
        letterSpacing: -0.25,
      ),
      displayMedium: TextStyle(
        fontFamily: "ibm_plex_sans",
        fontSize: 45,
        fontWeight: FontWeight.bold,
        color: colors.textColor,
      ),
      displaySmall: TextStyle(
        fontFamily: "ibm_plex_sans",
        fontSize: 36,
        fontWeight: FontWeight.w600,
        color: colors.textColor,
      ),
      headlineLarge: TextStyle(
        fontFamily: "ibm_plex_sans",
        fontSize: 32,
        fontWeight: FontWeight.w600,
        color: colors.textColor,
      ),
      headlineMedium: TextStyle(
        fontFamily: "ibm_plex_sans",
        fontSize: 28,
        fontWeight: FontWeight.w500,
        color: colors.textColor,
      ),
      headlineSmall: TextStyle(
        fontFamily: "ibm_plex_sans",
        fontSize: 24,
        fontWeight: FontWeight.w500,
        color: colors.textColor,
      ),
      titleLarge: TextStyle(
        fontFamily: "ibm_plex_sans",
        fontSize: 22,
        fontWeight: FontWeight.bold,
        color: colors.textColor,
      ),
      titleMedium: TextStyle(
        fontFamily: "ibm_plex_sans",
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: colors.textColor.withOpacity(0.9),
      ),
      titleSmall: TextStyle(
        fontFamily: "ibm_plex_sans",
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: colors.textColor.withOpacity(0.85),
      ),
      bodyLarge: TextStyle(
        fontFamily: "ibm_plex_sans",
        fontSize: 16,
        fontWeight: FontWeight.normal,
        color: colors.textColor,
      ),
      bodyMedium: TextStyle(
        fontFamily: "ibm_plex_sans",
        fontSize: 14,
        fontWeight: FontWeight.normal,
        color: colors.textColor.withOpacity(0.9),
      ),
      bodySmall: TextStyle(
        fontFamily: "ibm_plex_sans",
        fontSize: 12,
        fontWeight: FontWeight.normal,
        color: colors.textColor.withOpacity(0.7),
      ),
      labelLarge: TextStyle(
        fontFamily: "ibm_plex_sans",
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: colors.textColor,
      ),
      labelMedium: TextStyle(
        fontSize: 12,
        fontFamily: "ibm_plex_sans",
        fontWeight: FontWeight.w500,
        color: colors.textColor.withOpacity(0.8),
      ),
      labelSmall: TextStyle(
        fontFamily: "ibm_plex_sans",
        fontSize: 11,
        fontWeight: FontWeight.w400,
        color: colors.textColor.withOpacity(0.6),
      ),
    );
