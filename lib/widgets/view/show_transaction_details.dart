import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:moonwallet/logger/logger.dart';
import 'package:moonwallet/types/types.dart';
import 'package:moonwallet/utils/constant.dart';
import 'package:moonwallet/utils/share_manager.dart';
import 'package:moonwallet/widgets/screen_widgets/crypto_picture.dart';
import 'package:moonwallet/widgets/view/details_container.dart';
import 'package:timer_builder/timer_builder.dart';
import 'package:url_launcher/url_launcher.dart';

void showTransactionDetails(
    {required BuildContext context,
    required AppColors colors,
    required String address,
    required bool isFrom,
    required TransactionDetails tr,
    required Crypto currentNetwork}) {
  final textTheme = Theme.of(context).textTheme;

  showMaterialModalBottomSheet(
      backgroundColor: colors.primaryColor,
      context: context,
      builder: (BuildContext ctx) {
        final amount = tr.value;
        return SafeArea(
            child: Scaffold(
          backgroundColor: colors.primaryColor,
          appBar: AppBar(
            leading: IconButton(
              icon: Icon(
                Icons.arrow_back,
                color: colors.textColor.withOpacity(0.7),
              ),
              onPressed: () {
                Navigator.pop(ctx);
              },
            ),
            backgroundColor: colors.primaryColor,
            centerTitle: true,
            title: Text(
              isFrom ? "Transfer" : "Receive",
              style: textTheme.headlineSmall?.copyWith(
                  color: colors.textColor.withOpacity(0.7), fontSize: 20),
            ),
          ),
          body: ConstrainedBox(
              constraints: BoxConstraints(
                  minHeight: MediaQuery.of(context).size.height * 0.8),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: colors.primaryColor,
                  borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30)),
                ),
                child: ListView(
                  children: [
                    DetailsContainer(
                      colors: colors,
                      child: ListTile(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20)),
                        leading: SizedBox(
                          child: CryptoPicture(
                              crypto: currentNetwork, size: 50, colors: colors),
                        ),
                        title: Text(
                          isFrom ? "- $amount" : "+ $amount",
                          style: textTheme.bodyMedium?.copyWith(
                              color: colors.textColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 17),
                        ),
                        subtitle: Text(
                          currentNetwork.symbol,
                          style: textTheme.bodySmall?.copyWith(
                              color: colors.textColor.withOpacity(0.3),
                              fontSize: 15,
                              fontWeight: FontWeight.normal),
                        ),
                      ),
                    ),
                    DetailsContainer(
                      colors: colors,
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "From",
                                style: textTheme.bodyMedium?.copyWith(
                                    color: colors.textColor, fontSize: 14),
                              ),
                              Row(
                                children: [
                                  Text(
                                    tr.from.length > 6
                                        ? "${tr.from.substring(0, 6)}...${tr.from.substring(tr.from.length - 6)}"
                                        : "...",
                                    style: textTheme.bodyMedium?.copyWith(
                                        color: colors.textColor, fontSize: 14),
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
                                      color: colors.textColor,
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
                                style: textTheme.bodyMedium?.copyWith(
                                    color: colors.textColor, fontSize: 14),
                              ),
                              Row(
                                children: [
                                  Text(
                                    tr.to.length > 6
                                        ? "${tr.to.substring(0, 6)}...${tr.to.substring(tr.to.length - 6)}"
                                        : "...",
                                    style: textTheme.bodyMedium?.copyWith(
                                        color: colors.textColor, fontSize: 14),
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
                                      color: colors.textColor,
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
                                "Time",
                                style: textTheme.bodyMedium?.copyWith(
                                    color: colors.textColor, fontSize: 14),
                              ),
                              Row(
                                children: [
                                  TimerBuilder.periodic(
                                    Duration(seconds: 5),
                                    builder: (ctx) {
                                      return Text(
                                        formatTimeElapsed(
                                            int.parse(tr.timeStamp)),
                                        style: textTheme.bodyMedium?.copyWith(
                                            color: colors.textColor
                                                .withOpacity(0.5),
                                            fontSize: 12),
                                      );
                                    },
                                  ),
                                  SizedBox(
                                    width: 10,
                                  ),
                                  IconButton(
                                    onPressed: () {
                                      Clipboard.setData(
                                          ClipboardData(text: tr.timeStamp));
                                    },
                                    icon: Icon(
                                      LucideIcons.copy,
                                      color: colors.textColor,
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
                    DetailsContainer(
                      colors: colors,
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "Hash",
                                style: textTheme.bodyMedium?.copyWith(
                                    color: colors.textColor, fontSize: 14),
                              ),
                              Row(
                                children: [
                                  Text(
                                    tr.hash.length > 6
                                        ? "${tr.hash.substring(0, 6)}...${tr.hash.substring(tr.hash.length - 6)}"
                                        : "...",
                                    style: textTheme.bodyMedium?.copyWith(
                                        color: colors.textColor, fontSize: 14),
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
                                      color: colors.textColor,
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
                                style: textTheme.bodyMedium?.copyWith(
                                    color: colors.textColor, fontSize: 14),
                              ),
                              Row(
                                children: [
                                  Text(
                                    tr.blockNumber,
                                    style: textTheme.bodyMedium?.copyWith(
                                        color: colors.textColor, fontSize: 14),
                                  ),
                                  SizedBox(
                                    width: 10,
                                  ),
                                  IconButton(
                                    onPressed: () {
                                      Clipboard.setData(
                                          ClipboardData(text: tr.blockNumber));
                                    },
                                    icon: Icon(
                                      LucideIcons.copy,
                                      color: colors.textColor,
                                      size: 20,
                                    ),
                                    padding: const EdgeInsets.all(0),
                                  )
                                ],
                              ),
                            ],
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "Status",
                                style: textTheme.bodyMedium?.copyWith(
                                    color: colors.textColor, fontSize: 14),
                              ),
                              Row(
                                children: [
                                  Text(
                                    tr.status,
                                    style: textTheme.bodyMedium?.copyWith(
                                        color: colors.textColor, fontSize: 14),
                                  ),
                                  SizedBox(
                                    width: 10,
                                  ),
                                  IconButton(
                                    onPressed: () {
                                      Clipboard.setData(
                                          ClipboardData(text: tr.status));
                                    },
                                    icon: Icon(
                                      LucideIcons.copy,
                                      color: colors.textColor,
                                      size: 20,
                                    ),
                                    padding: const EdgeInsets.all(0),
                                  )
                                ],
                              ),
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
                              "${!currentNetwork.isNative ? currentNetwork.network?.explorers![0] : currentNetwork.explorers![0]}/tx/${tr.hash}";
                          log("The url is $url");
                          await launchUrl(Uri.parse(url));
                        },
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                              color: colors.secondaryColor,
                              borderRadius: BorderRadius.circular(10)),
                          child: Center(
                            child: Text(
                              "View on Blockchain explorer",
                              style: textTheme.bodyMedium
                                  ?.copyWith(color: colors.textColor),
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(
                      height: 20,
                    ),
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(10),
                        onTap: () async {
                          final text =
                              "${!currentNetwork.isNative ? currentNetwork.network?.explorers![0] : currentNetwork.explorers![0]}/tx/${tr.hash}";
                          ShareManager().shareText(
                              text: text, subject: "Share Transaction Hash");
                        },
                        child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                                color: colors.themeColor.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(10)),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                Icon(
                                  LucideIcons.externalLink,
                                  color: colors.themeColor,
                                ),
                                Text(
                                  "Share transaction hash",
                                  style: textTheme.bodyMedium
                                      ?.copyWith(color: colors.themeColor),
                                )
                              ],
                            )),
                      ),
                    )
                  ],
                ),
              )),
        ));
      });
}
