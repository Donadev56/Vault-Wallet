import 'package:flutter/material.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:moonwallet/types/account_related_types.dart';
import 'package:moonwallet/types/types.dart';
import 'package:moonwallet/widgets/dialogs/search_modal_header.dart';
import 'package:moonwallet/widgets/dialogs/standard_container.dart';
import 'package:moonwallet/widgets/screen_widgets/crypto_picture.dart';

Future<Crypto?> showSelectNetworkModal(
    {required BuildContext context,
    String title = "Select Network",
    required AppColors colors,
    required DoubleFactor roundedOf,
    required DoubleFactor fontSizeOf,
    required DoubleFactor iconSizeOf,
    required List<Crypto> networks}) {
  final controller = TextEditingController();

  List<Crypto> getListCrypto() {
    return networks
        .where((e) =>
            e.name.toLowerCase().contains(controller.text.toLowerCase()) ||
            e.symbol.toLowerCase().contains(controller.text.toLowerCase()))
        .toList();
  }

  final response = showCupertinoModalBottomSheet<Crypto>(
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
                        itemCount: getListCrypto()
                            .where((crypto) => crypto.isNative)
                            .length,
                        itemBuilder: (ctx, i) {
                          final crypto = getListCrypto()
                              .where((crypto) => crypto.isNative)
                              .toList()[i];
                          return ListTile(
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                            leading: CryptoPicture(
                                crypto: crypto,
                                size: iconSizeOf(30),
                                colors: colors),
                            title: Text(crypto.name,
                                style: textTheme.bodyMedium?.copyWith(
                                    color: colors.textColor,
                                    fontWeight: FontWeight.w400)),
                            onTap: () {
                              Navigator.pop(context, crypto);
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
