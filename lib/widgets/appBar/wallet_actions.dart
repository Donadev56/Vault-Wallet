import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:moonwallet/main.dart';
import 'package:moonwallet/types/types.dart';
import 'package:moonwallet/widgets/appBar/button.dart';

class WalletActions extends StatelessWidget {

  final DoubleFactor roundedOf;
  final DoubleFactor fontSizeOf;
  final DoubleFactor iconSizeOf;
  final AppColors colors;
  const WalletActions({super.key, required this.colors,
  required this.fontSizeOf,
  required this.iconSizeOf,
  required this.roundedOf});

  @override
  Widget build(BuildContext context) {
    return Column(
      spacing: 10,
      children: [
        CustomListTitleButton(
          roundedOf: roundedOf,
          fontSizeOf: fontSizeOf,
          iconSizeOf: iconSizeOf,
            textColor: colors.textColor,
            text: "Create a new wallet",
            icon: Icons.add,
            onTap: () {
              Navigator.pushNamed(context, Routes.createPrivateKeyMain);
            }),
        CustomListTitleButton(
            roundedOf: roundedOf,
          fontSizeOf: fontSizeOf,
          iconSizeOf: iconSizeOf,
            textColor: colors.textColor,
            text: "Import Mnemonic phrases",
            icon: LucideIcons.fileText,
            onTap: () {
              Navigator.pushNamed(context, Routes.createAccountFromSed);
            }),
        CustomListTitleButton(
            roundedOf: roundedOf,
          fontSizeOf: fontSizeOf,
          iconSizeOf: iconSizeOf,
            textColor: colors.textColor,
            text: "Import private key",
            icon: LucideIcons.key,
            onTap: () {
              Navigator.pushNamed(context, Routes.importWalletMain);
            }),
        CustomListTitleButton(
            roundedOf: roundedOf,
          fontSizeOf: fontSizeOf,
          iconSizeOf: iconSizeOf,
            textColor: colors.textColor,
            text: "Observation wallet",
            icon: LucideIcons.eye,
            onTap: () {
              Navigator.pushNamed(context, Routes.addObservationWallet);
            })
      ],
    );
  }
}
