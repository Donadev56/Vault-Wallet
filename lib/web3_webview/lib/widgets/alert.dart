import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:moonwallet/logger/logger.dart';
import 'package:moonwallet/types/types.dart';

Future<bool> showAlert(
    {required BuildContext context,
    String? title,
    String? content,
    required AppColors colors,
    Color? contentColor,
    String? confirmText,
    String? cancelText}) async {
  log("===== Showing the wallet ======");
  final result = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: colors.primaryColor,
          title: title != null
              ? Text(
                  title,
                  style: GoogleFonts.roboto(color: colors.textColor),
                )
              : null,
          content: content != null
              ? Text(
                  content,
                  style: GoogleFonts.roboto(
                      color: contentColor ?? colors.textColor.withOpacity(0.8)),
                )
              : null,
          actions: <Widget>[
            if (cancelText != null)
              TextButton(
                onPressed: () async {
                  Navigator.pop(context, false);
                },
                child: Text(cancelText,
                    style: GoogleFonts.roboto(color: colors.textColor)),
              ),
            if (confirmText != null)
              TextButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: colors.secondaryColor),
                onPressed: () async {
                  Navigator.pop(context, true);
                },
                child: Text(confirmText,
                    style: GoogleFonts.roboto(color: colors.textColor)),
              )
          ],
        );
      });
  return result ?? false;
}

Future<void> sendWatchOnlyAlert(BuildContext context, AppColors colors) async {
  await showAlert(
      context: context,
      colors: colors,
      contentColor: Colors.orange,
      title: "Watch only",
      content: "Watch-only wallet cannot send transactions.",
      cancelText: "Ok");
}
