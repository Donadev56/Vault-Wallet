import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:moonwallet/custom/web3_webview/lib/web3_webview.dart';
import 'package:moonwallet/logger/logger.dart';
import 'package:moonwallet/types/account_related_types.dart';
import 'package:moonwallet/types/types.dart';
import 'package:moonwallet/utils/constant.dart';
import 'package:moonwallet/widgets/func/tokens_config/show_select_network_modal.dart';
import 'package:moonwallet/widgets/screen_widgets/crypto_picture.dart';

void showBrowserBottomOptions(
    {required BuildContext context,
    required Color darkNavigatorColor,
    required AppColors colors,
    required String title,
    required List<Crypto> networks,
    required Future<void> Function(Crypto) manualChangeNetwork,
    required Crypto currentNetwork,
    required int chainId,
    required String currentUrl,
    required VoidCallback reload,
    required VoidCallback toggleShowAppBar,
    required VoidCallback onShareClick,
    required VoidCallback onClose,
    required InAppWebViewController controller}) async {
  try {
    showCupertinoModalBottomSheet(
        backgroundColor: darkNavigatorColor,
        context: context,
        builder: (BuildContext ctx) {
          double width = MediaQuery.of(context).size.width;

          return StatefulBuilder(builder: (ctx, st) {
            return Material(
                color: Colors.transparent,
                child: SafeArea(
                  child: ListView(
                    shrinkWrap: true,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          spacing: 10,
                          children: [
                            Container(
                              margin: const EdgeInsets.only(left: 4),
                              child: LayoutBuilder(builder: (ctx, c) {
                                return Row(
                                  spacing: 10,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(2),
                                      decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(50),
                                          border: Border.all(
                                              width: 1,
                                              color: currentNetwork.color ??
                                                  Colors.orange
                                                      .withOpacity(0.8))),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(50),
                                        child: Material(
                                          color: Colors.transparent,
                                          child: InkWell(
                                              borderRadius:
                                                  BorderRadius.circular(50),
                                              onTap: () async {
                                                final targetNetwork =
                                                    await showSelectNetworkModal(
                                                        context: context,
                                                        colors: colors,
                                                        roundedOf: (v) => v,
                                                        fontSizeOf: (v) => v,
                                                        iconSizeOf: (v) => v,
                                                        networks: networks);
                                                if (targetNetwork != null) {
                                                  await manualChangeNetwork(
                                                      targetNetwork);
                                                }
                                              },
                                              child: CryptoPicture(
                                                  crypto: currentNetwork,
                                                  size: 30,
                                                  colors: colors)),
                                        ),
                                      ),
                                    ),
                                    SizedBox(
                                      width: c.maxWidth * 0.8,
                                      child: Text(
                                        title,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.roboto(
                                            color: colors.textColor,
                                            fontWeight: FontWeight.w500,
                                            fontSize: 20),
                                      ),
                                    ),
                                  ],
                                );
                              }),
                            ),
                            ConstrainedBox(
                              constraints: BoxConstraints(
                                  maxWidth: width, maxHeight: 70),
                              child: Container(
                                height: 40,
                                padding: const EdgeInsets.only(left: 7),
                                margin: const EdgeInsets.only(top: 10),
                                decoration: BoxDecoration(
                                    color:
                                        currentNetwork.color?.withOpacity(0.05),
                                    borderRadius: BorderRadius.circular(30)),
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(20),
                                    onTap: () async {
                                      Clipboard.setData(ClipboardData(
                                          text: (await controller.getUrl())
                                              .toString()));
                                    },
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        ConstrainedBox(
                                          constraints: BoxConstraints(
                                              maxWidth: width * 0.8),
                                          child: Text(
                                            currentUrl,
                                            style: GoogleFonts.roboto(
                                              color: currentNetwork.color
                                                  ?.withOpacity(0.8),
                                              fontSize: 14,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 10),
                                          child: Icon(
                                            FeatherIcons.copy,
                                            color: currentNetwork.color,
                                          ),
                                        )
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            )
                          ],
                        ),
                      ),
                      Divider(
                        height: 10,
                        color: colors.textColor.withOpacity(0.05),
                      ),
                      Column(
                        children:
                            List.generate(browserModalOptions.length, (index) {
                          final option = browserModalOptions[index];

                          return Material(
                            color: Colors.transparent,
                            child: ListTile(
                              onTap: () async {
                                if (index == 0) {
                                  reload();
                                  Navigator.pop(ctx);
                                } else if (index == 1) {
                                  final targetNetwork =
                                      await showSelectNetworkModal(
                                          context: context,
                                          colors: colors,
                                          roundedOf: (v) => v,
                                          fontSizeOf: (v) => v,
                                          iconSizeOf: (v) => v,
                                          networks: networks);
                                  if (targetNetwork != null) {
                                    await manualChangeNetwork(targetNetwork);
                                  }
                                } else if (index == 2) {
                                  toggleShowAppBar();
                                  Navigator.pop(ctx);
                                } else if (index == 3) {
                                  onShareClick();
                                } else if (index == 4) {
                                  onClose();
                                }
                              },
                              title: Row(
                                children: [
                                  Text(
                                    option["name"],
                                    style: GoogleFonts.roboto(
                                      color: colors.textColor,
                                    ),
                                  ),
                                  SizedBox(
                                    width: 7,
                                  ),
                                  if (index == 1)
                                    ConstrainedBox(
                                      constraints: BoxConstraints(
                                        maxWidth:
                                            MediaQuery.of(context).size.width *
                                                0.45,
                                      ),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 2, horizontal: 8),
                                        decoration: BoxDecoration(
                                            borderRadius:
                                                BorderRadius.circular(30),
                                            color: currentNetwork.color
                                                ?.withOpacity(0.05)),
                                        child: Text(
                                          currentNetwork.name,
                                          overflow: TextOverflow.ellipsis,
                                          style: GoogleFonts.roboto(
                                              color: currentNetwork.color,
                                              fontSize: 14),
                                        ),
                                      ),
                                    )
                                ],
                              ),
                              trailing: Icon(
                                option["icon"],
                                color: colors.textColor.withOpacity(0.6),
                              ),
                            ),
                          );
                        }),
                      )
                    ],
                  ),
                ));
          });
        });
  } catch (e) {
    logError(e.toString());
  }
}
