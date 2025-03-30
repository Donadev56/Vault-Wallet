// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:moonwallet/service/vibration.dart';
import 'package:moonwallet/types/types.dart';
import 'package:moonwallet/utils/constant.dart';
import 'package:moonwallet/widgets/appBar/show_wallet_actions.dart';
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

  Key widgetKey = UniqueKey();
  String searchQuery = "";
  List<PublicData> availableAccounts = accounts;
  List<PublicData> filteredList(
      {String query = "", required List<PublicData> accts}) {
    return accts
        .where((account) =>
            account.walletName.toLowerCase().contains(query.toLowerCase()) ||
            account.address.toLowerCase().contains(query.toLowerCase()))
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
                        prefixIcon: Icon(
                          Icons.search,
                          color: colors.textColor.withOpacity(0.3),
                        ),
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
                    physics: ClampingScrollPhysics(),
                    child: LayoutBuilder(builder: (ctx, c) {
                      return ConstrainedBox(
                          constraints: BoxConstraints(maxHeight: height * 0.72),
                          key: widgetKey,
                          child: GlowingOverscrollIndicator(
                              color: colors.themeColor,
                              axisDirection: AxisDirection.down,
                              child: ReorderableListView.builder(
                                  shrinkWrap: true,
                                  physics: ClampingScrollPhysics(),
                                  itemCount: filteredList(
                                          query: searchQuery,
                                          accts: availableAccounts)
                                      .length,
                                  itemBuilder: (ctx, index) {
                                    final wallet = filteredList(
                                        query: searchQuery,
                                        accts: availableAccounts)[index];
                                    return SizedBox(
                                        key: Key("$index"),
                                        child: Material(
                                            color: Colors.transparent,
                                            child: Padding(
                                              padding: EdgeInsets.symmetric(
                                                  vertical: 4, horizontal: 20),
                                              child: ListTile(
                                                  visualDensity: VisualDensity(
                                                      horizontal: 0,
                                                      vertical: -4),
                                                  contentPadding:
                                                      const EdgeInsets
                                                          .symmetric(
                                                          vertical: 0,
                                                          horizontal: 10),
                                                  tileColor:
                                                      (wallet.keyId ==
                                                              currentAccount
                                                                  .keyId
                                                          ? colors.themeColor
                                                              .withOpacity(0.2)
                                                          : wallet.walletColor
                                                                      ?.value !=
                                                                  0x00000000
                                                              ? wallet
                                                                  .walletColor
                                                              : colors
                                                                  .textColor
                                                                  .withOpacity(
                                                                      0.05)),
                                                  onTap: () async {
                                                    await vibrate();

                                                    changeAccount(index);
                                                  },
                                                  shape: RoundedRectangleBorder(
                                                      borderRadius: BorderRadius
                                                          .circular(6)),
                                                  leading: wallet.isWatchOnly ==
                                                          true
                                                      ? Icon(
                                                          LucideIcons.eye,
                                                          color:
                                                              colors.textColor,
                                                        )
                                                      : Icon(
                                                          wallet.walletIcon ??
                                                              LucideIcons
                                                                  .wallet,
                                                          color:
                                                              colors.textColor,
                                                        ),
                                                  title: Text(
                                                    wallet.walletName,
                                                    style: GoogleFonts.roboto(
                                                        color: colors.textColor,
                                                        fontWeight:
                                                            FontWeight.w500,
                                                        fontSize: 16),
                                                  ),
                                                  subtitle: Text(
                                                    "${wallet.address.substring(0, 9)}...${wallet.address.substring(wallet.address.length - 6, wallet.address.length)}",
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style: GoogleFonts.roboto(
                                                        color: colors.textColor
                                                            .withOpacity(0.4),
                                                        fontSize: 12),
                                                  ),
                                                  trailing: IconButton(
                                                      onPressed: () async {
                                                        showFloatingModalBottomSheet(
                                                            backgroundColor:
                                                                colors
                                                                    .primaryColor,
                                                            context: context,
                                                            builder: (ctx) {
                                                              return ListView
                                                                  .builder(
                                                                      itemCount:
                                                                          appBarButtonOptions
                                                                              .length,
                                                                      shrinkWrap:
                                                                          true,
                                                                      itemBuilder:
                                                                          (ctx,
                                                                              i) {
                                                                        final opt =
                                                                            appBarButtonOptions[i];
                                                                        final isLast =
                                                                            i ==
                                                                                appBarButtonOptions.length - 1;

                                                                        return Material(
                                                                            color:
                                                                                Colors.transparent,
                                                                            child: ListTile(
                                                                                tileColor: isLast ? colors.redColor.withOpacity(0.1) : Colors.transparent,
                                                                                leading: Icon(
                                                                                  opt["icon"] ?? Icons.integration_instructions,
                                                                                  color: isLast ? colors.redColor : colors.textColor.withOpacity(0.8),
                                                                                ),
                                                                                title: Text(
                                                                                  opt["name"] ?? "",
                                                                                  style: GoogleFonts.roboto(
                                                                                    color: isLast ? colors.redColor : colors.textColor.withOpacity(0.8),
                                                                                  ),
                                                                                ),
                                                                                onTap: () async {
                                                                                  vibrate();

                                                                                  if (i == 0) {
                                                                                    _textController.text = availableAccounts[index].walletName;
                                                                                    showChangeTextDialog(
                                                                                        context: context,
                                                                                        colors: colors,
                                                                                        textController: _textController,
                                                                                        onSubmit: (v) async {
                                                                                          log("Submitted $v");
                                                                                          editWalletName(v, index);
                                                                                          _textController.text = "";
                                                                                        });
                                                                                  } else if (i == 5) {
                                                                                    final response = await deleteWallet(wallet.keyId);

                                                                                    if (response == true) {
                                                                                      setModalState(() {
                                                                                        availableAccounts.remove(filteredList(query: searchQuery, accts: availableAccounts)[index]);
                                                                                      });
                                                                                      rebuild();
                                                                                    }
                                                                                  } else if (i == 3) {
                                                                                    Clipboard.setData(ClipboardData(text: wallet.address));
                                                                                  } else if (i == 4) {
                                                                                    showPrivateData(index);
                                                                                  } else if (i == 2) {
                                                                                    showColorPicker(
                                                                                        onSelect: (c) async {
                                                                                          await editVisualData(index: index, color: colorList[c]);
                                                                                          setModalState(() {});
                                                                                        },
                                                                                        context: context,
                                                                                        colors: colors);
                                                                                  } else if (i == 1) {
                                                                                    if (wallet.isWatchOnly) {
                                                                                      showDialog(
                                                                                          context: context,
                                                                                          builder: (ctx) {
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
                                                                                        onSelect: (ic) async {
                                                                                          await editVisualData(index: index, icon: ic);
                                                                                          setModalState(() {});
                                                                                        },
                                                                                        context: context,
                                                                                        colors: colors);
                                                                                  }
                                                                                }));
                                                                      });
                                                            });
                                                      },
                                                      icon: Icon(
                                                        Icons.more_vert,
                                                        color: colors.textColor,
                                                      ))),
                                            )));
                                  },

                                  /*   */

                                  onReorder: (int oldIndex, int newIndex) {
                                    vibrate();
                                    reorderList(oldIndex, newIndex);

                                    setModalState(() {});
                                  })));
                    })),
                // bottom
                SizedBox(
                  height: 15,
                ),
                LayoutBuilder(builder: (ctx, c) {
                  return SizedBox(
                    width: width,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: ElevatedButton.icon(
                        onPressed: () {
                          vibrate();

                          showAppBarWalletActions(
                              context: context, colors: colors);
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
                            borderRadius: BorderRadius.circular(25),
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

/*
class CustomListWallet extends StatelessWidget {
  final String walletType ;
  final List<PublicData> wallets;
  final AppColors colors ;

  const CustomListWallet({super.key ,
    required this.walletType,
    required this.wallets});

  @override
  Widget build(BuildContext context) {
    return  Column(
      children: [
        Padding(padding: 
        const EdgeInsets.only(left: 15),
        child: Text(walletType, style: GoogleFonts.roboto(color: colors.textColor, fontWeight: FontWeight.bold ),),),

 Column(children: List.generate(wallets.length, (index) {
      return  ();
    }))
      ],
    );
  }
}*/
