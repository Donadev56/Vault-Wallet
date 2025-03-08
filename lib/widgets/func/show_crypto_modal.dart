// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:moonwallet/types/types.dart';

void showCryptoModal(
    {required BuildContext context,
    required Color primaryColor,
    required Color textColor,
    required Color surfaceTintColor,
    required List<Crypto> reorganizedCrypto,
    required String route}) {
  showModalBottomSheet(
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
              topLeft: Radius.circular(30), topRight: Radius.circular(30))),
      isScrollControlled: true,
      context: context,
      builder: (BuildContext btmCtx) {
        String searchQuery = "";

        return StatefulBuilder(builder: (ctx, setLocalState) {
          return Container(
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height * 0.8,
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
                color: primaryColor,
                borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30))),
            child: Column(
              children: [
                TextField(
                  onChanged: (v) {
                    setLocalState(() {
                      searchQuery = v;
                    });
                  },
                  maxLines: 1,
                  minLines: 1,
                  scrollPadding: const EdgeInsets.all(10),
                  decoration: InputDecoration(
                    contentPadding:
                        const EdgeInsets.symmetric(vertical: 6, horizontal: 6),
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
                ),
                SizedBox(
                  height: 10,
                ),
                SingleChildScrollView(
                    child: SizedBox(
                  height: MediaQuery.of(btmCtx).size.height * 0.68,
                  child: ListView.builder(
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
                            leading: ClipRRect(
                              borderRadius: BorderRadius.circular(50),
                              child: net.icon == null
                                  ? Container(
                                      width: 35,
                                      height: 35,
                                      decoration: BoxDecoration(
                                          color: textColor.withOpacity(0.6),
                                          borderRadius:
                                              BorderRadius.circular(50)),
                                      child: Center(
                                        child: Text(
                                          net.symbol.length > 2
                                              ? net.symbol.substring(0, 2)
                                              : net.symbol,
                                          style: GoogleFonts.roboto(
                                              color: primaryColor,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 18),
                                        ),
                                      ),
                                    )
                                  : Image.asset(
                                      net.icon ?? "",
                                      width: 35,
                                      height: 35,
                                      fit: BoxFit.cover,
                                    ),
                            ),
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
                                        color:
                                            surfaceTintColor.withOpacity(0.2),
                                        borderRadius:
                                            BorderRadius.circular(20)),
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
                )),
              ],
            ),
          );
        });
      });
}
