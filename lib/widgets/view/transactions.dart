// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:moonwallet/logger/logger.dart';
import 'package:moonwallet/types/types.dart';
import 'package:moonwallet/utils/constant.dart';
import 'package:moonwallet/widgets/crypto_picture.dart';
import 'package:timer_builder/timer_builder.dart';
import 'package:url_launcher/url_launcher.dart';

class TransactionsListElement extends StatelessWidget {
  final Color surfaceTintColor;

  final bool isFrom;
  final EsTransaction tr;
  final AppColors colors;
  final Color textColor;
  final Color secondaryColor;
  final Color primaryColor;
  final Color darkColor;
  final Crypto currentNetwork;
  const TransactionsListElement({
    super.key,
    required this.surfaceTintColor,
    required this.isFrom,
    required this.tr,
    required this.textColor,
    required this.secondaryColor,
    required this.primaryColor,
    required this.darkColor,
    required this.currentNetwork,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: ListTile(
        onTap: () {
          showBarModalBottomSheet(
              backgroundColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20))),
              context: context,
              builder: (BuildContext ctx) {
                return SafeArea(
                    child: ConstrainedBox(
                        constraints: BoxConstraints(
                            minHeight:
                                MediaQuery.of(context).size.height * 0.8),
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: primaryColor,
                            borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(30),
                                topRight: Radius.circular(30)),
                          ),
                          child: ListView(
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(20),
                                    color: surfaceTintColor.withOpacity(0.2)),
                                child: ListTile(
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20)),
                                  leading: SizedBox(
                                    child: CryptoPicture(
                                        crypto: currentNetwork,
                                        size: 50,
                                        colors: colors),
                                  ),
                                  title: Text(
                                    isFrom
                                        ? "- ${BigInt.parse(tr.value).toDouble() / 1e18}"
                                        : "+ ${BigInt.parse(tr.value).toDouble() / 1e18}",
                                    style: GoogleFonts.manrope(
                                        color: textColor,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 21),
                                  ),
                                  subtitle: Text(
                                    currentNetwork.symbol,
                                    style: GoogleFonts.manrope(
                                        color: textColor.withOpacity(0.3),
                                        fontSize: 15,
                                        fontWeight: FontWeight.normal),
                                  ),
                                ),
                              ),
                              Container(
                                margin: const EdgeInsets.only(top: 10),
                                padding:
                                    const EdgeInsets.only(left: 20, right: 20),
                                decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(20),
                                    color: surfaceTintColor.withOpacity(0.2)),
                                child: Column(
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          "From",
                                          style: GoogleFonts.manrope(
                                              color: textColor, fontSize: 14),
                                        ),
                                        Row(
                                          children: [
                                            Text(
                                              tr.from.length > 6
                                                  ? "${tr.from.substring(0, 6)}...${tr.from.substring(tr.from.length - 6)}"
                                                  : "...",
                                              style: GoogleFonts.manrope(
                                                  color: textColor,
                                                  fontSize: 14),
                                            ),
                                            SizedBox(
                                              width: 10,
                                            ),
                                            IconButton(
                                              onPressed: () {
                                                Clipboard.setData(ClipboardData(
                                                    text: tr.from));
                                              },
                                              icon: Icon(
                                                LucideIcons.copy,
                                                color: textColor,
                                                size: 20,
                                              ),
                                              padding: const EdgeInsets.all(0),
                                            )
                                          ],
                                        )
                                      ],
                                    ),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          "To",
                                          style: GoogleFonts.manrope(
                                              color: textColor, fontSize: 14),
                                        ),
                                        Row(
                                          children: [
                                            Text(
                                              tr.to.length > 6
                                                  ? "${tr.to.substring(0, 6)}...${tr.to.substring(tr.to.length - 6)}"
                                                  : "...",
                                              style: GoogleFonts.manrope(
                                                  color: textColor,
                                                  fontSize: 14),
                                            ),
                                            SizedBox(
                                              width: 10,
                                            ),
                                            IconButton(
                                              onPressed: () {
                                                Clipboard.setData(
                                                    ClipboardData(text: tr.to));
                                              },
                                              icon: Icon(
                                                LucideIcons.copy,
                                                color: textColor,
                                                size: 20,
                                              ),
                                              padding: const EdgeInsets.all(0),
                                            )
                                          ],
                                        )
                                      ],
                                    ),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          "Time",
                                          style: GoogleFonts.manrope(
                                              color: textColor, fontSize: 14),
                                        ),
                                        Row(
                                          children: [
                                            Text(
                                              formatTimeElapsed(
                                                  int.parse(tr.timeStamp)),
                                              style: GoogleFonts.manrope(
                                                  color: textColor,
                                                  fontSize: 14),
                                            ),
                                            SizedBox(
                                              width: 10,
                                            ),
                                            IconButton(
                                              onPressed: () {
                                                Clipboard.setData(ClipboardData(
                                                    text: tr.timeStamp));
                                              },
                                              icon: Icon(
                                                LucideIcons.copy,
                                                color: textColor,
                                                size: 20,
                                              ),
                                              padding: const EdgeInsets.all(0),
                                            )
                                          ],
                                        )
                                      ],
                                    )
                                  ],
                                ),
                              ),
                              Container(
                                margin: const EdgeInsets.only(top: 10),
                                padding:
                                    const EdgeInsets.only(left: 20, right: 20),
                                decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(20),
                                    color: surfaceTintColor.withOpacity(0.2)),
                                child: Column(
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          "Hash",
                                          style: GoogleFonts.manrope(
                                              color: textColor, fontSize: 14),
                                        ),
                                        Row(
                                          children: [
                                            Text(
                                              tr.hash.length > 6
                                                  ? "${tr.hash.substring(0, 6)}...${tr.hash.substring(tr.hash.length - 6)}"
                                                  : "...",
                                              style: GoogleFonts.manrope(
                                                  color: textColor,
                                                  fontSize: 14),
                                            ),
                                            SizedBox(
                                              width: 10,
                                            ),
                                            IconButton(
                                              onPressed: () {
                                                Clipboard.setData(ClipboardData(
                                                    text: tr.hash));
                                              },
                                              icon: Icon(
                                                LucideIcons.copy,
                                                color: textColor,
                                                size: 20,
                                              ),
                                              padding: const EdgeInsets.all(0),
                                            )
                                          ],
                                        )
                                      ],
                                    ),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          "Block",
                                          style: GoogleFonts.manrope(
                                              color: textColor, fontSize: 14),
                                        ),
                                        Row(
                                          children: [
                                            Text(
                                              tr.blockNumber,
                                              style: GoogleFonts.manrope(
                                                  color: textColor,
                                                  fontSize: 14),
                                            ),
                                            SizedBox(
                                              width: 10,
                                            ),
                                            IconButton(
                                              onPressed: () {
                                                Clipboard.setData(ClipboardData(
                                                    text: tr.blockNumber));
                                              },
                                              icon: Icon(
                                                LucideIcons.copy,
                                                color: textColor,
                                                size: 20,
                                              ),
                                              padding: const EdgeInsets.all(0),
                                            )
                                          ],
                                        )
                                      ],
                                    )
                                  ],
                                ),
                              ),
                              SizedBox(
                                height: 30,
                              ),
                              Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(10),
                                  onTap: () async {
                                    final url =
                                        "${currentNetwork.type == CryptoType.token ? currentNetwork.network?.explorer : currentNetwork.explorer}/tx/${tr.hash}";
                                    log("The url is $url");
                                    await launchUrl(Uri.parse(url));
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                        color:
                                            surfaceTintColor.withOpacity(0.2),
                                        borderRadius:
                                            BorderRadius.circular(10)),
                                    child: Center(
                                      child: Text(
                                        "View on Blockchain explorer",
                                        style: GoogleFonts.manrope(
                                            color: textColor),
                                      ),
                                    ),
                                  ),
                                ),
                              )
                            ],
                          ),
                        )));
              });
        },
        leading: Container(
          height: 35,
          width: 35,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
              color: surfaceTintColor.withOpacity(0.3),
              borderRadius: BorderRadius.circular(50)),
          child: Icon(
            isFrom ? FeatherIcons.arrowUpRight : FeatherIcons.arrowDown,
            size: 15,
            color: isFrom ? textColor.withOpacity(0.4) : secondaryColor,
          ),
        ),
        title: Text(
          isFrom ? "Send" : "Receive",
          style: GoogleFonts.roboto(
              color: textColor, fontWeight: FontWeight.bold, fontSize: 15),
        ),
        subtitle: Text(
            isFrom
                ? tr.to.length > 6
                    ? "To : ${tr.to.substring(0, 6)}...${tr.to.substring(tr.to.length - 6, tr.to.length)}"
                    : "To : ...."
                : tr.from.length > 6
                    ? "From : ${tr.from.substring(0, 6)}... ${tr.from.substring(tr.from.length - 6, tr.from.length)}"
                    : "From : ...",
            style: GoogleFonts.roboto(
                color: textColor.withOpacity(0.4), fontSize: 12)),
        trailing: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              isFrom
                  ? "- ${BigInt.parse(tr.value).toDouble() / 1e18}"
                  : "+ ${BigInt.parse(tr.value).toDouble() / 1e18}",
              style: GoogleFonts.roboto(
                  color: textColor, fontWeight: FontWeight.bold),
            ),
            TimerBuilder.periodic(
              Duration(seconds: 5),
              builder: (ctx) {
                return Text(
                  formatTimeElapsed(int.parse(tr.timeStamp)),
                  style: GoogleFonts.roboto(
                      color: textColor.withOpacity(0.5), fontSize: 12),
                );
              },
            )
          ],
        ),
      ),
    );
  }
}
