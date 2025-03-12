// ignore_for_file: deprecated_member_use

import 'dart:io';
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:moonwallet/logger/logger.dart';
import 'package:moonwallet/main.dart';
import 'package:moonwallet/service/vibration.dart';
import 'package:moonwallet/types/types.dart';
import 'package:moonwallet/utils/constant.dart';
import 'package:moonwallet/widgets/appBar/button.dart';
import 'package:moonwallet/widgets/barre.dart';
import 'package:moonwallet/widgets/func/show_color.dart';
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
  final EditWalletNameType editWalletName;
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
            scaffoldKey.currentState?.openDrawer();
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
              showModalBottomSheet(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(30),
                          topRight: Radius.circular(30))),
                  isScrollControlled: true,
                  // ignore: use_build_context_synchronously
                  context: context,
                  builder: (BuildContext modalCtx) {
                    return StatefulBuilder(
                        builder: (BuildContext mainCtx, setModalState) {
                      return Container(
                        height: height * 0.9,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(30),
                                topRight: Radius.circular(30)),
                            color: primaryColor),
                        child: Column(
                          children: [
                            DraggableBar(colors: colors),
                            // top
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
                                      icon: Icon(
                                        FeatherIcons.xCircle,
                                        color: Colors.pinkAccent,
                                      )),
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

                            // search
                            Container(
                              width: width * 0.89,
                              margin: const EdgeInsets.only(bottom: 9),
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
                                        vertical: 2, horizontal: 20),
                                    filled: true,
                                    fillColor: textColor.withOpacity(0.05),
                                    enabledBorder: OutlineInputBorder(
                                        borderSide: BorderSide(
                                            color: Colors.transparent,
                                            width: 0),
                                        borderRadius:
                                            BorderRadius.circular(30)),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                        borderSide: BorderSide(
                                            color: Colors.transparent,
                                            width: 0),
                                        borderRadius:
                                            BorderRadius.circular(30)),
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
                                  height: height * 0.60,
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
                                            child: Container(
                                              margin: const EdgeInsets.only(
                                                  top: 3,
                                                  bottom: 3,
                                                  left: 15,
                                                  right: 15),
                                              decoration: BoxDecoration(
                                                  color: (filteredList(
                                                                      query:
                                                                          searchQuery)[
                                                                  index]
                                                              .keyId ==
                                                          currentAccount.keyId
                                                      ? secondaryColor
                                                          .withOpacity(0.2)
                                                      : filteredList(
                                                                      query:
                                                                          searchQuery)[
                                                                  index]
                                                              .walletColor ??
                                                          textColor.withOpacity(
                                                              0.05)),
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          15)),
                                              child: ListTile(
                                                onTap: () async {
                                                  await vibrate();

                                                  changeAccount(index);
                                                },
                                                shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            5)),
                                                leading: filteredList(
                                                                    query:
                                                                        searchQuery)[
                                                                index]
                                                            .isWatchOnly ==
                                                        true
                                                    ? Icon(LucideIcons.eye,
                                                        color: textColor)
                                                    : Icon(
                                                        filteredList(query: searchQuery)[
                                                                    index]
                                                                .walletIcon ??
                                                            LucideIcons.wallet,
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
                                                trailing: PopupMenuButton(
                                                  elevation: 10,
                                                  requestFocus: true,
                                                  splashRadius: 10,
                                                  menuPadding:
                                                      const EdgeInsets.all(0),
                                                  shape: RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              20)),
                                                  padding:
                                                      const EdgeInsets.all(10),
                                                  color: colors.secondaryColor,
                                                  iconColor: textColor,
                                                  itemBuilder:
                                                      (BuildContext ctx) {
                                                    return List.generate(
                                                        options.length, (i) {
                                                      final option = options[i];
                                                      return PopupMenuItem(
                                                        value: 1,
                                                        child: Row(
                                                          children: [
                                                            Icon(
                                                              option["icon"],
                                                              size: 20,
                                                              color: option[
                                                                  "color"],
                                                            ),
                                                            SizedBox(
                                                              width: 10,
                                                            ),
                                                            Text(
                                                              option["name"],
                                                              style: GoogleFonts.roboto(
                                                                  color: option[
                                                                      "color"]),
                                                            )
                                                          ],
                                                        ),
                                                        onTap: () {
                                                          vibrate();

                                                          if (i == 0) {
                                                            _textController
                                                                    .text =
                                                                accounts[index]
                                                                    .walletName;
                                                            showDialog(
                                                                context: ctx,
                                                                builder:
                                                                    (BuildContext
                                                                        alertCtx) {
                                                                  return BackdropFilter(
                                                                    filter: ImageFilter.blur(
                                                                        sigmaX:
                                                                            2,
                                                                        sigmaY:
                                                                            2),
                                                                    child: AlertDialog
                                                                        .adaptive(
                                                                      backgroundColor:
                                                                          primaryColor,
                                                                      title:
                                                                          Text(
                                                                        "Edit your wallet name",
                                                                      ),
                                                                      titleTextStyle:
                                                                          GoogleFonts
                                                                              .roboto(
                                                                        fontSize:
                                                                            18,
                                                                        fontWeight:
                                                                            FontWeight.bold,
                                                                        color:
                                                                            textColor,
                                                                      ),
                                                                      content:
                                                                          SizedBox(
                                                                        height:
                                                                            50,
                                                                        child:
                                                                            TextField(
                                                                          cursorColor:
                                                                              textColor.withOpacity(0.2),
                                                                          style:
                                                                              GoogleFonts.roboto(color: textColor),
                                                                          controller:
                                                                              _textController,
                                                                          decoration: InputDecoration(
                                                                              filled: true,
                                                                              fillColor: textColor.withOpacity(0.1),
                                                                              enabledBorder: OutlineInputBorder(borderSide: BorderSide(width: 0, color: Colors.transparent), borderRadius: BorderRadius.circular(30)),
                                                                              focusedBorder: OutlineInputBorder(borderSide: BorderSide(width: 0, color: Colors.transparent))),
                                                                        ),
                                                                      ),
                                                                      actions: [
                                                                        TextButton(
                                                                          onPressed:
                                                                              () {
                                                                            _textController.text =
                                                                                "";
                                                                            Navigator.pop(alertCtx);
                                                                          },
                                                                          child:
                                                                              Text(
                                                                            "Close",
                                                                            style:
                                                                                TextStyle(
                                                                              color: Colors.pinkAccent,
                                                                            ),
                                                                          ),
                                                                        ),
                                                                        TextButton(
                                                                          onPressed:
                                                                              () {
                                                                            log("Submitted ${_textController.text}");
                                                                            editWalletName(_textController.text,
                                                                                index);
                                                                            _textController.text =
                                                                                "";
                                                                            Navigator.pop(alertCtx);
                                                                          },
                                                                          child:
                                                                              Text(
                                                                            "change",
                                                                            style:
                                                                                TextStyle(
                                                                              color: textColor,
                                                                            ),
                                                                          ),
                                                                        ),
                                                                      ],
                                                                    ),
                                                                  );
                                                                });
                                                          } else if (i == 5) {
                                                            deleteWallet(index);
                                                          } else if (i == 3) {
                                                            Clipboard.setData(
                                                                ClipboardData(
                                                                    text: accounts[
                                                                            index]
                                                                        .address));
                                                          } else if (i == 4) {
                                                            showPrivateData(
                                                                index);
                                                          } else if (i == 2) {
                                                            showColorPicker(
                                                                onSelect:
                                                                    (c) async {
                                                                  await editVisualData(
                                                                      index:
                                                                          index,
                                                                      color:
                                                                          colorList[
                                                                              c]);
                                                                  setModalState(
                                                                      () {});
                                                                },
                                                                context:
                                                                    context,
                                                                colors: colors);
                                                          } else if (i == 1) {
                                                            if (currentAccount
                                                                .isWatchOnly) {
                                                              showDialog(
                                                                  context:
                                                                      context,
                                                                  builder:
                                                                      (ctx) {
                                                                    return AlertDialog(
                                                                      backgroundColor:
                                                                          colors
                                                                              .secondaryColor,
                                                                      content:
                                                                          Text(
                                                                        "This wallet is a watch-only wallet. You cannot change the icon.",
                                                                        style:
                                                                            TextStyle(
                                                                          color:
                                                                              colors.redColor,
                                                                        ),
                                                                      ),
                                                                      actions: [
                                                                        TextButton(
                                                                          onPressed:
                                                                              () {
                                                                            Navigator.pop(ctx);
                                                                          },
                                                                          child:
                                                                              Text(
                                                                            "Close",
                                                                            style:
                                                                                TextStyle(
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
                                                                      index:
                                                                          index,
                                                                      icon: ic);
                                                                  setModalState(
                                                                      () {});
                                                                },
                                                                context:
                                                                    context,
                                                                colors: colors);
                                                          }
                                                        },
                                                      );
                                                    });
                                                  },
                                                  child: Icon(
                                                    Icons.more_vert,
                                                    color: textColor,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          )
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
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 20),
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  vibrate();

                                  showModalBottomSheet(
                                      isScrollControlled: true,
                                      backgroundColor: Colors.transparent,
                                      shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.only(
                                              topLeft: Radius.circular(30),
                                              topRight: Radius.circular(30))),
                                      context: context,
                                      builder: (BuildContext btnCtx) {
                                        return Container(
                                          height: height * 0.9,
                                          width: width,
                                          decoration: BoxDecoration(
                                              color: primaryColor,
                                              borderRadius: BorderRadius.only(
                                                  topLeft: Radius.circular(30),
                                                  topRight:
                                                      Radius.circular(30))),
                                          child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.start,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              DraggableBar(colors: colors),
                                              Container(
                                                margin: const EdgeInsets.only(
                                                    top: 20, left: 20),
                                                child: Text(
                                                  "Add a new wallet",
                                                  style: GoogleFonts.roboto(
                                                      color: textColor,
                                                      fontSize: 20,
                                                      fontWeight:
                                                          FontWeight.bold),
                                                ),
                                              ),
                                              Container(
                                                margin:
                                                    const EdgeInsets.all(20),
                                                child: Column(
                                                  children: [
                                                    AddWalletButton(
                                                        textColor: textColor,
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
                                                        textColor: textColor,
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
                                                        textColor: textColor,
                                                        text:
                                                            "Import private key",
                                                        icon: LucideIcons.key,
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
                                                        textColor: textColor,
                                                        text:
                                                            "Observation wallet",
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
                                icon:
                                    Icon(Icons.add, color: colors.primaryColor),
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
                                      vertical: 8, horizontal: 8),
                                  backgroundColor: colors.themeColor,
                                  minimumSize: const Size(double.infinity, 50),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                ),
                              ),
                            ),
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
