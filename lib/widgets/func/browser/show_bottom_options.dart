import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:moonwallet/logger/logger.dart';
import 'package:moonwallet/types/types.dart';
import 'package:moonwallet/utils/constant.dart';
import 'package:moonwallet/widgets/barre.dart';
import 'package:moonwallet/widgets/change_network.dart';

void showBrowserBottomOptions({
  required BuildContext context,
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
}) async {
  try {
    showModalBottomSheet(
        context: context,
        builder: (BuildContext context) {
          double width = MediaQuery.of(context).size.width;
          double height = MediaQuery.of(context).size.height;

          return StatefulBuilder(builder: (ctx, st) {
            return Container(
              width: width,
              decoration: BoxDecoration(
                color: darkNavigatorColor,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DraggableBar(colors: colors),
                  Container(
                    margin: const EdgeInsets.all(10),
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
                                        color: Colors.orange.withOpacity(0.8))),
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
                                            changeNetwork: manualChangeNetwork,
                                            height: height,
                                            context: context,
                                            darkNavigatorColor:
                                                darkNavigatorColor,
                                            textColor: colors.textColor,
                                            chainId: chainId);
                                      },
                                      child: currentNetwork.icon == null
                                          ? Container(
                                              width: 25,
                                              height: 25,
                                              decoration: BoxDecoration(
                                                  color: colors.textColor
                                                      .withOpacity(0.6),
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          50)),
                                              child: Center(
                                                child: Text(
                                                  currentNetwork.name
                                                      .substring(0, 2),
                                                  style: GoogleFonts.roboto(
                                                      color:
                                                          colors.primaryColor,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 18),
                                                ),
                                              ),
                                            )
                                          : Image.asset(
                                              currentNetwork.icon ?? "",
                                              width: 30,
                                              height: 30,
                                            ),
                                    ),
                                  ),
                                ),
                              )
                            ],
                          ),
                        ),
                        ConstrainedBox(
                          constraints:
                              BoxConstraints(maxWidth: 190, maxHeight: 70),
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
                                          BoxConstraints(maxWidth: 140),
                                      child: Text(
                                        currentUrl,
                                        style: GoogleFonts.roboto(
                                          color:
                                              colors.textColor.withOpacity(0.8),
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
                    children: List.generate(options.length, (index) {
                      final option = options[index];
                      return Material(
                        color: Colors.transparent,
                        child: ListTile(
                          onTap: () {
                            if (index == 0) {
                              reload();
                              Navigator.pop(context);
                            } else if (index == 1) {
                              showChangeNetworkModal(
                                  networks: networks,
                                  colors: colors,
                                  changeNetwork: manualChangeNetwork,
                                  height: height,
                                  context: context,
                                  darkNavigatorColor: darkNavigatorColor,
                                  textColor: colors.textColor,
                                  chainId: chainId);
                            } else if (index == 2) {
                              toggleShowAppBar();
                              Navigator.pop(context);
                            } else if (index == 3) {
                              toggleShowAppBar();
                              Navigator.pop(context);
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
                                Container(
                                  padding: const EdgeInsets.all(5),
                                  decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(10),
                                      color: colors.primaryColor),
                                  child: Text(
                                    currentNetwork.name,
                                    style: GoogleFonts.roboto(
                                      color: colors.textColor,
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
            );
          });
        });
  } catch (e) {
    logError(e.toString());
  }
}
