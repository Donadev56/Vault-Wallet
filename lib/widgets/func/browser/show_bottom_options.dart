import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:moonwallet/logger/logger.dart';
import 'package:moonwallet/types/types.dart';
import 'package:moonwallet/utils/constant.dart';
import 'package:moonwallet/widgets/crypto_picture.dart';
import 'package:moonwallet/widgets/func/browser/change_network.dart';

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
    required VoidCallback onClose}) async {
  try {
    showMaterialModalBottomSheet(
        backgroundColor: darkNavigatorColor,
        context: context,
        builder: (BuildContext ctx) {
          double width = MediaQuery.of(context).size.width;

          return StatefulBuilder(builder: (ctx, st) {
            return SafeArea(
              child: ListView(
                shrinkWrap: true,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          margin: const EdgeInsets.only(left: 4),
                          child: Row(
                            children: [
                              SizedBox(
                                width: width * 0.3,
                                child: Text(
                                  title,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.roboto(
                                      color: colors.textColor,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 22),
                                ),
                              ),
                              SizedBox(
                                width: 10,
                              ),
                              Container(
                                padding: const EdgeInsets.all(2),
                                decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(50),
                                    border: Border.all(
                                        width: 1,
                                        color: currentNetwork.color ??
                                            Colors.orange.withOpacity(0.8))),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(50),
                                  child: Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                        borderRadius: BorderRadius.circular(50),
                                        onTap: () {
                                          showChangeNetworkModal(
                                              networks: networks,
                                              colors: colors,
                                              changeNetwork:
                                                  manualChangeNetwork,
                                              context: ctx,
                                              darkNavigatorColor:
                                                  darkNavigatorColor,
                                              textColor: colors.textColor,
                                              chainId: chainId);
                                        },
                                        child: CryptoPicture(
                                            crypto: currentNetwork,
                                            size: 30,
                                            colors: colors)),
                                  ),
                                ),
                              )
                            ],
                          ),
                        ),
                        ConstrainedBox(
                          constraints:
                              BoxConstraints(maxWidth: width, maxHeight: 70),
                          child: Container(
                            height: 40,
                            padding: const EdgeInsets.only(left: 7),
                            margin: const EdgeInsets.only(top: 10),
                            decoration: BoxDecoration(
                                color: colors.themeColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(30)),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(20),
                                onTap: () {
                                  Clipboard.setData(
                                      ClipboardData(text: currentUrl));
                                },
                                child: Row(
                                  children: [
                                    ConstrainedBox(
                                      constraints:
                                          BoxConstraints(maxWidth: width * 0.8),
                                      child: Text(
                                        currentUrl,
                                        style: GoogleFonts.roboto(
                                          color: colors.themeColor
                                              .withOpacity(0.8),
                                          fontSize: 14,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    SizedBox(
                                      width: 5,
                                    ),
                                    Icon(
                                      FeatherIcons.copy,
                                      color: colors.themeColor,
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
                    color: colors.textColor.withOpacity(0.05),
                  ),
                  Column(
                    children:
                        List.generate(browserModalOptions.length, (index) {
                      final option = browserModalOptions[index];
                      final isLast = index == browserModalOptions.length - 1;

                      return Material(
                        color: Colors.transparent,
                        child: ListTile(
                          onTap: () {
                            if (index == 0) {
                              reload();
                              Navigator.pop(ctx);
                            } else if (index == 1) {
                              showChangeNetworkModal(
                                  networks: networks,
                                  colors: colors,
                                  changeNetwork: manualChangeNetwork,
                                  context: ctx,
                                  darkNavigatorColor: darkNavigatorColor,
                                  textColor: colors.textColor,
                                  chainId: chainId);
                            } else if (index == 2) {
                              toggleShowAppBar();
                              Navigator.pop(ctx);
                            } else if (index == 3) {
                              onShareClick();
                            } else if (index == 4) {
                              onClose();
                            }
                          },
                          tileColor: isLast
                              ? colors.redColor.withOpacity(0.1)
                              : Colors.transparent,
                          title: Row(
                            children: [
                              Text(
                                option["name"],
                                style: GoogleFonts.roboto(
                                  color: isLast
                                      ? colors.redColor
                                      : colors.textColor,
                                ),
                              ),
                              SizedBox(
                                width: 7,
                              ),
                              if (index == 1)
                                Container(
                                  padding: const EdgeInsets.all(5),
                                  decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(10),
                                      color: colors.primaryColor),
                                  child: Text(
                                    currentNetwork.name,
                                    style: GoogleFonts.roboto(
                                      color: isLast
                                          ? colors.redColor
                                          : colors.textColor,
                                    ),
                                  ),
                                )
                            ],
                          ),
                          trailing: Icon(
                            option["icon"],
                            color: isLast
                                ? colors.redColor
                                : colors.textColor.withOpacity(0.6),
                          ),
                        ),
                      );
                    }),
                  )
                ],
              ),
            );
          });
        });
  } catch (e) {
    logError(e.toString());
  }
}
