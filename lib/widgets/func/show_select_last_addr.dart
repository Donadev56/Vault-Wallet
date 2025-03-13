import 'dart:convert';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:moonwallet/types/types.dart';
import 'package:moonwallet/utils/prefs.dart';
import 'package:moonwallet/widgets/barre.dart';
import 'package:moonwallet/widgets/crypto_picture.dart';

import '../../logger/logger.dart';

void showSelectLastAddr(
    {required BuildContext context,
    required PublicDataManager publicDataManager,
    required PublicData currentAccount,
    required AppColors colors,
    required TextEditingController addressController,
    required Crypto currentNetwork}) {
  showModalBottomSheet(
      backgroundColor: Colors.transparent,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
              topLeft: Radius.circular(30), topRight: Radius.circular(30))),
      context: context,
      builder: (BuildContext btmCtx) {
        return StatefulBuilder(
            builder: (BuildContext stateFCtx, setModalState) {
          Future<List<dynamic>> getAddress() async {
            try {
              final lastUsedAddresses =
                  await publicDataManager.getDataFromPrefs(
                      key: "${currentAccount.address}/lastUsedAddresses");
              log("last address $lastUsedAddresses");
              if (lastUsedAddresses != null) {
                return (json.decode(lastUsedAddresses) as List<dynamic>)
                    .toSet()
                    .toList();
              } else {
                return [];
              }
            } catch (e) {
              logError(e.toString());
              return [];
            }
          }

          return BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
            child: Container(
                decoration: BoxDecoration(
                    color: colors.primaryColor,
                    borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(30),
                        topRight: Radius.circular(30))),
                child: Column(
                  children: [
                    DraggableBar(colors: colors),
                    SingleChildScrollView(
                      child: SizedBox(
                        height: MediaQuery.of(btmCtx).size.height * 0.46,
                        child: FutureBuilder(
                            future: getAddress(),
                            builder:
                                (BuildContext ftrCtx, AsyncSnapshot result) {
                              if (result.hasData) {
                                return ListView.builder(
                                    itemCount: result.data.length,
                                    itemBuilder: (BuildContext listCtx, index) {
                                      final addr = result.data[index];
                                      return Material(
                                        color: Colors.transparent,
                                        child: ListTile(
                                          onTap: () {
                                            addressController.text = addr;
                                            Navigator.pop(context);
                                          },
                                          leading: CryptoPicture(
                                              crypto: currentNetwork,
                                              size: 30,
                                              colors: colors),
                                          title: Text(
                                            "${(addr as String).substring(0, 10)}...${(addr).substring(addr.length - 10, addr.length)}",
                                            style: GoogleFonts.roboto(
                                                color: colors.textColor
                                                    .withOpacity(0.7)),
                                          ),
                                          trailing: IconButton(
                                              onPressed: () {
                                                Clipboard.setData(
                                                    ClipboardData(text: addr));
                                              },
                                              icon: Icon(
                                                LucideIcons.clipboard,
                                                color: colors.textColor,
                                              )),
                                        ),
                                      );
                                    });
                              } else {
                                return Center(
                                  child: Text(
                                    "No addresses found",
                                    style: GoogleFonts.roboto(
                                        color: colors.textColor),
                                  ),
                                );
                              }
                            }),
                      ),
                    )
                  ],
                )),
          );
        });
      });
}
