// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:moonwallet/logger/logger.dart';
import 'package:moonwallet/types/types.dart';
import 'package:moonwallet/utils/constant.dart';
import 'package:url_launcher/url_launcher.dart';

class TransactionsListElement extends StatelessWidget {
  final Color surfaceTintColor;

  final bool isFrom;
  final BscScanTransaction tr;
  final AppColors colors ;
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
    final height = MediaQuery.of(context).size.height;
    return Material(
      color: Colors.transparent,
      child: ListTile(
        onTap: () {
          showModalBottomSheet(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.only(topLeft: Radius.circular(30), topRight: Radius.circular(30))
            ),
              isScrollControlled: true,
              context: context,
              builder: (BuildContext ctx) {
                return Container(
                  padding: const EdgeInsets.all(15),
                  height: height * 0.7,
                  decoration: BoxDecoration(
                    color: primaryColor,
                    borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(30),
                        topRight: Radius.circular(30)),
                  ),
                  child: Column(
                    children: [
                              Align(alignment: Alignment.center,
                            child: Container(
                              margin: const EdgeInsets.all(10),
                              height: 10,
                              width: 80,
                              decoration: BoxDecoration(
                                color: isFrom ?  colors.redColor.withOpacity(0.8) : colors.greenColor.withOpacity(0.8),
                                borderRadius: BorderRadius.circular(50)
                              ),

                            ),),
                  
                      SizedBox(
                        height: 15,
                      ),
                      Container(
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            color: surfaceTintColor.withOpacity(0.2)),
                        child: ListTile(
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20)),
                          leading: SizedBox(
                            width: 50,
                            height: 50,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(50),
                              child: currentNetwork.icon == null
                                  ? Container(
                                      width: 50,
                                      height: 50,
                                      decoration: BoxDecoration(
                                          color: textColor.withOpacity(0.6),
                                          borderRadius:
                                              BorderRadius.circular(50)),
                                      child: Center(
                                        child: Text(
                                          currentNetwork.symbol.length > 2
                                              ? currentNetwork.symbol
                                                  .substring(0, 2)
                                              : currentNetwork.symbol,
                                          style: GoogleFonts.roboto(
                                              color: primaryColor,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 18),
                                        ),
                                      ),
                                    )
                                  : Image.asset(
                                      currentNetwork.icon ?? "",
                                      width: 50,
                                      height: 50,
                                      fit: BoxFit.cover,
                                    ),
                            ),
                          ),
                          title: Text(
                            isFrom
                                ? "- ${BigInt.parse(tr.value).toDouble() / 1e18}"
                                : "+ ${BigInt.parse(tr.value).toDouble() / 1e18}",
                            style: GoogleFonts.roboto(
                                color: textColor, fontWeight: FontWeight.bold, fontSize: 21),
                          ),
                          subtitle: Text(
                            currentNetwork.symbol,
                            style: GoogleFonts.roboto(
                                color: textColor.withOpacity(0.3),
                                fontSize: 15,
                                fontWeight: FontWeight.normal),
                          ),
                        ),
                      ),
                      Container(
                        margin: const EdgeInsets.only(top: 10),
                        padding: const EdgeInsets.only(left: 20, right: 20),
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            color: surfaceTintColor.withOpacity(0.2)),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "From",
                                  style: GoogleFonts.roboto(
                                      color: textColor, fontSize: 14),
                                ),
                                Row(
                                  children: [
                                    Text(
                                      tr.from.length > 6
                                          ? "${tr.from.substring(0, 6)}...${tr.from.substring(tr.from.length - 6)}"
                                          : "...",
                                      style: GoogleFonts.roboto(
                                          color: textColor, fontSize: 14),
                                    ),
                                    SizedBox(
                                      width: 10,
                                    ),
                                    IconButton(
                                      onPressed: () {
                                        Clipboard.setData(
                                            ClipboardData(text: tr.from));
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
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "To",
                                  style: GoogleFonts.roboto(
                                      color: textColor, fontSize: 14),
                                ),
                                Row(
                                  children: [
                                    Text(
                                      tr.to.length > 6
                                          ? "${tr.to.substring(0, 6)}...${tr.to.substring(tr.to.length - 6)}"
                                          : "...",
                                      style: GoogleFonts.roboto(
                                          color: textColor, fontSize: 14),
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
                            )
                          ],
                        ),
                      ),
                      Container(
                        margin: const EdgeInsets.only(top: 10),
                        padding: const EdgeInsets.only(left: 20, right: 20),
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            color: surfaceTintColor.withOpacity(0.2)),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "Hash",
                                  style: GoogleFonts.roboto(
                                      color: textColor, fontSize: 14),
                                ),
                                Row(
                                  children: [
                                    Text(
                                      tr.hash.length > 6
                                          ? "${tr.hash.substring(0, 6)}...${tr.hash.substring(tr.hash.length - 6)}"
                                          : "...",
                                      style: GoogleFonts.roboto(
                                          color: textColor, fontSize: 14),
                                    ),
                                    SizedBox(
                                      width: 10,
                                    ),
                                    IconButton(
                                      onPressed: () {
                                        Clipboard.setData(
                                            ClipboardData(text: tr.hash));
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
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "Block",
                                  style: GoogleFonts.roboto(
                                      color: textColor, fontSize: 14),
                                ),
                                Row(
                                  children: [
                                    Text(
                                      tr.blockNumber,
                                      style: GoogleFonts.roboto(
                                          color: textColor, fontSize: 14),
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
                                "${currentNetwork.type == CryptoType.token ? currentNetwork.network?.explorer :  currentNetwork.explorer}/tx/${tr.hash}";
                            log("The url is $url");
                            await launchUrl(Uri.parse(url));
                          },
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                                color: surfaceTintColor.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(10)),
                            child: Center(
                              child: Text(
                                "View on Blockchain explorer",
                                style: GoogleFonts.roboto(color: textColor),
                              ),
                            ),
                          ),
                        ),
                      )
                    ],
                  ),
                );
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
            Text(
              formatTimeElapsed(int.parse(tr.timeStamp)),
              style: GoogleFonts.roboto(
                  color: textColor.withOpacity(0.5), fontSize: 12),
            )
          ],
        ),
      ),
    );
  }
}
