import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:moonwallet/types/types.dart';
import 'package:moonwallet/utils/prefs.dart';
import 'package:moonwallet/widgets/crypto_picture.dart';

import '../../logger/logger.dart';

void showSelectLastAddr(
    {required BuildContext context,
    required List<PublicData> accounts,
    required PublicDataManager publicDataManager,
    required PublicData currentAccount,
    required AppColors colors,
    required TextEditingController addressController,
    required Crypto currentNetwork}) {
  int currentIndex = 0;
  int tabNumber = 2;

  showMaterialModalBottomSheet(
      backgroundColor: Colors.transparent,
      context: context,
      builder: (BuildContext btmCtx) {
        final textTheme = Theme.of(context).textTheme;

        return StatefulBuilder(
            builder: (BuildContext stateFCtx, setModalState) {
          Future<List<dynamic>> getAddress() async {
            try {
              final lastUsedAddresses =
                  await publicDataManager.getDataFromPrefs(
                      key: "${currentAccount.address}/lastUsedAddresses");
              log("last address $lastUsedAddresses");
              if (lastUsedAddresses != null) {
                return (json.decode(lastUsedAddresses) as List<dynamic>)
                    .toSet()
                    .toList();
              } else {
                return [];
              }
            } catch (e) {
              logError(e.toString());
              return [];
            }
          }

          Future<List<dynamic>> data() async {
            final addresses = await getAddress();
            return ([
              addresses,
              accounts
                  .where((acc) => !acc.isWatchOnly)
                  .map((acc) => acc.address)
                  .toList()
                  .toSet()
                  .toList()
            ]);
          }

          return BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
              child: DefaultTabController(
                  length: tabNumber,
                  initialIndex: currentIndex,
                  child: Scaffold(
                    backgroundColor: colors.primaryColor,
                    appBar: AppBar(
                      leading: IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: Icon(
                            Icons.arrow_back,
                            color: colors.textColor,
                          )),
                      title: Text(
                        "List of wallets",
                        style: textTheme.headlineMedium
                            ?.copyWith(color: colors.textColor, fontSize: 20),
                      ),
                      backgroundColor: colors.primaryColor,
                      bottom: PreferredSize(
                          preferredSize: Size.fromHeight(40),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              margin:
                                  const EdgeInsets.symmetric(horizontal: 15),
                              decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10),
                                  color:
                                      colors.themeColor.withValues(alpha: 0.1)),
                              child: TabBar(
                                indicatorSize: TabBarIndicatorSize.tab,
                                indicatorPadding: const EdgeInsets.symmetric(
                                    vertical: 5, horizontal: 10),
                                indicator: BoxDecoration(
                                    color: colors.themeColor,
                                    borderRadius: BorderRadius.circular(10)),
                                dividerColor: Colors.transparent,
                                labelStyle: textTheme.bodyMedium?.copyWith(
                                    color: colors.primaryColor,
                                    fontWeight: FontWeight.bold),
                                tabs: <Widget>[
                                  Tab(
                                    text: "Recent",
                                  ),
                                  Tab(text: "Accounts"),
                                ],
                              ),
                            ),
                          )),
                    ),
                    body: TabBarView(
                        children: List.generate(tabNumber, (i) {
                      return FutureBuilder(
                          future: data(),
                          builder: (ctx, result) {
                            if (result.hasData) {
                              return Padding(
                                padding: const EdgeInsets.only(top: 15),
                                child: ListView.builder(
                                    shrinkWrap: true,
                                    itemCount: result.data?[i].length,
                                    itemBuilder: (ctx, index) {
                                      final addr = result.data?[i][index];

                                      return Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 15, vertical: 5),
                                        child: ListTile(
                                          visualDensity: VisualDensity(
                                              vertical: -2, horizontal: -2),
                                          tileColor: colors.secondaryColor
                                              .withValues(alpha: 0.5),
                                          shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10)),
                                          onTap: () {
                                            addressController.text = addr;
                                            Navigator.pop(context);
                                          },
                                          leading: CryptoPicture(
                                              crypto: currentNetwork,
                                              size: 30,
                                              colors: colors),
                                          title: Text(
                                            "${(addr as String).substring(0, 10)}...${(addr).substring(addr.length - 10, addr.length)}",
                                            style: textTheme.bodyMedium
                                                ?.copyWith(
                                                    color: colors.textColor
                                                        .withOpacity(0.7)),
                                          ),
                                          trailing: IconButton(
                                              onPressed: () {
                                                Clipboard.setData(
                                                    ClipboardData(text: addr));
                                              },
                                              icon: Icon(
                                                Icons.copy_all,
                                                color: colors.textColor,
                                              )),
                                        ),
                                      );
                                    }),
                              );
                            } else if (result.hasError) {
                              return Center(
                                child: Text(
                                  result.error.toString(),
                                  style: textTheme.bodyMedium
                                      ?.copyWith(color: colors.textColor),
                                ),
                              );
                            } else {
                              return Center(
                                child: Text(
                                  "No address found",
                                  style: textTheme.bodyMedium
                                      ?.copyWith(color: colors.textColor),
                                ),
                              );
                            }
                          });
                    })),
                  )));
        });
      });
}
