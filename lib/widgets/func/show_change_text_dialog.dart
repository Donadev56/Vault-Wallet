import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:moonwallet/types/types.dart';

void showChangeTextDialog(
    {required BuildContext context,
    required AppColors colors,
    required TextEditingController textController,
    required Future<void> Function(String) onSubmit}) {
  showDialog(
      context: context,
      builder: (BuildContext alertCtx) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
          child: AlertDialog.adaptive(
            backgroundColor: colors.primaryColor,
            title: Text(
              "New name",
            ),
            titleTextStyle: GoogleFonts.roboto(
              fontSize: 18,
              color: colors.textColor.withOpacity(0.5),
            ),
            content: SizedBox(
              height: 50,
              child: TextField(
                cursorColor: colors.textColor.withOpacity(0.2),
                style: GoogleFonts.roboto(color: colors.textColor),
                controller: textController,
                decoration: InputDecoration(
                    filled: true,
                    fillColor: colors.textColor.withOpacity(0.1),
                    enabledBorder: OutlineInputBorder(
                      borderSide:
                          BorderSide(width: 0, color: Colors.transparent),
                    ),
                    focusedBorder: OutlineInputBorder(
                        borderSide:
                            BorderSide(width: 0, color: Colors.transparent))),
              ),
            ),
            actions: [
              TextButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.pinkAccent.withOpacity(0.1)),
                onPressed: () {
                  textController.text = "";
                  Navigator.pop(alertCtx);
                },
                child: Text(
                  "Close",
                  style: TextStyle(
                    color: Colors.pinkAccent,
                  ),
                ),
              ),
              TextButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: colors.themeColor.withOpacity(0.1)),
                onPressed: () {
                  onSubmit(textController.text);
                  Navigator.pop(alertCtx);
                },
                child: Text(
                  "change",
                  style: TextStyle(
                    color: colors.themeColor,
                  ),
                ),
              ),
            ],
          ),
        );
      });
}
