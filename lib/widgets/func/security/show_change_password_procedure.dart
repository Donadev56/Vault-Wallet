import 'package:flutter/material.dart';
import 'package:moonwallet/service/db/wallet_db.dart';
import 'package:moonwallet/types/types.dart';
import 'package:moonwallet/widgets/bottom_pin.dart';
import 'package:moonwallet/widgets/func/security/ask_password.dart';
import 'package:moonwallet/widgets/dialogs/show_custom_snackbar.dart';

void showChangePasswordProcedure(
    {required BuildContext context, required AppColors colors}) async {
  String newPassword = "";
  String confirmedPassword = "";

  final password = await askUserPassword(
      context: context, colors: colors, title: "Old Password");

  if (password == null || password.isEmpty) {
    notifyError("Incorrect password", context);
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
            confirmedPassword = newPassword;
            return PinSubmitResult(success: true, repeat: false);
          }
        }
      },
      colors: colors,
      title: "New password");

  if (res) {
    if (password == confirmedPassword) {
      notifyError("The old password and the new one are the same", context);
      newPassword = "";
      confirmedPassword = "";
    } else {
      final walletManager = WalletDatabase();
      final result =
          await walletManager.changePassword(password, confirmedPassword);
      if (!result) {
        notifyError("Failed to change password", context);
        newPassword = "";
        confirmedPassword = "";
      } else {
        notifySuccess("Password changed successfully", context);
      }
    }
  }
}
