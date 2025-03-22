import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:moonwallet/logger/logger.dart';
import 'package:moonwallet/service/web3.dart';
import 'package:moonwallet/types/types.dart';
import 'package:moonwallet/utils/prefs.dart';
import 'package:moonwallet/widgets/bottom_pin_copy.dart';

Future<String> askPassword(
    {required BuildContext context,
    required AppColors colors,
    String title = "Enter Password"}) async {
  String userPassword = "";
  final LocalAuthentication auth = LocalAuthentication();
  bool didAuthenticate = false;
  final manager = Web3Manager();

  final biometryStatus =
      await PublicDataManager().getDataFromPrefs(key: "BioStatus");
  if (biometryStatus == "on") {
    try {
      didAuthenticate = await auth.authenticate(
          localizedReason: 'Please authenticate to continue');
    } catch (e) {
      logError(e.toString());
      didAuthenticate = false;
    }
  } else {
    didAuthenticate = false;
  }
  if (didAuthenticate) {
    final savedKey = await manager.getSavedPassword();
    if (savedKey != null) {
      return savedKey;
    } else {
      return "";
    }
  }
  final res = await showPinModalBottomSheet(
      colors: colors,
      // ignore: use_build_context_synchronously
      context: context,
      handleSubmit: (password) async {
        final savedPassword = await manager.getSavedPassword();
        if (savedPassword != null) {
          if (password.trim() != savedPassword.trim()) {
            return PinSubmitResult(
                success: false,
                repeat: true,
                error: "Invalid password",
                newTitle: "Try again");
          } else {
            userPassword = password;

            return PinSubmitResult(success: true, repeat: false);
          }
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
