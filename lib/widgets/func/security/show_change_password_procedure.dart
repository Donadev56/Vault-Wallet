import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:moonwallet/service/db/wallet_saver.dart';
import 'package:moonwallet/types/types.dart';
import 'package:moonwallet/widgets/bottom_pin_copy.dart';
import 'package:moonwallet/widgets/func/security/ask_password.dart';
import 'package:moonwallet/widgets/func/snackbar.dart';

void showChangePasswordProcedure(
    {required BuildContext context, required AppColors colors}) async {
  String newPassword = "";
  String confirmPassword = "";

  final password = await askPassword(
      useBio: false, context: context, colors: colors, title: "Old Password");
  if (password.isEmpty) {
    showCustomSnackBar(
        context: context,
        message: "Incorrect password",
        type: MessageType.error,
        colors: colors);
    return;
  }

  final res = await showPinModalBottomSheet(
      canApplyBlur: true,
      context: context,
      handleSubmit: (password) async {
        if (newPassword.isEmpty) {
          newPassword = password;
          return PinSubmitResult(
              success: true, repeat: true, newTitle: "Repeat Password");
        } else {
          if (newPassword.trim() != password.trim()) {
            newPassword = "";
            return PinSubmitResult(
                success: false,
                repeat: true,
                newTitle: "New password",
                error: "Password does not match");
          } else {
            confirmPassword = newPassword;
            return PinSubmitResult(success: true, repeat: false);
          }
        }
      },
      colors: colors,
      title: "New password");

  if (res) {
    if (password == confirmPassword) {
      showCustomSnackBar(
          type: MessageType.error,
          context: context,
          message: "The old password and the new one are the same",
          colors: colors);
      newPassword = "";
      confirmPassword = "";
    } else {
      final walletManager = WalletSaver();
      final result =
          await walletManager.changePassword(password, confirmPassword);
      if (!result) {
        showCustomSnackBar(
            context: context,
            message: "Failed to change password",
            type: MessageType.error,
            colors: colors);
        newPassword = "";
        confirmPassword = "";
      } else {
        showCustomSnackBar(
            icon: Icons.check,
            iconColor: colors.greenColor,
            context: context,
            message: "Password changed successfully",
            type: MessageType.success,
            colors: colors);
      }
    }
  }
}
