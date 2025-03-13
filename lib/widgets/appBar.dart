// ignore_for_file: deprecated_member_use

import 'dart:io';
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:moonwallet/logger/logger.dart';
import 'package:moonwallet/main.dart';
import 'package:moonwallet/service/vibration.dart';
import 'package:moonwallet/types/types.dart';
import 'package:moonwallet/utils/constant.dart';
import 'package:moonwallet/widgets/appBar/button.dart';
import 'package:moonwallet/widgets/flowting_modat.dart';
import 'package:moonwallet/widgets/func/show_change_text_dialog.dart';
import 'package:moonwallet/widgets/func/show_color.dart';
import 'package:moonwallet/widgets/func/show_custom_drawer.dart';
import 'package:moonwallet/widgets/func/show_icon.dart';
import 'package:url_launcher/url_launcher.dart';

typedef EditWalletNameType = void Function(String newName, int index);
typedef ActionWithIndexType = void Function(int index);
typedef ReorderList = Future<void> Function(int oldIndex, int newIndex);
typedef SearchWallet = void Function(String query);

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final Color primaryColor;
  final Color textColor;
  final Color surfaceTintColor;
  final PublicData currentAccount;
  final List<PublicData> accounts;
  final List<Crypto> availableCryptos;
  final EditWalletNameType editWalletName;
  final double totalBalanceUsd;
  final Future<void> Function(
      {Color? color, required int index, IconData? icon}) editVisualData;
  final ActionWithIndexType deleteWallet;
  final ActionWithIndexType changeAccount;
  final ActionWithIndexType showPrivateData;
  final ReorderList reorderList;
  final Color secondaryColor;
  final GlobalKey<ScaffoldState> scaffoldKey;
  final File? profileImage;
  final double balanceOfAllAccounts;
  final bool isHidden;
  final AppColors colors;
  final bool isTotalBalanceUpdated;

  const CustomAppBar(
      {super.key,
      required this.totalBalanceUsd,
      required this.primaryColor,
      required this.textColor,
      required this.surfaceTintColor,
      required this.currentAccount,
      required this.accounts,
      required this.editWalletName,
      required this.deleteWallet,
      required this.changeAccount,
      required this.secondaryColor,
      required this.reorderList,
      required this.showPrivateData,
      required this.scaffoldKey,
      required this.balanceOfAllAccounts,
      required this.isHidden,
      required this.colors,
      required this.editVisualData,
      required this.isTotalBalanceUpdated,
      required this.availableCryptos,
      required this.profileImage});

  @override
  Widget build(BuildContext context) {
    // ignore: no_leading_underscores_for_local_identifiers
    TextEditingController _textController = TextEditingController();

    final height = MediaQuery.of(context).size.height;
    final width = MediaQuery.of(context).size.width;

    final List<Map<String, dynamic>> options = [
      {'icon': LucideIcons.pencil, 'name': 'Edit name', 'color': textColor},
      {
        'icon': LucideIcons.badgeDollarSign,
        'name': 'Edit Icon',
        'color': textColor
      },
      {'icon': LucideIcons.palette, 'name': 'Edit Color', 'color': textColor},
      {'icon': LucideIcons.copy, 'name': 'Copy address', 'color': textColor},
      {
        'icon': LucideIcons.key,
        'name': 'View private data',
        'color': textColor
      },
      {
        'icon': LucideIcons.trash,
        'name': 'Delete wallet',
        'color': Colors.pinkAccent
      },
    ];
    String searchQuery = "";

    List<PublicData> filteredList({String query = ""}) {
      return accounts
          .where((account) =>
              account.walletName.toLowerCase().contains(query.toLowerCase()))
          .toList();
    }

    return AppBar(
      backgroundColor: primaryColor,
      surfaceTintColor: primaryColor,
      leading: IconButton(
          onPressed: () {
            showCustomDrawer(
                totalBalanceUsd: totalBalanceUsd,
                context: context,
                profileImage: profileImage,
                colors: colors,
                account: currentAccount,
                availableCryptos: availableCryptos);
          },
          icon: profileImage != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(50),
                  child: Image.file(
                    profileImage!,
                    width: 30,
                    height: 30,
                    fit: BoxFit.cover,
                  ),
                )
              : Icon(
                  Icons.person,
                  color: textColor,
                )),
      title: Material(
        color: Colors.transparent,
        child: InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () async {
              await vibrate(duration: 10);
              showBarModalBottomSheet(
                  backgroundColor: colors.primaryColor,
                  enableDrag: false,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(15),
                          topRight: Radius.circular(15))),
                  // ignore: use_build_context_synchronously
                  context: context,
                  builder: (BuildContext modalCtx) {
                    return StatefulBuilder(
                        builder: (BuildContext mainCtx, setModalState) {
                      return Container(
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(15),
                                topRight: Radius.circular(15)),
                            color: primaryColor),
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
                              padding: const EdgeInsets.symmetric(
                                  vertical: 15, horizontal: 20),
                              child: TextField(
                                  style: GoogleFonts.roboto(
                                    color: textColor,
                                  ),
                                  onChanged: (value) {
                                    setModalState(() {
                                      searchQuery = value;
                                    });
                                  },
                                  cursorColor: textColor.withOpacity(0.4),
                                  decoration: InputDecoration(
                                    contentPadding: const EdgeInsets.symmetric(
                                        vertical: 0, horizontal: 20),
                                    filled: true,
                                    fillColor: textColor.withOpacity(0.05),
                                    enabledBorder: OutlineInputBorder(
                                        borderSide: BorderSide(
                                            color: Colors.transparent,
                                            width: 0),
                                        borderRadius: BorderRadius.circular(5)),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(5),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                        borderSide: BorderSide(
                                            color: Colors.transparent,
                                            width: 0),
                                        borderRadius: BorderRadius.circular(5)),
                                    hintText: 'Search wallets',
                                    hintStyle: GoogleFonts.roboto(
                                        fontSize: 14,
                                        fontWeight: FontWeight.normal,
                                        color: textColor.withOpacity(0.4)),
                                  )),
                            ),

                            // account list

                            SingleChildScrollView(
                              child: SizedBox(
                                  height: height * 0.72,
                                  child: ReorderableListView(
                                      children: [
                                        for (int index = 0;
                                            index <
                                                filteredList(query: searchQuery)
                                                    .length;
                                            index += 1)
                                          Material(
                                              key: Key("$index"),
                                              color: Colors.transparent,
                                              child: Padding(
                                                padding: EdgeInsets.symmetric(
                                                    vertical: 2,
                                                    horizontal: 20),
                                                child: ListTile(
                                                    contentPadding:
                                                        const EdgeInsets.symmetric(
                                                            vertical: 0,
                                                            horizontal: 8),
                                                    tileColor: (filteredList(query: searchQuery)[index].keyId ==
                                                            currentAccount.keyId
                                                        ? colors.themeColor
                                                            .withOpacity(0.2)
                                                        : filteredList(query: searchQuery)[index].walletColor ??
                                                            textColor.withOpacity(
                                                                0.05)),
                                                    onTap: () async {
                                                      await vibrate();

                                                      changeAccount(index);
                                                    },
                                                    shape: RoundedRectangleBorder(
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                                6)),
                                                    leading: filteredList(query: searchQuery)[index].isWatchOnly == true
                                                        ? Icon(LucideIcons.eye,
                                                            color: textColor)
                                                        : Icon(filteredList(query: searchQuery)[index].walletIcon ?? LucideIcons.wallet,
                                                            color: textColor),
                                                    title: Text(
                                                      filteredList(
                                                                  query:
                                                                      searchQuery)[
                                                              index]
                                                          .walletName,
                                                      style: GoogleFonts.roboto(
                                                          color: textColor),
                                                    ),
                                                    trailing: IconButton(
                                                        onPressed: () {
                                                          showFloatingModalBottomSheet(
                                                              backgroundColor:
                                                                  colors
                                                                      .primaryColor,
                                                              context: context,
                                                              builder: (ctx) {
                                                                return ListView
                                                                    .builder(
                                                                        itemCount:
                                                                            options
                                                                                .length,
                                                                        shrinkWrap:
                                                                            true,
                                                                        itemBuilder:
                                                                            (ctx,
                                                                                i) {
                                                                          final opt =
                                                                              options[i];
                                                                          return Material(
                                                                              color: Colors.transparent,
                                                                              child: ListTile(
                                                                                  leading: Icon(
                                                                                    opt["icon"] ?? Icons.integration_instructions,
                                                                                    color: opt["color"]?.withOpacity(0.8),
                                                                                  ),
                                                                                  title: Text(
                                                                                    opt["name"] ?? "",
                                                                                    style: GoogleFonts.roboto(color: opt["color"]?.withOpacity(0.8)),
                                                                                  ),
                                                                                  onTap: () {
                                                                                    vibrate();

                                                                                    if (i == 0) {
                                                                                      _textController.text = accounts[index].walletName;
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
                                                                                      setModalState(() {});

                                                                                      deleteWallet(index);
                                                                                    } else if (i == 3) {
                                                                                      Clipboard.setData(ClipboardData(text: accounts[index].address));
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
                                                                                      if (currentAccount.isWatchOnly) {
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
                                                          color:
                                                              colors.textColor,
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
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 20),
                                  child: ElevatedButton.icon(
                                    onPressed: () {
                                      vibrate();

                                      showMaterialModalBottomSheet(
                                          backgroundColor: Colors.transparent,
                                          shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.only(
                                                  topLeft: Radius.circular(15),
                                                  topRight:
                                                      Radius.circular(15))),
                                          context: context,
                                          builder: (BuildContext btnCtx) {
                                            return Container(
                                              height: height * 0.9,
                                              width: width,
                                              decoration: BoxDecoration(
                                                  color: primaryColor,
                                                  borderRadius:
                                                      BorderRadius.only(
                                                          topLeft:
                                                              Radius.circular(
                                                                  15),
                                                          topRight:
                                                              Radius.circular(
                                                                  15))),
                                              child: Column(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.start,
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Container(
                                                    margin:
                                                        const EdgeInsets.all(
                                                            20),
                                                    child: Column(
                                                      children: [
                                                        AddWalletButton(
                                                            textColor:
                                                                textColor,
                                                            text:
                                                                "Create a new wallet",
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
                                                            textColor:
                                                                textColor,
                                                            text:
                                                                "Import Mnemonic phrases",
                                                            icon: LucideIcons
                                                                .fileText,
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
                                                            textColor:
                                                                textColor,
                                                            text:
                                                                "Import private key",
                                                            icon:
                                                                LucideIcons.key,
                                                            onTap: () {
                                                              Navigator.pushNamed(
                                                                  context,
                                                                  Routes
                                                                      .importWalletMain);
                                                            }),
                                                        SizedBox(
                                                          height: 20,
                                                        ),
                                                        AddWalletButton(
                                                            textColor:
                                                                textColor,
                                                            text:
                                                                "Observation wallet",
                                                            icon:
                                                                LucideIcons.eye,
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
                                    icon: Icon(Icons.add,
                                        color: colors.primaryColor),
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
            },
            child: Container(
              padding: const EdgeInsets.all(2),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    currentAccount.walletName,
                    style: GoogleFonts.roboto(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: textColor),
                  ),
                  SizedBox(
                    width: 5,
                  ),
                  Icon(
                    FeatherIcons.chevronDown,
                    color: textColor,
                  )
                ],
              ),
            )),
      ),
      actions: <Widget>[
        IconButton(
            onPressed: () {
              launchUrl(Uri.parse(
                  "https://x.com/eternalprotcl?t=m1cADuEKb9tTlngYCrlB3Q&s=09"));
            },
            icon: Icon(
              LucideIcons.twitter,
              color: textColor,
            )),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class CustomPopupMenuItem<T> extends PopupMenuEntry<T> {
  final T value;
  final Widget child;
  final double height;
  final VoidCallback onTap;

  const CustomPopupMenuItem({
    required this.value,
    required this.child,
    this.height = kMinInteractiveDimension,
    required this.onTap,
  });

  @override
  bool represents(T? value) => this.value == value;

  @override
  CustomPopupMenuItemState<T> createState() => CustomPopupMenuItemState<T>();
}

class CustomPopupMenuItemState<T> extends State<CustomPopupMenuItem<T>> {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: widget.height,
      alignment: Alignment.centerLeft,
      child: PopupMenuItem(
        child: widget.child,
        onTap: widget.onTap,
      ),
    );
  }
}
