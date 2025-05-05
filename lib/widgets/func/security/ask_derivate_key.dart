import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:moonwallet/logger/logger.dart';
import 'package:moonwallet/notifiers/app_secure_config_notifier.dart';
import 'package:moonwallet/service/db/wallet_db_stateless.dart';
import 'package:moonwallet/types/types.dart';
import 'package:moonwallet/widgets/bottom_pin.dart';
import 'package:moonwallet/widgets/func/snackbar.dart';

Future<String?> askDerivateKey(
    {required BuildContext context,
    required AppColors colors,
    bool useBio = true,
    String title = "Enter Password"}) async {
  String userPassword = "";

  int attempt = 0;
  final LocalAuthentication auth = LocalAuthentication();
  bool didAuthenticate = false;
  final manager = WalletDbStateLess();
  final secureConfig = AppSecureConfigNotifier();
  final bioOn = (await (secureConfig.getSecureConfig())).useBioMetric;

  if (useBio) {
    if (bioOn) {
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
  }

  if (didAuthenticate) {
    final savedKey = await manager.getSavedDeriveKey();
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
        final isValid = await manager.isPasswordValid(password);
        if (attempt >= 3) {
          showCustomSnackBar(
              context: context,
              message: "Too Many attempts",
              type: MessageType.error,
              colors: colors);
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
    final deriveKey = manager.derivateEncryptionKeyStateless(userPassword);
    return deriveKey;
  }

  return null;
}
