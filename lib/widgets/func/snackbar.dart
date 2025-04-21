import 'package:cherry_toast/cherry_toast.dart';
import 'package:flutter/material.dart';
import 'package:moonwallet/types/types.dart';

void showCustomSnackBar(
    {required BuildContext context,
    required String message,
    IconData icon = Icons.info,
    required AppColors colors,
    required MessageType type,
    Color? iconColor}) {
  final title = Text(message, style: TextStyle(color: colors.textColor));
  final shadowColor = const Color.fromARGB(18, 21, 21, 21);
  final double borderRadius = 20;
  final duration = Duration(milliseconds: 500);
  switch (type) {
    case MessageType.success:
      CherryToast.success(
              actionHandler: () {
                Navigator.of(context);
              },
              shadowColor: shadowColor,
              borderRadius: borderRadius,
              animationDuration: duration,
              backgroundColor: colors.primaryColor,
              title: title)
          .show(context);
    case MessageType.error:
      CherryToast.error(
              actionHandler: () {
                Navigator.of(context);
              },
              shadowColor: shadowColor,
              borderRadius: borderRadius,
              animationDuration: duration,
              backgroundColor: colors.primaryColor,
              title: title)
          .show(context);

    case MessageType.warning:
      CherryToast.warning(
              actionHandler: () {
                Navigator.of(context);
              },
              shadowColor: shadowColor,
              borderRadius: borderRadius,
              animationDuration: duration,
              backgroundColor: colors.primaryColor,
              title: title)
          .show(context);

    case MessageType.info:
      CherryToast.warning(
              actionHandler: () {
                Navigator.of(context);
              },
              shadowColor: shadowColor,
              borderRadius: borderRadius,
              animationDuration: duration,
              backgroundColor: colors.primaryColor,
              title: title)
          .show(context);

      break;
  }
}
