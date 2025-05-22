import 'package:flutter/material.dart';
import 'package:moonwallet/custom/web3_webview/lib/ethereum/wallet_dialog_service.dart';
import 'package:moonwallet/types/types.dart';

class StandardSendBottomButton extends StatelessWidget {
  final AppColors colors;
  final void Function()? onConfirmPress;
  StandardSendBottomButton(
      {super.key, required this.colors, required this.onConfirmPress});
  final WalletDialogService dialogService = WalletDialogService.instance;

  @override
  Widget build(BuildContext context) {
    return dialogService.buildActionButtons(
        context: context,
        cancelText: "Cancel",
        confirmText: "Continue",
        colors: colors,
        onConfirmPress: onConfirmPress,
        onCancelPress: () => Navigator.pop(context));
  }
}
