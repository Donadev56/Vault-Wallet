import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:moonwallet/logger/logger.dart';
import 'package:moonwallet/notifiers/providers.dart';
import 'package:moonwallet/routes.dart';
import 'package:moonwallet/screens/dashboard/wallet_actions/add_private_key.dart';
import 'package:moonwallet/screens/dashboard/wallet_actions/add_w_o.dart';
import 'package:moonwallet/service/crypto_manager.dart';
import 'package:moonwallet/types/account_related_types.dart';
import 'package:moonwallet/types/types.dart';
import 'package:moonwallet/widgets/appBar/custom_list_title_button.dart';
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
  Widget build(BuildContext context, WidgetRef ref) {
    final cryptoProvider = ref.watch(savedCryptosProviderNotifier.notifier);

    Future<TokenEcosystem?> selectEcosystem(String keyName) async {
      final savedTokens = await cryptoProvider.getSavedCrypto();
      final defaultTokens = await CryptoManager().getDefaultTokens();
      final cryptos = CryptoManager().addOnlyNewTokens(
          localList: savedTokens, externalList: defaultTokens);

      if (cryptos.isEmpty) {
        logError("Crypto list is empty");
        return null;
      }
      final networks = cryptos.where((c) => c.isNative).toList();

      final ecosystem = await showSelectEcoSystem(
          keyName: keyName,
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
            colors: colors,
            text: "Create a new wallet",
            icon: Icons.add,
            onTap: () {
              Navigator.pushNamed(context, Routes.createPrivateKeyMain);
            }),
        CustomListTitleButton(
            roundedOf: roundedOf,
            fontSizeOf: fontSizeOf,
            iconSizeOf: iconSizeOf,
            colors: colors,
            text: "Import Mnemonic phrases",
            icon: LucideIcons.fileText,
            onTap: () {
              Navigator.pushNamed(context, Routes.createAccountFromSed);
            }),
        CustomListTitleButton(
            roundedOf: roundedOf,
            fontSizeOf: fontSizeOf,
            iconSizeOf: iconSizeOf,
            colors: colors,
            text: "Import private key",
            icon: LucideIcons.key,
            onTap: () async {
              final ecosystem = await selectEcosystem("private key");
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
            colors: colors,
            text: "Observation wallet",
            icon: LucideIcons.eye,
            onTap: () async {
              final ecosystem = await selectEcosystem("wallet");
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
