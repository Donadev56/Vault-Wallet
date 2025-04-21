import 'package:flutter/material.dart';
import 'package:moonwallet/types/types.dart';

void showWatchOnlyWaring(AppColors colors, BuildContext context) {
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
            "This a watch-only account, you won't be able to send the transaction on the blockchain.",
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
