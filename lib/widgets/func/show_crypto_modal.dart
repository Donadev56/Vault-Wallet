// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:moonwallet/types/types.dart';
import 'package:moonwallet/widgets/crypto_picture.dart';

void showCryptoModal(
    {required BuildContext context,
    required AppColors colors,
    required Color primaryColor,
    required Color textColor,
    required Color surfaceTintColor,
    required List<Crypto> reorganizedCrypto,
    required String route}) {
  showBarModalBottomSheet(
      backgroundColor: colors.primaryColor,
      isDismissible: true,
      duration: const Duration(
        milliseconds: 200,
      ),
      closeProgressThreshold: 0.2,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
              topLeft: Radius.circular(30), topRight: Radius.circular(30))),
      context: context,
      builder: (BuildContext btmCtx) {
        String searchQuery = "";

        return StatefulBuilder(builder: (ctx, setLocalState) {
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
                      label: Text("Search crypto"),
                      labelStyle:
                          GoogleFonts.roboto(color: textColor.withOpacity(0.7)),
                      filled: true,
                      fillColor: surfaceTintColor.withOpacity(0.15),
                      prefixIcon: Icon(
                        Icons.search,
                        color: textColor.withOpacity(0.5),
                      ),
                      enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide:
                              BorderSide(width: 0, color: Colors.transparent)),
                      focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
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
                            Navigator.pushNamed(context, route,
                                arguments: ({"id": net.cryptoId}));
                          },
                          leading: CryptoPicture(
                              crypto: net, size: 35, colors: colors),
                          title: Row(
                            spacing: 10,
                            children: [
                              Text(
                                net.symbol,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.roboto(
                                  color: textColor,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (net.type == CryptoType.token)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 2),
                                  decoration: BoxDecoration(
                                      color: surfaceTintColor.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(20)),
                                  child: Text(
                                    "${net.network?.name}",
                                    style: GoogleFonts.roboto(
                                        color: textColor.withOpacity(0.8),
                                        fontSize: 10),
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
