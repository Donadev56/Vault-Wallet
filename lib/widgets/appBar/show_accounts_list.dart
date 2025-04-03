// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:jazzicon/jazzicon.dart';
import 'package:jazzicon/jazziconshape.dart';

import 'package:moonwallet/service/vibration.dart';
import 'package:moonwallet/types/types.dart';
import 'package:moonwallet/widgets/appBar/show_account_options.dart';
import 'package:moonwallet/widgets/appBar/show_wallet_actions.dart';
import 'package:moonwallet/widgets/flowting_modat.dart';

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

  JazziconData getJazzImage(String address) {
    return Jazzicon.getJazziconData(35, address: address);
  }

  void rebuild() {
    widgetKey = UniqueKey();
  }

  showFloatingModalBottomSheet(
      enableDrag: false,
      /* backgroundColor: colors.primaryColor,
      enableDrag: false,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
              topLeft: Radius.circular(15), topRight: Radius.circular(15))),
              */
      // ignore: use_build_context_synchronously
      context: context,
      builder: (BuildContext modalCtx) {
        return StatefulBuilder(builder: (BuildContext mainCtx, setModalState) {
          return Scaffold(
              backgroundColor: colors.primaryColor,
              appBar: AppBar(
                backgroundColor: colors.primaryColor,
                leading: IconButton(
                  icon: Icon(
                    Icons.arrow_back,
                    color: colors.textColor.withOpacity(0.4),
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              body: SingleChildScrollView(
                child: Container(
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
                        padding: const EdgeInsets.only(
                            bottom: 15, left: 20, right: 20, top: 5),
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
                                  borderSide: BorderSide(
                                      color: Colors.transparent, width: 0),
                                  borderRadius: BorderRadius.circular(5)),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(5),
                              ),
                              focusedBorder: OutlineInputBorder(
                                  borderSide: BorderSide(
                                      color: Colors.transparent, width: 0),
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
                                constraints:
                                    BoxConstraints(maxHeight: height * 0.65),
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
                                                    padding:
                                                        EdgeInsets.symmetric(
                                                            vertical: 4,
                                                            horizontal: 20),
                                                    child: ListTile(
                                                        visualDensity:
                                                            VisualDensity(
                                                                horizontal: 0,
                                                                vertical: -4),
                                                        contentPadding:
                                                            const EdgeInsets.symmetric(
                                                                vertical: 0,
                                                                horizontal: 10),
                                                        tileColor: (wallet
                                                                    .keyId ==
                                                                currentAccount
                                                                    .keyId
                                                            ? colors.themeColor
                                                                .withOpacity(
                                                                    0.2)
                                                            : wallet.walletColor
                                                                        ?.value !=
                                                                    0x00000000
                                                                ? wallet
                                                                    .walletColor
                                                                : Colors
                                                                    .transparent),
                                                        onTap: () async {
                                                          await vibrate();

                                                          changeAccount(index);
                                                        },
                                                        shape: RoundedRectangleBorder(
                                                            borderRadius:
                                                                BorderRadius.circular(
                                                                    6)),
                                                        leading:
                                                            Jazzicon.getIconWidget(
                                                                getJazzImage(wallet.address),
                                                                size: 35),
                                                        title: Row(
                                                          spacing: 5,
                                                          children: [
                                                            LayoutBuilder(
                                                                builder:
                                                                    (ctx, c) {
                                                              return ConstrainedBox(
                                                                constraints: BoxConstraints(
                                                                    maxWidth: wallet
                                                                            .isWatchOnly
                                                                        ? MediaQuery.of(context).size.width *
                                                                            0.16
                                                                        : MediaQuery.of(context).size.width *
                                                                            0.4),
                                                                child: Text(
                                                                  wallet
                                                                      .walletName,
                                                                  overflow:
                                                                      TextOverflow
                                                                          .ellipsis,
                                                                  style: GoogleFonts.roboto(
                                                                      color: colors
                                                                          .textColor,
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .w500,
                                                                      fontSize:
                                                                          16),
                                                                ),
                                                              );
                                                            }),
                                                            if (wallet
                                                                .isWatchOnly)
                                                              Container(
                                                                padding: const EdgeInsets
                                                                    .symmetric(
                                                                    vertical: 3,
                                                                    horizontal:
                                                                        6),
                                                                decoration: BoxDecoration(
                                                                    borderRadius:
                                                                        BorderRadius.circular(
                                                                            20),
                                                                    color: colors
                                                                        .secondaryColor
                                                                        .withOpacity(
                                                                            0.2),
                                                                    border: Border.all(
                                                                        color: colors
                                                                            .secondaryColor)),
                                                                child: Text(
                                                                  "Watch Only",
                                                                  style: GoogleFonts.roboto(
                                                                      color: colors
                                                                          .textColor
                                                                          .withOpacity(
                                                                              0.8),
                                                                      fontSize:
                                                                          11),
                                                                ),
                                                              )
                                                          ],
                                                        ),
                                                        subtitle: Text(
                                                          "${wallet.address.substring(0, 9)}...${wallet.address.substring(wallet.address.length - 6, wallet.address.length)}",
                                                          maxLines: 1,
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                          style: GoogleFonts
                                                              .roboto(
                                                                  color: colors
                                                                      .textColor
                                                                      .withOpacity(
                                                                          0.4),
                                                                  fontSize: 12),
                                                        ),
                                                        trailing: IconButton(
                                                            onPressed: () async {
                                                              showAccountOptions(
                                                                  originalList:
                                                                      availableAccounts,
                                                                  context:
                                                                      context,
                                                                  colors:
                                                                      colors,
                                                                  availableAccounts:
                                                                      filteredList(
                                                                          query:
                                                                              searchQuery,
                                                                          accts:
                                                                              availableAccounts),
                                                                  wallet:
                                                                      wallet,
                                                                  editWalletName:
                                                                      editWalletName,
                                                                  deleteWallet:
                                                                      deleteWallet,
                                                                  updateListAccount:
                                                                      (accounts) {
                                                                    setModalState(
                                                                        () {
                                                                      availableAccounts =
                                                                          accounts;
                                                                    });
                                                                  },
                                                                  rebuild: () {
                                                                    setModalState(
                                                                        () {});
                                                                    rebuild();
                                                                  },
                                                                  showPrivateData:
                                                                      showPrivateData,
                                                                  index: index,
                                                                  editVisualData:
                                                                      editVisualData);
                                                            },
                                                            icon: Icon(
                                                              Icons.more_vert,
                                                              color: colors
                                                                  .textColor,
                                                            ))),
                                                  )));
                                        },

                                        /*   */

                                        onReorder:
                                            (int oldIndex, int newIndex) {
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
                ),
              ));
        });
      });
}
