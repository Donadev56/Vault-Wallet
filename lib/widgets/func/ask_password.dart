import 'package:flutter/material.dart';
import 'package:moonwallet/service/web3.dart';
import 'package:moonwallet/types/types.dart';
import 'package:moonwallet/widgets/bottom_pin.dart';

Future<String> askPassword(
    {required BuildContext context, required AppColors colors}) async {
  String userPassword = "";
  final res = await showPinModalBottomSheet(
      colors: colors,
      // ignore: use_build_context_synchronously
      context: context,
      handleSubmit: (password) async {
        final manager = Web3Manager();
        final savedPassword = await manager.getSavedPassword();
        if (password.trim() != savedPassword) {
          return PinSubmitResult(
              success: false,
              repeat: true,
              error: "Invalid password",
              newTitle: "Try again");
        } else {
          userPassword = password;

          return PinSubmitResult(success: true, repeat: false);
        }
      },
      title: "Enter Password");
  if (res && userPassword.isNotEmpty) {
    return userPassword;
  }
  return "";
}
