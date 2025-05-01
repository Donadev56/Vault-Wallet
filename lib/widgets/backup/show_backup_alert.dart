import 'package:flutter/material.dart';
import 'package:moonwallet/custom/web3_webview/lib/widgets/alert.dart';
import 'package:moonwallet/types/types.dart';

void showBackupAlert(
    {required BuildContext context, required AppColors colors}) {
  showAlert(
      context: context,
      colors: colors,
      title: "Backup your wallet",
      content:
          "Backup your wallet to avoid losing your assets. You can do this by going to the settings and selecting 'Backup'.");
}
