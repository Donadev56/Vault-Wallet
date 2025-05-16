import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:moonwallet/types/account_related_types.dart';
import 'package:moonwallet/types/types.dart';
import 'package:moonwallet/widgets/dialogs/row_details.dart';
import 'package:moonwallet/widgets/dialogs/show_standard_sheet.dart';
import 'package:moonwallet/widgets/dialogs/standard_container.dart';
import 'package:moonwallet/widgets/screen_widgets/crypto_picture.dart';

void showTokenDetails(
    {required BuildContext context,
    required AppColors colors,
    required Crypto crypto}) {
  void copy(String text) {
    Clipboard.setData(ClipboardData(text: text));
  }

  showStandardModalBottomSheet(
    context: context,
    builder: (context) {
      final textTheme = TextTheme.of(context);
      return Material(
        color: colors.primaryColor,
        child: SelectableRegion(
            selectionControls: materialTextSelectionControls,
            child: StandardContainer(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
              child: ListView(
                shrinkWrap: true,
                children: [
                  SizedBox(
                    height: 5,
                  ),
                  Align(
                    alignment: Alignment.center,
                    child:
                        CryptoPicture(crypto: crypto, size: 60, colors: colors),
                  ),
                  SizedBox(
                    height: 10,
                  ),
                  Align(
                    alignment: Alignment.center,
                    child: Text(
                      crypto.symbol,
                      style: textTheme.bodyMedium?.copyWith(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: colors.textColor),
                    ),
                  ),
                  SizedBox(
                    height: 30,
                  ),
                  Column(
                    children: [
                      StandardContainer(
                          padding: const EdgeInsets.symmetric(
                              vertical: 10, horizontal: 20),
                          backgroundColor: colors.secondaryColor,
                          child: Column(
                            children: [
                              RowDetailsContent(
                                  colors: colors,
                                  name: "Name",
                                  value: crypto.name),
                              SizedBox(
                                height: 10,
                              ),
                              RowDetailsContent(
                                  colors: colors,
                                  name: "Symbol",
                                  value: crypto.symbol),
                              SizedBox(
                                height: 10,
                              ),
                              RowDetailsContent(
                                  colors: colors,
                                  name: "Decimals",
                                  value: crypto.decimals.toString()),
                              SizedBox(
                                height: 10,
                              ),
                              RowDetailsContent(
                                  colors: colors,
                                  name: "Type",
                                  value: crypto.isNative ? "Native" : "Token"),
                              SizedBox(
                                height: 10,
                              ),
                            ],
                          )),
                      SizedBox(
                        height: 15,
                      ),
                      StandardContainer(
                          padding: const EdgeInsets.symmetric(
                              vertical: 10, horizontal: 20),
                          backgroundColor: colors.secondaryColor,
                          child: Column(
                            children: [
                              if (crypto.isNative)
                                RowDetailsContent(
                                    onClick: () => copy(crypto.getRpcUrl),
                                    colors: colors,
                                    name: "Rpc Url",
                                    value: (crypto.getRpcUrl)),
                              if (!crypto.isNative)
                                RowDetailsContent(
                                    onClick: () =>
                                        copy(crypto.contractAddress ?? ""),
                                    colors: colors,
                                    name: "Token Address",
                                    value:
                                        "${crypto.contractAddress?.substring(0, 10)}..."),
                              SizedBox(
                                height: 10,
                              ),
                              RowDetailsContent(
                                  underline: !crypto.isNative ? true : false,
                                  colors: colors,
                                  onClick: () {
                                    if (crypto.isNative) {
                                      return;
                                    }
                                    final network = crypto.network;
                                    if (network == null) {
                                      return;
                                    }
                                    showTokenDetails(
                                        context: context,
                                        colors: colors,
                                        crypto: network);
                                  },
                                  name: "Network",
                                  value: (crypto.isNative
                                          ? crypto.name
                                          : crypto.network?.name) ??
                                      "Not Found"),
                            ],
                          ))
                    ],
                  ),
                ],
              ),
            )),
      );
    },
  );
}
