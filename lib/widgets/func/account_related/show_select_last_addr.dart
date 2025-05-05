import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:moonwallet/service/db/list_address_dynamic_db.dart';
import 'package:moonwallet/types/account_related_types.dart';
import 'package:moonwallet/types/types.dart';
import 'package:moonwallet/widgets/screen_widgets/crypto_picture.dart';

import '../../../logger/logger.dart';

void showSelectLastAddr(
    {required BuildContext context,
    required List<PublicAccount> accounts,
    required PublicAccount currentAccount,
    required AppColors colors,
    required TextEditingController addressController,
    required Crypto crypto}) {
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
              final db =
                  ListAddressDynamicDb(account: currentAccount, crypto: crypto);
              final lastUsedAddresses = await db.getData();

              log("last address $lastUsedAddresses");
              return (lastUsedAddresses).toSet().toList();
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
                  .where((acc) =>
                      !acc.isWatchOnly && acc.hasAddress(crypto.getNetworkType))
                  .map((acc) => acc.addressByToken(crypto))
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
                      centerTitle: true,
                      title: Text(
                        "Wallets",
                        style: textTheme.bodyMedium
                            ?.copyWith(color: colors.textColor, fontSize: 20),
                      ),
                      backgroundColor: colors.primaryColor,
                      bottom: PreferredSize(
                          preferredSize: Size.fromHeight(25),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              margin:
                                  const EdgeInsets.symmetric(horizontal: 15),
                              child: TabBar(
                                dividerColor: Colors.transparent,
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
                                child: (result.data?[i] as List<dynamic>)
                                        .isEmpty
                                    ? Center(
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.cleaning_services,
                                              color: colors.textColor,
                                              size: 40,
                                            ),
                                            const SizedBox(height: 10),
                                            Text(
                                              "No address found",
                                              style: textTheme.bodyMedium
                                                  ?.copyWith(
                                                      color: colors.textColor),
                                            )
                                          ],
                                        ),
                                      )
                                    : ListView.builder(
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
                                                      BorderRadius.circular(
                                                          10)),
                                              onTap: () {
                                                addressController.text = addr;
                                                Navigator.pop(context);
                                              },
                                              leading: CryptoPicture(
                                                  crypto: crypto,
                                                  size: 30,
                                                  colors: colors),
                                              title: Text(
                                                "${(addr as String).substring(0, 10)}...${(addr).substring(addr.length - 10, addr.length)}",
                                                style: textTheme.bodyMedium
                                                    ?.copyWith(
                                                        color: colors.textColor
                                                            .withOpacity(0.7)),
                                              ),
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
