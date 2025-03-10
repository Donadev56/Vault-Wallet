import 'package:delightful_toast/delight_toast.dart';
import 'package:delightful_toast/toast/components/toast_card.dart';
import 'package:flutter/material.dart';
import 'package:moonwallet/types/types.dart';

void showCustomSnackBar(
    {required BuildContext context,
    required String message,
    required Color primaryColor,
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
