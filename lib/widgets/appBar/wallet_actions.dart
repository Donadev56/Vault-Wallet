import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:moonwallet/logger/logger.dart';
import 'package:moonwallet/main.dart';
import 'package:moonwallet/screens/dashboard/wallet_actions/add_private_key.dart';
import 'package:moonwallet/screens/dashboard/wallet_actions/add_w_o.dart';
import 'package:moonwallet/service/external_data/crypto_request_manager.dart';
import 'package:moonwallet/types/account_related_types.dart';
import 'package:moonwallet/types/types.dart';
import 'package:moonwallet/widgets/appBar/button.dart';
import 'package:moonwallet/widgets/func/tokens_config/show_select_ecosystem.dart';

class WalletActions extends HookConsumerWidget {
  final DoubleFactor roundedOf;
  final DoubleFactor fontSizeOf;
  final DoubleFactor iconSizeOf;
  final AppColors colors;
  const WalletActions({
    super.key,
    required this.colors,
    required this.fontSizeOf,
    required this.iconSizeOf,
    required this.roundedOf,
  });

  @override
  Widget build(BuildContext context, ref) {
    Future<TokenEcosystem?> selectEcosystem() async {
      final cryptos = await CryptoRequestManager().getAllCryptos();

      if (cryptos.isEmpty) {
        logError("Crypto list is empty");
        return null;
      }
      final networks = cryptos.where((c) => c.isNative).toList();

      final ecosystem = await showSelectEcoSystem(
          context: context,
          colors: colors,
          roundedOf: roundedOf,
          fontSizeOf: fontSizeOf,
          iconSizeOf: iconSizeOf,
          networks: networks);
      if (ecosystem != null) {
        return ecosystem;
      }

      return null;
    }

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
            onTap: () async {
              final ecosystem = await selectEcosystem();
              if (ecosystem == null) {
                return;
              }
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (ctx) =>
                          AddPrivateKeyMain(ecosystem: ecosystem)));
            }),
        CustomListTitleButton(
            roundedOf: roundedOf,
            fontSizeOf: fontSizeOf,
            iconSizeOf: iconSizeOf,
            textColor: colors.textColor,
            text: "Observation wallet",
            icon: LucideIcons.eye,
            onTap: () async {
              final ecosystem = await selectEcosystem();
              if (ecosystem == null) {
                return;
              }
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (ctx) =>
                          AddObservationWallet(ecosystem: ecosystem)));
            })
      ],
    );
  }
}
