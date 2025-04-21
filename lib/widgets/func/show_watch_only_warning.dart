import 'package:flutter/material.dart';
import 'package:moonwallet/types/types.dart';

void showWatchOnlyWaring(
    {required AppColors colors,
    String text =
        "This is a watch wallet only, it does not contain any valid keys.",
    required BuildContext context}) {
  showDialog(
      context: context,
      builder: (BuildContext wOCtx) {
        final textTheme = TextTheme.of(context);

        return AlertDialog(
          backgroundColor: colors.primaryColor,
          title: Text(
            "Warning",
            style: textTheme.headlineMedium?.copyWith(color: colors.textColor),
          ),
          content: Text(
            text,
            style: textTheme.bodyMedium?.copyWith(color: colors.redColor),
          ),
          actions: [
            ElevatedButton(
              style:
                  ElevatedButton.styleFrom(backgroundColor: colors.themeColor),
              child: Text("Ok"),
              onPressed: () {
                Navigator.pop(wOCtx);
              },
            ),
          ],
        );
      });
}
