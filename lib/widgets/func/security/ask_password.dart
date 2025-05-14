import 'package:flutter/material.dart';
import 'package:moonwallet/service/db/wallet_db_stateless.dart';
import 'package:moonwallet/types/types.dart';
import 'package:moonwallet/widgets/bottom_pin.dart';
import 'package:moonwallet/widgets/dialogs/show_custom_snackbar.dart';

Future<String?> askUserPassword(
    {required BuildContext context,
    required AppColors colors,
    String title = "Enter Password"}) async {
  String userPassword = "";

  int attempt = 0;

  final manager = WalletDbStateLess();

  final res = await showPinModalBottomSheet(
      colors: colors,
      // ignore: use_build_context_synchronously
      context: context,
      handleSubmit: (password) async {
        final isValid = await manager.isPasswordValid(password);
        if (attempt >= 3) {
          notifyError("Too Many attempts", context);
          return PinSubmitResult(
            success: false,
            repeat: false,
          );
        }
        if (isValid) {
          userPassword = password;

          return PinSubmitResult(success: true, repeat: false);
        } else if (!isValid) {
          attempt++;
          return PinSubmitResult(
              success: false,
              repeat: true,
              error: "Invalid password",
              newTitle: "Try again");
        } else {
          return PinSubmitResult(
            success: false,
            repeat: false,
          );
        }
      },
      title: title);

  if (res && userPassword.isNotEmpty) {
    return userPassword;
  }

  return "";
}
