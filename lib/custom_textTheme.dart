import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:moonwallet/types/types.dart';

TextTheme customTextTheme(AppColors colors) => TextTheme(
      displayLarge: GoogleFonts.ibmPlexSans(
        fontSize: 57,
        fontWeight: FontWeight.bold,
        color: colors.textColor,
        letterSpacing: -0.25,
      ),
      displayMedium: GoogleFonts.ibmPlexSans(
        fontSize: 45,
        fontWeight: FontWeight.bold,
        color: colors.textColor,
      ),
      displaySmall: GoogleFonts.ibmPlexSans(
        fontSize: 36,
        fontWeight: FontWeight.w600,
        color: colors.textColor,
      ),
      headlineLarge: GoogleFonts.ibmPlexSans(
        fontSize: 32,
        fontWeight: FontWeight.w600,
        color: colors.textColor,
      ),
      headlineMedium: GoogleFonts.ibmPlexSans(
        fontSize: 28,
        fontWeight: FontWeight.w500,
        color: colors.textColor,
      ),
      headlineSmall: GoogleFonts.ibmPlexSans(
        fontSize: 24,
        fontWeight: FontWeight.w500,
        color: colors.textColor,
      ),
      titleLarge: GoogleFonts.ibmPlexSans(
        fontSize: 22,
        fontWeight: FontWeight.bold,
        color: colors.textColor,
      ),
      titleMedium: GoogleFonts.ibmPlexSans(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: colors.textColor.withOpacity(0.9),
      ),
      titleSmall: GoogleFonts.ibmPlexSans(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: colors.textColor.withOpacity(0.85),
      ),
      bodyLarge: GoogleFonts.ibmPlexSans(
        fontSize: 16,
        fontWeight: FontWeight.normal,
        color: colors.textColor,
      ),
      bodyMedium: GoogleFonts.ibmPlexSans(
        fontSize: 14,
        fontWeight: FontWeight.normal,
        color: colors.textColor.withOpacity(0.9),
      ),
      bodySmall: GoogleFonts.ibmPlexSans(
        fontSize: 12,
        fontWeight: FontWeight.normal,
        color: colors.textColor.withOpacity(0.7),
      ),
      labelLarge: GoogleFonts.ibmPlexSans(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: colors.textColor,
      ),
      labelMedium: GoogleFonts.ibmPlexSans(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: colors.textColor.withOpacity(0.8),
      ),
      labelSmall: GoogleFonts.ibmPlexSans(
        fontSize: 11,
        fontWeight: FontWeight.w400,
        color: colors.textColor.withOpacity(0.6),
      ),
    );
