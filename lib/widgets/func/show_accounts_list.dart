// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:moonwallet/main.dart';
import 'package:moonwallet/service/vibration.dart';
import 'package:moonwallet/types/types.dart';
import 'package:moonwallet/utils/constant.dart';
import 'package:moonwallet/widgets/appBar/button.dart';
import 'package:moonwallet/widgets/flowting_modat.dart';
import 'package:moonwallet/widgets/func/show_change_text_dialog.dart';
import 'package:moonwallet/widgets/func/show_color.dart';
import 'package:moonwallet/widgets/func/show_icon.dart';

import '../../logger/logger.dart';

typedef EditWalletNameType = void Function(String newName, int index);
typedef ActionWithIndexType = void Function(int index);
typedef ActionWithCryptoId = void Function(String cryptoId);

typedef ReorderList = Future<void> Function(int oldIndex, int newIndex);
typedef SearchWallet = void Function(String query);

void showAccountList({
  required AppColors colors,
  required BuildContext context,
  required List<PublicData> accounts,
  required PublicData currentAccount,
  required EditWalletNameType editWalletName,
  required Future<bool> Function(String keyId) deleteWallet,
  required ActionWithIndexType changeAccount,
  required ActionWithIndexType showPrivateData,
  required ReorderList reorderList,
  required Future<void> Function(
          {Color? color, required int index, IconData? icon})
      editVisualData,
}) async {
  TextEditingController _textController = TextEditingController();

  final height = MediaQuery.of(context).size.height;
  final width = MediaQuery.of(context).size.width;
  final List<Map<String, dynamic>> options = [
    {
      'icon': LucideIcons.pencil,
      'name': 'Edit name',
      'color': colors.textColor
    },
    {
      'icon': LucideIcons.badgeDollarSign,
      'name': 'Edit Icon',
      'color': colors.textColor
    },
    {
      'icon': LucideIcons.palette,
      'name': 'Edit Color',
      'color': colors.textColor
    },
    {
      'icon': LucideIcons.copy,
      'name': 'Copy address',
      'color': colors.textColor
    },
    {
      'icon': LucideIcons.key,
      'name': 'View private data',
      'color': colors.textColor
    },
    {
      'icon': LucideIcons.trash,
      'name': 'Delete wallet',
      'color': Colors.pinkAccent
    },
  ];
  Key widgetKey = UniqueKey();
  String searchQuery = "";
  List<PublicData> availableAccounts = accounts;
  List<PublicData> filteredList(
      {String query = "", required List<PublicData> accts}) {
    return accts
        .where((account) =>
            account.walletName.toLowerCase().contains(query.toLowerCase()))
        .toList();
  }

  void rebuild() {
    widgetKey = UniqueKey();
  }

  showBarModalBottomSheet(
      backgroundColor: colors.primaryColor,
      enableDrag: false,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
              topLeft: Radius.circular(15), topRight: Radius.circular(15))),
      // ignore: use_build_context_synchronously
      context: context,
      builder: (BuildContext modalCtx) {
        return StatefulBuilder(builder: (BuildContext mainCtx, setModalState) {
          return Container(
            key: widgetKey,
            alignment: Alignment.center,
            decoration: BoxDecoration(
                borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(15),
                    topRight: Radius.circular(15)),
                color: colors.primaryColor),
            child: Column(
              children: [
                /*  // top
                            Container(
                              padding: const EdgeInsets.all(10),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  IconButton(
                                      padding: const EdgeInsets.all(0),
                                      onPressed: () {
                                        Navigator.pop(context);
                                      },
                                      icon: Text("")),
                                  !isTotalBalanceUpdated
                                      ? SizedBox(
                                          width: 30,
                                          height: 30,
                                          child: CircularProgressIndicator(
                                            color: secondaryColor,
                                          ),
                                        )
                                      : Column(
                                          spacing: 5,
                                          mainAxisAlignment:
                                              MainAxisAlignment.end,
                                          children: [
                                            Text(
                                              "Last Balance",
                                              style: GoogleFonts.roboto(
                                                  color: textColor
                                                      .withOpacity(0.45),
                                                  fontSize: 12),
                                            ),
                                            isHidden
                                                ? Text(
                                                    "*****",
                                                    style: GoogleFonts.roboto(
                                                        color: textColor),
                                                  )
                                                : Text(
                                                    "≈ \$${balanceOfAllAccounts.toStringAsFixed(2)}",
                                                    style: GoogleFonts.roboto(
                                                        color: textColor,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 18),
                                                  )
                                          ],
                                        ),
                                  IconButton(
                                      padding: const EdgeInsets.all(0),
                                      onPressed: () {
                                        Navigator.pop(context);
                                      },
                                      icon: Text(
                                          "") /* Icon(
                                        FeatherIcons.layers,
                                        color: textColor,
                                      ) */
                                      ),
                                ],
                              ),
                            ),
*/
                // search
                Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
                  child: TextField(
                      style: GoogleFonts.roboto(
                        color: colors.textColor,
                      ),
                      onChanged: (value) {
                        setModalState(() {
                          searchQuery = value;
                        });
                      },
                      cursorColor: colors.textColor.withOpacity(0.4),
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(
                            vertical: 0, horizontal: 20),
                        filled: true,
                        fillColor: colors.textColor.withOpacity(0.05),
                        enabledBorder: OutlineInputBorder(
                            borderSide:
                                BorderSide(color: Colors.transparent, width: 0),
                            borderRadius: BorderRadius.circular(5)),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(5),
                        ),
                        focusedBorder: OutlineInputBorder(
                            borderSide:
                                BorderSide(color: Colors.transparent, width: 0),
                            borderRadius: BorderRadius.circular(5)),
                        hintText: 'Search wallets',
                        hintStyle: GoogleFonts.roboto(
                            fontSize: 14,
                            fontWeight: FontWeight.normal,
                            color: colors.textColor.withOpacity(0.4)),
                      )),
                ),

                // account list

                SingleChildScrollView(
                  child: SizedBox(
                      key: widgetKey,
                      height: height * 0.72,
                      child: ReorderableListView(
                          children: [
                            for (int index = 0;
                                index <
                                    filteredList(
                                            query: searchQuery,
                                            accts: availableAccounts)
                                        .length;
                                index += 1)
                              Material(
                                  key: Key("$index"),
                                  color: Colors.transparent,
                                  child: Padding(
                                    padding: EdgeInsets.symmetric(
                                        vertical: 2, horizontal: 20),
                                    child: ListTile(
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                                vertical: 0, horizontal: 8),
                                        tileColor: (filteredList(query: searchQuery, accts: availableAccounts)[index]
                                                    .keyId ==
                                                currentAccount.keyId
                                            ? colors.themeColor.withOpacity(0.2)
                                            : filteredList(query: searchQuery, accts: availableAccounts)[index]
                                                    .walletColor ??
                                                colors.textColor
                                                    .withOpacity(0.05)),
                                        onTap: () async {
                                          await vibrate();

                                          changeAccount(index);
                                        },
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(6)),
                                        leading: filteredList(
                                                        query: searchQuery,
                                                        accts:
                                                            availableAccounts)[index]
                                                    .isWatchOnly ==
                                                true
                                            ? Icon(LucideIcons.eye, color: colors.textColor)
                                            : Icon(
                                                filteredList(
                                                            query: searchQuery,
                                                            accts:
                                                                availableAccounts)[index]
                                                        .walletIcon ??
                                                    LucideIcons.wallet,
                                                color: colors.textColor,
                                              ),
                                        title: Text(
                                          filteredList(
                                                  query: searchQuery,
                                                  accts:
                                                      availableAccounts)[index]
                                              .walletName,
                                          style: GoogleFonts.roboto(
                                              color: colors.textColor),
                                        ),
                                        trailing: IconButton(
                                            onPressed: () async {
                                              showFloatingModalBottomSheet(
                                                  backgroundColor:
                                                      colors.primaryColor,
                                                  context: context,
                                                  builder: (ctx) {
                                                    return ListView.builder(
                                                        itemCount:
                                                            options.length,
                                                        shrinkWrap: true,
                                                        itemBuilder: (ctx, i) {
                                                          final opt =
                                                              options[i];
                                                          return Material(
                                                              color: Colors
                                                                  .transparent,
                                                              child: ListTile(
                                                                  leading: Icon(
                                                                    opt["icon"] ??
                                                                        Icons
                                                                            .integration_instructions,
                                                                    color: opt[
                                                                            "color"]
                                                                        ?.withOpacity(
                                                                            0.8),
                                                                  ),
                                                                  title: Text(
                                                                    opt["name"] ??
                                                                        "",
                                                                    style: GoogleFonts
                                                                        .roboto(
                                                                            color:
                                                                                opt["color"]?.withOpacity(0.8)),
                                                                  ),
                                                                  onTap:
                                                                      () async {
                                                                    vibrate();

                                                                    if (i ==
                                                                        0) {
                                                                      _textController
                                                                          .text = availableAccounts[
                                                                              index]
                                                                          .walletName;
                                                                      showChangeTextDialog(
                                                                          context:
                                                                              context,
                                                                          colors:
                                                                              colors,
                                                                          textController:
                                                                              _textController,
                                                                          onSubmit:
                                                                              (v) async {
                                                                            log("Submitted $v");
                                                                            editWalletName(v,
                                                                                index);
                                                                            _textController.text =
                                                                                "";
                                                                          });
                                                                    } else if (i ==
                                                                        5) {
                                                                      final response = await deleteWallet(filteredList(
                                                                              query: searchQuery,
                                                                              accts: availableAccounts)[index]
                                                                          .keyId);

                                                                      if (response ==
                                                                          true) {
                                                                        setModalState(
                                                                            () {
                                                                          availableAccounts.remove(filteredList(
                                                                              query: searchQuery,
                                                                              accts: availableAccounts)[index]);
                                                                        });
                                                                        rebuild();
                                                                      }
                                                                    } else if (i ==
                                                                        3) {
                                                                      Clipboard.setData(
                                                                          ClipboardData(
                                                                              text: filteredList(query: searchQuery, accts: availableAccounts)[index].address));
                                                                    } else if (i ==
                                                                        4) {
                                                                      showPrivateData(
                                                                          index);
                                                                    } else if (i ==
                                                                        2) {
                                                                      showColorPicker(
                                                                          onSelect:
                                                                              (c) async {
                                                                            await editVisualData(
                                                                                index: index,
                                                                                color: colorList[c]);
                                                                            setModalState(() {});
                                                                          },
                                                                          context:
                                                                              context,
                                                                          colors:
                                                                              colors);
                                                                    } else if (i ==
                                                                        1) {
                                                                      if (currentAccount
                                                                          .isWatchOnly) {
                                                                        showDialog(
                                                                            context:
                                                                                context,
                                                                            builder:
                                                                                (ctx) {
                                                                              return AlertDialog(
                                                                                backgroundColor: colors.secondaryColor,
                                                                                content: Text(
                                                                                  "This wallet is a watch-only wallet. You cannot change the icon.",
                                                                                  style: TextStyle(
                                                                                    color: colors.redColor,
                                                                                  ),
                                                                                ),
                                                                                actions: [
                                                                                  TextButton(
                                                                                    onPressed: () {
                                                                                      Navigator.pop(ctx);
                                                                                    },
                                                                                    child: Text(
                                                                                      "Close",
                                                                                      style: TextStyle(
                                                                                        color: colors.redColor,
                                                                                      ),
                                                                                    ),
                                                                                  ),
                                                                                ],
                                                                              );
                                                                            });

                                                                        return;
                                                                      }
                                                                      showIconPicker(
                                                                          onSelect:
                                                                              (ic) async {
                                                                            await editVisualData(
                                                                                index: index,
                                                                                icon: ic);
                                                                            setModalState(() {});
                                                                          },
                                                                          context:
                                                                              context,
                                                                          colors:
                                                                              colors);
                                                                    }
                                                                  }));
                                                        });
                                                  });
                                            },
                                            icon: Icon(
                                              Icons.more_vert,
                                              color: colors.textColor,
                                            ))),
                                  ))
                          ],
                          onReorder: (int oldIndex, int newIndex) {
                            vibrate();
                            reorderList(oldIndex, newIndex);

                            setModalState(() {});
                          })),
                ),
                // bottom
                SizedBox(
                  height: 15,
                ),
                LayoutBuilder(builder: (ctx, c) {
                  return SizedBox(
                    width: width * 0.9,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: ElevatedButton.icon(
                        onPressed: () {
                          vibrate();

                          showMaterialModalBottomSheet(
                              backgroundColor: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.only(
                                      topLeft: Radius.circular(15),
                                      topRight: Radius.circular(15))),
                              context: context,
                              builder: (BuildContext btnCtx) {
                                return Container(
                                  height: height * 0.9,
                                  width: width,
                                  decoration: BoxDecoration(
                                      color: colors.primaryColor,
                                      borderRadius: BorderRadius.only(
                                          topLeft: Radius.circular(15),
                                          topRight: Radius.circular(15))),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        margin: const EdgeInsets.all(20),
                                        child: Column(
                                          children: [
                                            AddWalletButton(
                                                textColor: colors.textColor,
                                                text: "Create a new wallet",
                                                icon: Icons.add,
                                                onTap: () {
                                                  Navigator.pushNamed(
                                                      context,
                                                      Routes
                                                          .createPrivateKeyMain);
                                                }),
                                            SizedBox(
                                              height: 20,
                                            ),
                                            AddWalletButton(
                                                textColor: colors.textColor,
                                                text: "Import Mnemonic phrases",
                                                icon: LucideIcons.fileText,
                                                onTap: () {
                                                  Navigator.pushNamed(
                                                      context,
                                                      Routes
                                                          .createAccountFromSed);
                                                }),
                                            SizedBox(
                                              height: 20,
                                            ),
                                            AddWalletButton(
                                                textColor: colors.textColor,
                                                text: "Import private key",
                                                icon: LucideIcons.key,
                                                onTap: () {
                                                  Navigator.pushNamed(context,
                                                      Routes.importWalletMain);
                                                }),
                                            SizedBox(
                                              height: 20,
                                            ),
                                            AddWalletButton(
                                                textColor: colors.textColor,
                                                text: "Observation wallet",
                                                icon: LucideIcons.eye,
                                                onTap: () {
                                                  Navigator.pushNamed(
                                                      context,
                                                      Routes
                                                          .addObservationWallet);
                                                })
                                          ],
                                        ),
                                      )
                                    ],
                                  ),
                                );
                              });
                        },
                        icon: Icon(Icons.add, color: colors.primaryColor),
                        label: Text(
                          "Add Wallet",
                          style: GoogleFonts.exo2(
                              fontSize: 16,
                              color: colors.primaryColor,
                              fontWeight: FontWeight.bold),
                        ),
                        style: ElevatedButton.styleFrom(
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(
                              vertical: 0, horizontal: 8),
                          backgroundColor: colors.themeColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          );
        });
      });
}
