// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:moonwallet/logger/logger.dart';

import 'package:moonwallet/service/vibration.dart';
import 'package:moonwallet/types/types.dart';
import 'package:moonwallet/widgets/account_list_view_widget.dart';
import 'package:moonwallet/widgets/appBar/show_account_options.dart';
import 'package:moonwallet/widgets/appBar/show_wallet_actions.dart';
import 'package:moonwallet/widgets/flowting_modat.dart';

typedef EditWalletNameType = Future<bool> Function(
    {required PublicData account, String? name, IconData? icon, Color? color});

typedef ActionWithIndexType = void Function(int index);
typedef ActionWithCryptoId = void Function(String cryptoId);

typedef ReorderList = Future<void> Function(int oldIndex, int newIndex);
typedef SearchWallet = void Function(String query);

void showAccountList({
  required AppColors colors,
  required BuildContext context,
  required List<PublicData> accounts,
  required PublicData currentAccount,
  required EditWalletNameType editWallet,
  required Future<bool> Function(String keyId) deleteWallet,
  required ActionWithIndexType changeAccount,
  required ActionWithIndexType showPrivateData,
  required ReorderList reorderList,
}) async {
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

  showFloatingModalBottomSheet(
      enableDrag: false,
      // ignore: use_build_context_synchronously
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(builder: (BuildContext mainCtx, setModalState) {
          final height = MediaQuery.of(mainCtx).size.height;
          final width = MediaQuery.of(mainCtx).size.width;
          final textTheme = Theme.of(mainCtx).textTheme;

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
                            style: textTheme.bodyMedium?.copyWith(
                                color: colors.textColor,
                                fontSize: 14,
                                fontWeight: FontWeight.w500),
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
                              hintStyle: textTheme.bodySmall?.copyWith(
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
                                                    child:
                                                        AccountListViewWidget(
                                                            colors: colors,
                                                            tileColor: (wallet
                                                                        .keyId ==
                                                                    currentAccount
                                                                        .keyId
                                                                ? colors
                                                                    .themeColor
                                                                    .withOpacity(
                                                                        0.2)
                                                                : wallet.walletColor
                                                                            ?.value !=
                                                                        0x00000000
                                                                    ? wallet
                                                                        .walletColor
                                                                    : Colors
                                                                        .transparent),
                                                            wallet: wallet,
                                                            onTap: () async {
                                                              await vibrate();

                                                              changeAccount(
                                                                  index);
                                                            },
                                                            onMoreTap:
                                                                () async {
                                                              try {
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
                                                                  editWallet:
                                                                      editWallet,
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
                                                                  showPrivateData:
                                                                      showPrivateData,
                                                                  index: index,
                                                                );
                                                              } catch (e) {
                                                                logError(e
                                                                    .toString());
                                                              }
                                                            }),
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
                                style: textTheme.bodyMedium?.copyWith(
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
