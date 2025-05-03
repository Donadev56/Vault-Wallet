import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:moonwallet/types/types.dart';
import 'package:moonwallet/widgets/dialogs/show_standard_sheet.dart';
import 'package:moonwallet/widgets/dialogs/standard_container.dart';
import 'package:moonwallet/widgets/screen_widgets/crypto_picture.dart';

void showTokenDetails(
    {required BuildContext context,
    required AppColors colors,
    required Crypto crypto}) {
  showStandardModalBottomSheet(
    barrierColor: Colors.transparent,
    context: context,
    builder: (context) {
      final textTheme = TextTheme.of(context);
      return Material(
        color: Colors.transparent,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: SelectableRegion(
              selectionControls: materialTextSelectionControls,
              child: StandardContainer(
                padding:
                    const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    Align(
                      alignment: Alignment.center,
                      child: Text(
                        "Token Details",
                        style: textTheme.bodyMedium
                            ?.copyWith(fontSize: 14, color: colors.textColor),
                      ),
                    ),
                    SizedBox(
                      height: 15,
                    ),
                    Align(
                      alignment: Alignment.center,
                      child: CryptoPicture(
                          crypto: crypto, size: 60, colors: colors),
                    ),
                    SizedBox(
                      height: 10,
                    ),
                    Align(
                      alignment: Alignment.center,
                      child: Text(
                        crypto.name,
                        style: textTheme.bodyMedium?.copyWith(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: colors.textColor),
                      ),
                    ),
                    SizedBox(
                      height: 30,
                    ),
                    StandardContainer(
                      padding: const EdgeInsets.symmetric(
                          vertical: 10, horizontal: 20),
                      backgroundColor: colors.secondaryColor,
                      child: Column(
                        children: [
                          RowDetailsContent(
                              colors: colors, name: "Name", value: crypto.name),
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
                          if (!crypto.isNative)
                            InkWell(
                                onTap: () {
                                  Clipboard.setData(ClipboardData(
                                      text: crypto.contractAddress ?? ""));
                                },
                                child: RowDetailsContent(
                                    colors: colors,
                                    name: "Token Address",
                                    value:
                                        "${crypto.contractAddress?.substring(0, 10)}...")),
                          SizedBox(
                            height: 10,
                          ),
                          RowDetailsContent(
                              colors: colors,
                              name: "Network",
                              value: (crypto.isNative
                                      ? crypto.name
                                      : crypto.network?.name) ??
                                  "Not Found"),
                          SizedBox(
                            height: 10,
                          ),
                        ],
                      ),
                    )
                  ],
                ),
              )),
        ),
      );
    },
  );
}

class RowDetailsContent extends StatelessWidget {
  final String name;
  final String value;
  final AppColors colors;
  const RowDetailsContent(
      {super.key,
      required this.colors,
      required this.name,
      required this.value});

  @override
  Widget build(BuildContext context) {
    final textTheme = TextTheme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          name,
          style: textTheme.bodyMedium
              ?.copyWith(fontSize: 14, color: colors.textColor),
        ),
        Text(
          value,
          style: textTheme.bodyMedium?.copyWith(
              fontSize: 14,
              color: colors.textColor,
              fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
