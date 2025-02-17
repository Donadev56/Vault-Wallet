// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:moonwallet/logger/logger.dart';
import 'package:moonwallet/main.dart';
import 'package:moonwallet/service/vibration.dart';
import 'package:moonwallet/types/types.dart';
import 'package:moonwallet/widgets/appBar/button.dart';

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
  final ActionWithIndexType deleteWallet;
  final ActionWithIndexType changeAccount;
  final ActionWithIndexType showPrivateData;
  final ReorderList reorderList;
  final Color secondaryColor;

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
      required this.showPrivateData});

  @override
  Widget build(BuildContext context) {
    // ignore: no_leading_underscores_for_local_identifiers
    TextEditingController _textController = TextEditingController();

    final height = MediaQuery.of(context).size.height;
    final width = MediaQuery.of(context).size.width;

    final List<Map<String, dynamic>> options = [
      {'icon': LucideIcons.pencil, 'name': 'Edit name', 'color': textColor},
      {
        'icon': LucideIcons.trash,
        'name': 'Delete wallet',
        'color': Colors.pinkAccent
      },
      {'icon': LucideIcons.copy, 'name': 'Copy address', 'color': textColor},
      {
        'icon': LucideIcons.key,
        'name': 'View private data',
        'color': textColor
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
      surfaceTintColor: surfaceTintColor,
      leading: IconButton(
          onPressed: () {
            log("taped");
          },
          icon: Icon(
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
                                topLeft: Radius.circular(15),
                                topRight: Radius.circular(15)),
                            color: surfaceTintColor),
                        child: Column(
                          children: [
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
                                  Text(
                                    'Select wallet',
                                    style: GoogleFonts.roboto(
                                        fontSize: 14,
                                        fontWeight: FontWeight.normal,
                                        color: textColor),
                                  ),
                                  IconButton(
                                      padding: const EdgeInsets.all(0),
                                      onPressed: () {
                                        Navigator.pop(context);
                                      },
                                      icon: Icon(
                                        FeatherIcons.layers,
                                        color: textColor,
                                      )),
                                ],
                              ),
                            ),

                            // search
                            Container(
                              height: 70,
                              padding: const EdgeInsets.all(13),
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
                                    filled: true,
                                    fillColor: textColor.withOpacity(0.125),
                                    enabledBorder: OutlineInputBorder(
                                        borderSide: BorderSide(
                                            color: Colors.transparent,
                                            width: 0),
                                        borderRadius:
                                            BorderRadius.circular(30)),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                        borderSide: BorderSide(
                                            color: textColor.withOpacity(0.2),
                                            width: 2),
                                        borderRadius:
                                            BorderRadius.circular(15)),
                                    hintText: 'Search wallets',
                                    hintStyle: GoogleFonts.roboto(
                                        fontSize: 14,
                                        fontWeight: FontWeight.normal,
                                        color: textColor),
                                  )),
                            ),

                            // account list

                            SingleChildScrollView(
                              child: SizedBox(
                                  height: height * 0.62,
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
                                                  top: 5,
                                                  bottom: 5,
                                                  left: 15,
                                                  right: 15),
                                              decoration: BoxDecoration(
                                                  color:
                                                      filteredList(query: searchQuery)[
                                                                      index]
                                                                  .keyId ==
                                                              currentAccount
                                                                  .keyId
                                                          ? secondaryColor
                                                              .withOpacity(0.2)
                                                          : textColor
                                                              .withOpacity(0.1),
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          10)),
                                              child: ListTile(
                                                onTap: () async {
                                                  await vibrate();

                                                  changeAccount(index);
                                                },
                                                shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            10)),
                                                leading:
                                                    filteredList(query: searchQuery)[
                                                                    index]
                                                                .isWatchOnly ==
                                                            true
                                                        ? Icon(LucideIcons.eye,
                                                            color: textColor)
                                                        : Icon(
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
                                                    color: surfaceTintColor,
                                                    iconColor: textColor,
                                                    itemBuilder:
                                                        (BuildContext ctx) {
                                                      return List.generate(
                                                          options.length, (i) {
                                                        final option =
                                                            options[i];
                                                        return PopupMenuItem(
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
                                                              showDialog(
                                                                  context: ctx,
                                                                  builder:
                                                                      (BuildContext
                                                                          alertCtx) {
                                                                    return AlertDialog(
                                                                      backgroundColor:
                                                                          surfaceTintColor,
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
                                                                    );
                                                                  });
                                                            } else if (i == 1) {
                                                              deleteWallet(
                                                                  index);
                                                            } else if (i == 2) {
                                                              Clipboard.setData(
                                                                  ClipboardData(
                                                                      text: accounts[
                                                                              index]
                                                                          .address));
                                                            } else if (i == 3) {
                                                              showPrivateData(
                                                                  index);
                                                            }
                                                          },
                                                        );
                                                      });
                                                    }),
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
                              height: 5,
                            ),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 20),
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  vibrate();

                                  showModalBottomSheet(
                                      isScrollControlled: true,
                                      context: context,
                                      builder: (BuildContext btnCtx) {
                                        return Container(
                                          height: height * 0.9,
                                          width: width,
                                          decoration: BoxDecoration(
                                              color: primaryColor,
                                              borderRadius: BorderRadius.only(
                                                  topLeft: Radius.circular(15),
                                                  topRight:
                                                      Radius.circular(15))),
                                          child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.start,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
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
                                    const Icon(Icons.add, color: Colors.black),
                                label: Text(
                                  "Add a new wallet",
                                  style: GoogleFonts.exo2(
                                      fontSize: 16, color: Colors.black),
                                ),
                                style: ElevatedButton.styleFrom(
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
              log("taped");
            },
            icon: Icon(
              LucideIcons.maximize,
              color: textColor,
            )),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
