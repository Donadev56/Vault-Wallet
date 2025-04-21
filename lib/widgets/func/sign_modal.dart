/*

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_web3_webview/flutter_web3_webview.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:moonwallet/logger/logger.dart';
import 'package:moonwallet/service/web3_interactions/evm/eth_interaction_manager.dart';
import 'package:moonwallet/types/types.dart';
import 'package:moonwallet/widgets/barre.dart';
import 'package:moonwallet/widgets/func/ask_password.dart';
import 'package:moonwallet/widgets/func/show_select_account.dart';

Future<String?> showSignModal(
    {required String actionName,
    required String data,
    required SignatureRequestType type,
    required currentAccount,
    required BuildContext context,
    InAppWebViewController? webViewController,
    required List<PublicData> accounts,
    required bool mounted,
    required AppColors colors,
    required void Function(PublicData) onTap,
    required Crypto currentNetwork}) async {

  if (currentAccount.isWatchOnly) {
    throw Exception("Signing with a watch-only wallet is not supported.");
  }

  final width = MediaQuery.of(context).size.width;
  final res = showModalBottomSheet<String?>(
      backgroundColor: Colors.transparent,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
              topLeft: Radius.circular(30), topRight: Radius.circular(30))),
      context: context,
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx, st) {
          return ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 500),
            child: Container(
                decoration: BoxDecoration(
                    color: colors.primaryColor,
                    borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(30),
                        topRight: Radius.circular(30))),
                child: Column(
                  spacing: 10,
                  children: [
                    DraggableBar(colors: colors),
                    Align(
                        alignment: Alignment.center,
                        child: Text(
                          actionName,
                          style: GoogleFonts.roboto(
                              color: colors.textColor,
                              fontSize: 20,
                              fontWeight: FontWeight.bold),
                        )),
                    Align(
                        alignment: Alignment.center,
                        child: Text(
                          "Review request details before you confirm.",
                          style: GoogleFonts.roboto(
                              color: Colors.orangeAccent, fontSize: 14),
                        )),
                    SizedBox(
                      height: 15,
                    ),
                    Align(
                      alignment: Alignment.center,
                      child: Container(
                        width: MediaQuery.of(context).size.width * 0.9,
                        decoration: BoxDecoration(
                          color: colors.secondaryColor.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    "Request from",
                                    style: GoogleFonts.roboto(
                                        color: colors.textColor),
                                  ),
                                  FutureBuilder(
                                      future: webViewController?.getUrl(),
                                      builder: (ctx, result) {
                                        if (result.hasData) {
                                          return Text(
                                            "${result.data?.host}",
                                            style: GoogleFonts.roboto(
                                                color: colors.textColor,
                                                fontWeight: FontWeight.bold),
                                          );
                                        } else {
                                          return Text(
                                            "...",
                                            style: GoogleFonts.roboto(
                                                color: colors.textColor),
                                          );
                                        }
                                      })
                                ],
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                selectAnAccount(
                                    currentAccount: currentAccount,
                                    colors: colors,
                                    context: context,
                                    accounts: accounts,
                                    onTap: (w) {
                                      onTap(w);
                                      st(() {
                                        currentAccount = w;
                                      });
                                    });
                              },
                              child: Container(
                                padding: const EdgeInsets.all(10),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      "Sign with",
                                      style: GoogleFonts.roboto(
                                          color: Colors.orangeAccent,
                                          fontWeight: FontWeight.bold),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.all(3),
                                      decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(50),
                                          color: colors.themeColor
                                              .withOpacity(0.1)),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        spacing: 10,
                                        children: [
                                          ClipRRect(
                                            borderRadius: BorderRadius.circular(
                                              (50),
                                            ),
                                            child: currentNetwork.icon != null
                                                ? Image.asset(
                                                    currentNetwork.icon ?? "",
                                                    width: 30,
                                                    height: 30,
                                                    fit: BoxFit.cover,
                                                  )
                                                : Image.network(
                                                    "https://cdn0.iconfinder.com/data/icons/basic-uses-symbol-vol-2/100/Help_Need_Suggestion_Question_Unknown-1024.png",
                                                    width: 30,
                                                    height: 30,
                                                    fit: BoxFit.cover,
                                                  ),
                                          ),
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.center,
                                            children: [
                                              Text(
                                                currentAccount.walletName,
                                                style: GoogleFonts.roboto(
                                                    color: colors.textColor),
                                              ),
                                              SizedBox(
                                                width: 20,
                                              )
                                            ],
                                          )
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          ],
                        ),
                      ),
                    ),
                    Align(
                        alignment: Alignment.center,
                        child: Container(
                            width: width * 0.9,
                            padding: const EdgeInsets.symmetric(
                                vertical: 2, horizontal: 12),
                            decoration: BoxDecoration(
                              color: colors.secondaryColor.withOpacity(0.7),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      "Data :",
                                      style: GoogleFonts.roboto(
                                          color: colors.textColor),
                                    ),
                                    IconButton(
                                        onPressed: () {
                                          Clipboard.setData(
                                              ClipboardData(text: data));
                                        },
                                        icon: Icon(
                                          LucideIcons.copy,
                                          color:
                                              colors.textColor.withOpacity(0.8),
                                          size: 14,
                                        ))
                                  ],
                                ),
                                SizedBox(
                                  height: 80,
                                  child: SingleChildScrollView(
                                    child: Text(
                                      data,
                                      style: GoogleFonts.roboto(
                                          color: colors.textColor),
                                    ),
                                  ),
                                )
                              ],
                            ))),
                    SizedBox(
                      width: width * 0.9,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          SizedBox(
                            width: width * 0.58,
                            child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                    backgroundColor: colors.themeColor,
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 3, horizontal: 10),
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(10))),
                                onPressed: () async {
                                  String userPassword = await askPassword(
                                      context: context, colors: colors);

                                  if (!mounted) {
                                    throw Exception("Internal error");
                                  }
                                  if (userPassword.isEmpty) {
                                    log("No password");
                                    throw Exception("No password provided");
                                  }
                                  showDialog(
                                      context: context,
                                      builder: (BuildContext context) {
                                        return Center(
                                          child: Container(
                                            padding: const EdgeInsets.all(30),
                                            width: 100,
                                            height: 100,
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                              border: Border.all(
                                                  color: colors.secondaryColor,
                                                  width: 0.5),
                                              color: colors.primaryColor,
                                            ),
                                            child: SizedBox(
                                              width: 50,
                                              height: 50,
                                              child: CircularProgressIndicator(
                                                color: colors.textColor,
                                              ),
                                            ),
                                          ),
                                        );
                                      });
                                  String? res;
                                  final web3IntManager =
                                      EthInteractionManager();
                                  if (type ==
                                      SignatureRequestType.ethPersonalSign) {
                                    res = await web3IntManager.personalSign(
                                        data,
                                        network: currentNetwork,
                                        account: currentAccount,
                                        password: userPassword);
                                  } else if (type ==
                                      SignatureRequestType.ethSign) {
                                    res = await web3IntManager.sign(data,
                                        network: currentNetwork,
                                        account: currentAccount,
                                        password: userPassword);
                                  }

                                  Navigator.pop(context);

                                  Navigator.pop(context, res);
                                },
                                child: Text(
                                  "Sign",
                                  style: GoogleFonts.roboto(
                                      color: colors.primaryColor),
                                )),
                          ),
                          SizedBox(
                            width: width * 0.28,
                            child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    elevation: 0,
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 3, horizontal: 10),
                                    shape: RoundedRectangleBorder(
                                        side: BorderSide(
                                            width: 1, color: colors.redColor),
                                        borderRadius:
                                            BorderRadius.circular(10))),
                                onPressed: () {
                                  Navigator.pop(context, "");
                                },
                                child: Text(
                                  "Cancel",
                                  style: GoogleFonts.roboto(
                                      color: colors.redColor),
                                )),
                          )
                        ],
                      ),
                    )
                  ],
                )),
          );
        });
      });
  return res;
}
*/
