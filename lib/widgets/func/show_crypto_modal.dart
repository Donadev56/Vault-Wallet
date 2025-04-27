// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:moonwallet/types/types.dart';
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

  showBarModalBottomSheet(
      backgroundColor: colors.primaryColor,
      isDismissible: true,
      context: context,
      builder: (BuildContext btmCtx) {
        return StatefulBuilder(builder: (ctx, setLocalState) {
          final textTheme = Theme.of(context).textTheme;

          return Column(
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
                      fillColor: surfaceTintColor.withOpacity(0.15),
                      prefixIcon: Icon(
                        Icons.search,
                        color: textColor.withOpacity(0.5),
                      ),
                      enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(roundedOf(10)),
                          borderSide:
                              BorderSide(width: 0, color: Colors.transparent)),
                      focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(roundedOf(10)),
                          borderSide:
                              BorderSide(width: 0, color: Colors.transparent)),
                    ),
                  )),
              Expanded(
                child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: reorganizedCrypto
                        .where((c) => c.symbol
                            .toLowerCase()
                            .contains(searchQuery.toLowerCase()))
                        .length,
                    itemBuilder: (BuildContext lisCryptoCtx, int index) {
                      final net = reorganizedCrypto
                          .where((c) => c.symbol
                              .toLowerCase()
                              .contains(searchQuery.toLowerCase()))
                          .toList()[index];
                      return Material(
                        color: Colors.transparent,
                        child: ListTile(
                          onTap: () {
                            onSelect(net);
                          },
                          leading: CryptoPicture(
                              crypto: net,
                              size: imageSizeOf(35),
                              colors: colors),
                          title: Row(
                            spacing: 10,
                            children: [
                              Text(
                                net.symbol,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: textTheme.bodyMedium?.copyWith(
                                  color: textColor,
                                  fontSize: fontSizeOf(16),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 2),
                                decoration: BoxDecoration(
                                    color: surfaceTintColor.withOpacity(0.2),
                                    borderRadius:
                                        BorderRadius.circular(roundedOf(20))),
                                child: Text(
                                  net.type == CryptoType.token
                                      ? "${net.network?.name}"
                                      : net.name,
                                  style: textTheme.bodySmall?.copyWith(
                                    color: textColor.withOpacity(0.8),
                                  ),
                                ),
                              )
                            ],
                          ),
                        ),
                      );
                    }),
              )
            ],
          );
        });
      });
}
