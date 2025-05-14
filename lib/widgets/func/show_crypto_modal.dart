// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:moonwallet/types/account_related_types.dart';
import 'package:moonwallet/types/types.dart';
import 'package:moonwallet/widgets/dialogs/standard_container.dart';
import 'package:moonwallet/widgets/screen_widgets/crypto_picture.dart';

typedef DoubleFactor = double Function(double size);

void showCryptoModal(
    {required DoubleFactor roundedOf,
    required DoubleFactor fontSizeOf,
    required DoubleFactor iconSizeOf,
    required DoubleFactor imageSizeOf,
    required DoubleFactor listTitleHorizontalOf,
    required DoubleFactor listTitleVerticalOf,
    required BuildContext context,
    required AppColors colors,
    required Color primaryColor,
    required Color textColor,
    required Color surfaceTintColor,
    required List<Crypto> reorganizedCrypto,
    required void Function(Crypto crypto) onSelect}) {
  String searchQuery = "";

  showMaterialModalBottomSheet(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      context: context,
      builder: (BuildContext btmCtx) {
        return StatefulBuilder(builder: (ctx, setLocalState) {
          final textTheme = Theme.of(context).textTheme;

          return StandardContainer(
              backgroundColor: colors.primaryColor,
              child: SafeArea(
                  child: Material(
                color: Colors.transparent,
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      child: TextField(
                        onChanged: (v) {
                          setLocalState(() {
                            searchQuery = v;
                          });
                        },
                        maxLines: 1,
                        minLines: 1,
                        scrollPadding: const EdgeInsets.all(10),
                        decoration: InputDecoration(
                          contentPadding: const EdgeInsets.symmetric(
                              vertical: 6, horizontal: 6),
                          label: Text(
                            "Search crypto",
                            style: textTheme.bodyMedium
                                ?.copyWith(color: colors.textColor),
                          ),
                          labelStyle: textTheme.bodyMedium
                              ?.copyWith(color: textColor.withOpacity(0.7)),
                          filled: true,
                          fillColor: colors.secondaryColor,
                          prefixIcon: Icon(
                            Icons.search,
                            color: textColor.withOpacity(0.5),
                          ),
                          enabledBorder: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.circular(roundedOf(10)),
                              borderSide: BorderSide(
                                  width: 0, color: Colors.transparent)),
                          focusedBorder: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.circular(roundedOf(10)),
                              borderSide: BorderSide(
                                  width: 0, color: Colors.transparent)),
                        ),
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: reorganizedCrypto
                              .where((c) => c.symbol
                                  .toLowerCase()
                                  .contains(searchQuery.toLowerCase()))
                              .length,
                          itemBuilder: (BuildContext lisCryptoCtx, int index) {
                            final coin = reorganizedCrypto
                                .where((c) => c.symbol
                                    .toLowerCase()
                                    .contains(searchQuery.toLowerCase()))
                                .toList()[index];
                            return Material(
                              color: Colors.transparent,
                              child: ListTile(
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(50)),
                                onTap: () {
                                  onSelect(coin);
                                },
                                leading: CryptoPicture(
                                    crypto: coin,
                                    size: imageSizeOf(35),
                                    colors: colors),
                                title: Text(
                                  coin.symbol,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: textTheme.bodyMedium?.copyWith(
                                    color: textColor,
                                    fontWeight: FontWeight.w500,
                                    fontSize: fontSizeOf(14),
                                  ),
                                ),
                                subtitle: Text(
                                  (coin.isNative
                                      ? coin.name
                                      : (coin.network?.name ??
                                          "Unknown network")),
                                  style: textTheme.bodyMedium?.copyWith(
                                      color: colors.textColor
                                          .withValues(alpha: 0.8),
                                      fontSize: fontSizeOf(12)),
                                ),
                              ),
                            );
                          }),
                    )
                  ],
                ),
              )));
        });
      });
}
