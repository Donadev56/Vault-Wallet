import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:moonwallet/types/types.dart';
import 'package:moonwallet/widgets/crypto_picture.dart';

typedef ChangeNetworkType = Future<void> Function(Crypto network);
void showChangeNetworkModal(
    {required double height,
    required List<Crypto> networks,
    required BuildContext context,
    required Color darkNavigatorColor,
    required Color textColor,
    required int chainId,
    required AppColors colors,
    required ChangeNetworkType changeNetwork}) {
  showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          child: Container(
            height: height * 0.5,
            decoration: BoxDecoration(
                color: darkNavigatorColor,
                borderRadius: BorderRadius.circular(10)),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.only(top: 20, left: 15, bottom: 10),
                  child: Text(
                    "Change Network :",
                    style: GoogleFonts.roboto(
                        color: textColor, fontWeight: FontWeight.bold),
                  ),
                ),
                ConstrainedBox(
                  constraints: BoxConstraints(maxHeight: height * 0.4),
                  child: ListView.builder(
                    itemCount: networks
                        .where((crypto) => crypto.type != CryptoType.token)
                        .toList()
                        .length,
                    itemBuilder: (BuildContext context, int index) {
                      final network = networks
                          .where((crypto) => crypto.type != CryptoType.token)
                          .toList()[index];
                      return Material(
                        color: Colors.transparent,
                        child: ListTile(
                          selected: chainId == network.chainId,
                          tileColor: chainId == network.chainId
                              ? colors.themeColor
                              : Colors.transparent,
                          onTap: () async {
                            await changeNetwork(network);

                            Navigator.pop(context);
                          },
                          leading: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                                border: Border.all(
                                    width: 1,
                                    color: network.color ?? Colors.white),
                                borderRadius: BorderRadius.circular(50)),
                            child: CryptoPicture(
                                crypto: network, size: 30, colors: colors),
                          ),
                          title: Text(
                            network.name,
                            style: GoogleFonts.roboto(color: textColor),
                          ),
                          trailing: Icon(
                            Icons.arrow_right_outlined,
                            color: textColor.withOpacity(0.6),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      });
}
