// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:moonwallet/types/types.dart';
import 'package:moonwallet/widgets/screen_widgets/crypto_picture.dart';

typedef ChangeNetworkType = Future<void> Function(Crypto network);
Future<bool> showChangeNetworkModal(
    {required List<Crypto> networks,
    required BuildContext context,
    required Color darkNavigatorColor,
    required Color textColor,
    required int chainId,
    required AppColors colors,
    title = "Change Network",
    required ChangeNetworkType changeNetwork}) async {
  final result = await showMaterialModalBottomSheet<bool>(
      backgroundColor: colors.primaryColor,
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
            child: Scaffold(
          backgroundColor: colors.primaryColor,
          appBar: AppBar(
            backgroundColor: colors.primaryColor,
            surfaceTintColor: colors.primaryColor,
            title: Text(
              title,
              style: GoogleFonts.roboto(color: colors.textColor),
            ),
            actions: [
              IconButton(
                icon: Icon(
                  LucideIcons.circleX,
                  color: colors.redColor,
                ),
                onPressed: () {
                  Navigator.pop(context, false);
                },
              ),
            ],
          ),
          body: Column(children: [
            Expanded(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: networks
                    .where((crypto) => crypto.type != CryptoType.token)
                    .toList()
                    .length,
                itemBuilder: (BuildContext context, int index) {
                  final network = networks
                      .where((crypto) => crypto.type != CryptoType.token)
                      .toList()[index];
                  return Material(
                    color: chainId == network.chainId
                        ? network.color?.withOpacity(0.025)
                        : Colors.transparent,
                    child: ListTile(
                      tileColor: chainId == network.chainId
                          ? network.color?.withOpacity(0.025)
                          : Colors.transparent,
                      onTap: () async {
                        await changeNetwork(network);

                        Navigator.pop(context, true);
                      },
                      leading: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                            border: Border.all(
                                width: 1, color: network.color ?? Colors.white),
                            borderRadius: BorderRadius.circular(50)),
                        child: CryptoPicture(
                            crypto: network, size: 30, colors: colors),
                      ),
                      title: Text(
                        network.name,
                        style: GoogleFonts.roboto(color: textColor),
                      ),
                      trailing: Icon(
                        LucideIcons.chevronRight,
                        color: textColor.withOpacity(0.4),
                      ),
                    ),
                  );
                },
              ),
            )
          ]),
        ));
      });

  return result ?? false;
}
