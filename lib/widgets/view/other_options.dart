import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:moonwallet/types/types.dart';
import 'package:moonwallet/widgets/crypto_picture.dart';
import 'package:url_launcher/url_launcher.dart';

void showOtherOptions(
    {required BuildContext context,
    required AppColors colors,
    required Crypto currentCrypto}) async {
  showMaterialModalBottomSheet(
      backgroundColor: Colors.transparent,
      context: context,
      builder: (ctx) {
        final width = MediaQuery.of(context).size.width;

        return Material(
            color: Colors.transparent,
            child: Container(
              decoration: BoxDecoration(
                color: colors.primaryColor,
                borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(15),
                    topRight: Radius.circular(15)),
              ),
              child: ListView(
                shrinkWrap: true,
                children: [
                  ListTile(
                    leading: CryptoPicture(
                        crypto: currentCrypto, size: 40, colors: colors),
                    title: Text(
                      currentCrypto.symbol,
                      style: GoogleFonts.roboto(
                          color: colors.textColor, fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      currentCrypto.name,
                      style: GoogleFonts.roboto(
                          color: colors.textColor.withOpacity(0.5)),
                    ),
                    trailing: IconButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        icon: Icon(
                          LucideIcons.x,
                          color: colors.grayColor,
                        )),
                  ),
                  Divider(
                    color: colors.textColor.withOpacity(0.1),
                  ),
                  SizedBox(
                    height: 15,
                  ),
                  Column(
                    spacing: 20,
                    children: [
                      Align(
                        alignment: Alignment.center,
                        child: Container(
                            decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(5),
                                color: colors.grayColor.withOpacity(0.25)),
                            width: width * 0.9,
                            child: Column(
                              children: [
                                ListTile(
                                  onTap: () {},
                                  leading: Icon(
                                    LucideIcons.network,
                                    color: colors.textColor,
                                  ),
                                  title: Text(
                                    "Network",
                                    style: GoogleFonts.roboto(
                                        color: colors.textColor),
                                  ),
                                  trailing: Text(
                                    "${currentCrypto.type == CryptoType.network ? currentCrypto.name : currentCrypto.network?.name}",
                                    style: GoogleFonts.roboto(
                                        color:
                                            colors.textColor.withOpacity(0.5)),
                                  ),
                                ),
                                ListTile(
                                  onTap: () {
                                    if (currentCrypto.type ==
                                        CryptoType.network) return;
                                    Clipboard.setData(ClipboardData(
                                        text: currentCrypto.contractAddress ??
                                            ""));
                                  },
                                  leading: Icon(
                                    LucideIcons.scrollText,
                                    color: colors.textColor,
                                  ),
                                  title: Text(
                                    "Contract",
                                    style: GoogleFonts.roboto(
                                        color: colors.textColor),
                                  ),
                                  trailing: Text(
                                    "${currentCrypto.contractAddress != null ? currentCrypto.contractAddress!.length > 10 ? currentCrypto.contractAddress?.substring(0, 10) : "" : ""}...",
                                    style: GoogleFonts.roboto(
                                        color:
                                            colors.textColor.withOpacity(0.5)),
                                  ),
                                ),
                              ],
                            )),
                      ),
                      Align(
                        alignment: Alignment.center,
                        child: Container(
                            decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(5),
                                color: colors.grayColor.withOpacity(0.25)),
                            width: width * 0.9,
                            child: Column(
                              children: [
                                ListTile(
                                    onTap: () {
                                      if (currentCrypto.type ==
                                          CryptoType.token) {
                                        launchUrl(Uri.parse(
                                            '${currentCrypto.network?.explorer}/address/${currentCrypto.contractAddress}'));
                                      } else {
                                        launchUrl(Uri.parse(
                                            '${currentCrypto.explorer}'));
                                      }
                                    },
                                    leading: Icon(
                                      LucideIcons.scrollText,
                                      color: colors.textColor,
                                    ),
                                    title: Text(
                                      "View on Explorer",
                                      style: GoogleFonts.roboto(
                                          color: colors.textColor),
                                    ),
                                    trailing: Icon(
                                      Icons.chevron_right,
                                      color: colors.textColor.withOpacity(0.5),
                                    )),
                              ],
                            )),
                      ),
                      SizedBox(
                        height: 15,
                      ),
                    ],
                  ),
                  SizedBox(
                    height: 10,
                  )
                ],
              ),
            ));
      });
}
