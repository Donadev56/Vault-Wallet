import 'package:flutter/material.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:moonwallet/custom/web3_webview/lib/utils/loading.dart';
import 'package:moonwallet/logger/logger.dart';
import 'package:moonwallet/notifiers/saved_crypto.dart';
import 'package:moonwallet/service/crypto_manager.dart';
import 'package:moonwallet/types/account_related_types.dart';
import 'package:moonwallet/types/ecosystem_config.dart';
import 'package:moonwallet/types/types.dart';
import 'package:moonwallet/widgets/custom_filled_text_field.dart';
import 'package:moonwallet/widgets/dialogs/search_modal_header.dart';
import 'package:moonwallet/widgets/dialogs/standard_container.dart';
import 'package:moonwallet/widgets/func/tokens_config/show_token_detials.dart';
import 'package:moonwallet/widgets/screen_widgets/crypto_picture.dart';
import 'package:moonwallet/widgets/standard_network_image.dart';

Future<TokenEcosystem?> showSelectEcoSystem({
  required BuildContext context,
  String title = "Select Network",
   String ? keyName,
   String ? description ,
  
  required AppColors colors,
  required DoubleFactor roundedOf,
  required DoubleFactor fontSizeOf,
  required DoubleFactor iconSizeOf,
}) async {
  final controller = TextEditingController();
  final ecosystemChainsController = TextEditingController();
  final savedTokens =
      await SavedCryptoProvider().getSavedCrypto().withLoading(context, colors);
  final defaultTokens =
      await CryptoManager().getDefaultTokens().withLoading(context, colors);

  final cryptos = CryptoManager()
      .addOnlyNewTokens(localList: savedTokens, externalList: defaultTokens);

  if (cryptos.isEmpty) {
    logError("Crypto list is empty");
    return null;
  }

  final networks = cryptos.where((c) => c.isNative).toList();

  List<TokenEcosystem> getEcosystems() {
    return ecosystemInfo.values
        .toList()
        .where(
            (e) => e.name.toLowerCase().contains(controller.text.toLowerCase()))
        .toList();
  }

  final response = showCupertinoModalBottomSheet<TokenEcosystem?>(
      context: context,
      enableDrag: false,
      builder: (ctx) {
        final textTheme = TextTheme.of(ctx);
        return StatefulBuilder(builder: (ctx, st) {
          return Material(
              color: colors.primaryColor,
              child: StandardContainer(
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 10, horizontal: 5),
                      child: SearchModalAppBar(
                        description:
                         description ?? ( keyName != null ?  "Select the ecosystem to which the $keyName you want to add belongs." : null),
                        hint: "Search Network",
                        onChanged: (v) => st(() {}),
                        controller: controller,
                        colors: colors,
                        title: title,
                        fontSizeOf: fontSizeOf,
                        iconSizeOf: iconSizeOf,
                        roundedOf: roundedOf,
                      ),
                    ),
                    Expanded(
                        child: GlowingOverscrollIndicator(
                      axisDirection: AxisDirection.down,
                      color: colors.themeColor,
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: getEcosystems().length,
                        itemBuilder: (ctx, i) {
                          final ecosystem = getEcosystems()[i];
                          final ecosystemNetworks = networks
                              .where((e) => e.getNetworkType == ecosystem.type)
                              .toList();

                          return ListTile(
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                            leading: StandardNetworkImage(
                                colors: colors, imageUrl: ecosystem.iconUrl),
                            title: Text(ecosystem.name,
                                style: textTheme.bodyMedium?.copyWith(
                                    color: colors.textColor,
                                    fontWeight: FontWeight.w500)),
                            subtitle: ecosystemNetworks.length > 1
                                ? Row(
                                    children: [
                                      InkWell(
                                        onTap: () {
                                          showDialog(
                                              context: context,
                                              builder: (ctx) {
                                                return StatefulBuilder(builder:
                                                    (ctx, setDialogState) {
                                                  return AlertDialog(
                                                    backgroundColor:
                                                        colors.primaryColor,
                                                    contentPadding:
                                                        const EdgeInsets.all(0),
                                                    title: Column(
                                                      spacing: 10,
                                                      children: [
                                                        Header(
                                                            title:
                                                                "${ecosystem.name} Chains",
                                                            colors: colors),
                                                        CustomFilledTextFormField(
                                                          colors: colors,
                                                          onChanged: (v) {
                                                            setDialogState(
                                                                () {});
                                                          },
                                                          fontSizeOf:
                                                              fontSizeOf,
                                                          iconSizeOf:
                                                              iconSizeOf,
                                                          roundedOf: roundedOf,
                                                          controller:
                                                              ecosystemChainsController,
                                                          prefixIcon: Icon(
                                                            Icons.search,
                                                            color: colors
                                                                .textColor
                                                                .withValues(
                                                                    alpha: 0.7),
                                                          ),
                                                          hintText:
                                                              "Search Network",
                                                          contentPadding:
                                                              const EdgeInsets
                                                                  .all(0),
                                                        ),
                                                        SizedBox(
                                                          height: 10,
                                                        )
                                                      ],
                                                    ),
                                                    content: ListView.builder(
                                                        shrinkWrap: true,
                                                        itemCount: ecosystemNetworks
                                                            .where((e) => e.name
                                                                .toLowerCase()
                                                                .contains(
                                                                    ecosystemChainsController
                                                                        .text))
                                                            .toList()
                                                            .length,
                                                        itemBuilder:
                                                            (ctx, index) {
                                                          final filteredNetworks =
                                                              ecosystemNetworks
                                                                  .where((e) => e
                                                                      .name
                                                                      .toLowerCase()
                                                                      .contains(
                                                                          ecosystemChainsController
                                                                              .text))
                                                                  .toList()
                                                                ..sort((a, b) => a
                                                                    .name
                                                                    .compareTo(b
                                                                        .name));

                                                          final net =
                                                              filteredNetworks[
                                                                  index];
                                                          return Padding(
                                                            padding:
                                                                const EdgeInsets
                                                                    .symmetric(
                                                                    vertical:
                                                                        4),
                                                            child: ListTile(
                                                              visualDensity:
                                                                  VisualDensity
                                                                      .compact,
                                                              onTap: () {
                                                                showTokenDetails(
                                                                    context:
                                                                        context,
                                                                    colors:
                                                                        colors,
                                                                    crypto:
                                                                        net);
                                                              },
                                                              leading:
                                                                  CryptoPicture(
                                                                      crypto:
                                                                          net,
                                                                      size: 30,
                                                                      colors:
                                                                          colors),
                                                              title: Text(
                                                                net.name,
                                                                style: textTheme.bodyMedium?.copyWith(
                                                                    fontSize:
                                                                        fontSizeOf(
                                                                            14),
                                                                    color: colors
                                                                        .textColor
                                                                        .withValues(
                                                                            alpha:
                                                                                0.9),
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w400),
                                                              ),
                                                            ),
                                                          );
                                                        }),
                                                  );
                                                });
                                              });
                                        },
                                        child: RichText(
                                          text: TextSpan(
                                            style:
                                                textTheme.bodyMedium?.copyWith(
                                              fontSize: fontSizeOf(12),
                                              color: colors.textColor
                                                  .withValues(alpha: 0.8),
                                            ),
                                            children: [
                                              TextSpan(
                                                  text:
                                                      "${ecosystem.name} and ${ecosystemNetworks.length - 1} "),
                                              TextSpan(
                                                text: "other Chains",
                                                style: TextStyle(
                                                  decoration:
                                                      TextDecoration.underline,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      )
                                    ],
                                  )
                                : null,
                            onTap: () {
                              Navigator.pop(context, ecosystem);
                            },
                          );
                        },
                      ),
                    ))
                  ],
                ),
              ));
        });
      });

  return response;
}
