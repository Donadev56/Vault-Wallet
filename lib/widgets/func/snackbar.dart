import 'package:cherry_toast/cherry_toast.dart';
import 'package:flutter/material.dart';
import 'package:moonwallet/types/types.dart';
/*
void showCustomSnackBar(
    {required BuildContext context,
    required String message,
    IconData icon = Icons.info,
    required AppColors colors,
    Color? iconColor}) {
  DelightToastBar(
    autoDismiss: true,
    builder: (context) => ToastCard(
    
      color: colors.secondaryColor,
      leading: Icon(
        color: iconColor ?? colors.redColor,
        icon,
        size: 28,
      ),
      title: Text(
        message,
        style: TextStyle(
          color: colors.textColor,
          fontWeight: FontWeight.w700,
          fontSize: 14,
        ),
      ),
    ),
  ).show(context);
}
*/

void showCustomSnackBar(
    {required BuildContext context,
    required String message,
    IconData icon = Icons.info,
    required AppColors colors,
    required MessageType type,
    Color? iconColor}) {
  final title = Text(message, style: TextStyle(color: colors.textColor));
  final shadowColor = null;
  final double borderRadius = 20;
  final duration = Duration(milliseconds: 500);
  switch (type) {
    case MessageType.success:
      CherryToast.success(
              borderRadius: borderRadius,
              animationDuration: duration,
              backgroundColor: colors.primaryColor,
              title: title)
          .show(context);
    case MessageType.error:
      CherryToast.error(
              borderRadius: borderRadius,
              animationDuration: duration,
              backgroundColor: colors.primaryColor,
              title: title)
          .show(context);

    case MessageType.warning:
      CherryToast.warning(
              borderRadius: borderRadius,
              animationDuration: duration,
              backgroundColor: colors.primaryColor,
              title: title)
          .show(context);

    case MessageType.info:
      CherryToast.warning(
              borderRadius: borderRadius,
              animationDuration: duration,
              backgroundColor: colors.primaryColor,
              title: title)
          .show(context);

      break;
  }
}
