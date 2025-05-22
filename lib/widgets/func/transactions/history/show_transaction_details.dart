import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:moonwallet/logger/logger.dart';
import 'package:moonwallet/service/external_data/price_manager.dart';
import 'package:moonwallet/types/account_related_types.dart';
import 'package:moonwallet/types/transaction.dart';
import 'package:moonwallet/types/types.dart';
import 'package:moonwallet/utils/constant.dart';
import 'package:moonwallet/utils/number_formatter.dart';
import 'package:moonwallet/utils/share_manager.dart';
import 'package:moonwallet/widgets/buttons/elevated_low_opacity_button.dart';
import 'package:moonwallet/widgets/dialogs/row_details.dart';
import 'package:moonwallet/widgets/dialogs/standard_container.dart';
import 'package:timer_builder/timer_builder.dart';
import 'package:url_launcher/url_launcher.dart';

void showTransactionDetails(
    {required BuildContext context,
    required AppColors colors,
    required String address,
    required bool isFrom,
    required Transaction tr,
    required Crypto token}) {
  Future<String> getPrice() async {
    try {
      final priceManager = PriceManager();
      return await priceManager.getTokenPriceUsd(token);
    } catch (e) {
      logError(e.toString());
      return "0";
    }
  }

  void copy(String value) async {
    Clipboard.setData(ClipboardData(text: value));
  }

  log("Transaction : ${tr.toJson()}");
  log("Transaction type ${tr.runtimeType}");
  final metadata = tr.metadata;
  log(metadata.toString());
  final metadataList = metadata.entries.toList();
  log("Metadata $metadataList");
  showMaterialModalBottomSheet(
      context: context,
      builder: (context) {
        final textTheme = Theme.of(context).textTheme;

        final defaultValueStyle = textTheme.bodyMedium?.copyWith(
            decorationColor: colors.textColor.withValues(alpha: 0.8),
            overflow: TextOverflow.ellipsis,
            fontSize: 13,
            color: colors.textColor,
            fontWeight: FontWeight.bold);
        final defaultTitleStyle = textTheme.bodyMedium
            ?.copyWith(fontSize: 13, color: colors.textColor);
        return Scaffold(
          backgroundColor: colors.primaryColor,
          appBar: AppBar(
            backgroundColor: colors.primaryColor,
            actions: [
              IconButton(
                  onPressed: () {
                    final url = token.tokenNetwork?.explorers?.firstOrNull;
                    if (url == null) {
                      return;
                    }
                    ShareManager().shareUri(url: "$url/tx/${tr.transactionId}");
                  },
                  icon: Icon(
                    Icons.share,
                    color: colors.textColor,
                  ))
            ],
            leading: IconButton(
                onPressed: () => Navigator.pop(context),
                icon: Icon(
                  Icons.chevron_left,
                  color: colors.textColor,
                )),
            centerTitle: true,
            title: Text(
              isFrom ? "Transfer" : "Receive",
              style: textTheme.bodyMedium?.copyWith(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: colors.textColor),
            ),
          ),
          body: StandardContainer(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: ListView(
              children: [
                Column(
                  spacing: 10,
                  children: [
                    Text(
                      "${isFrom ? "-" : "+"}${NumberFormatter().formatValue(str: tr.uiAmount)} ${token.symbol}",
                      textAlign: TextAlign.center,
                      style: textTheme.headlineMedium?.copyWith(
                        fontSize: 25,
                        fontWeight: FontWeight.bold,
                        color: colors.textColor,
                      ),
                    ),
                    FutureBuilder(
                        future: getPrice(),
                        builder: (ctx, result) {
                          if (result.hasData) {
                            return Text(
                              "≈\$${((double.tryParse(result.data ?? "") ?? 0) * (double.tryParse(tr.uiAmount) ?? 0)).toStringAsFixed(2)}",
                              style: textTheme.bodyMedium?.copyWith(
                                  fontSize: 14,
                                  color:
                                      colors.textColor.withValues(alpha: 0.5),
                                  fontWeight: FontWeight.bold),
                            );
                          }

                          return Text(
                            "...",
                            style: textTheme.bodyMedium?.copyWith(
                                fontSize: 14, color: colors.textColor),
                          );
                        })
                  ],
                ),
                SizedBox(
                  height: 20,
                ),
                StandardContainer(
                    backgroundColor: colors.secondaryColor,
                    padding: const EdgeInsets.symmetric(
                        vertical: 10, horizontal: 10),
                    child: Column(spacing: 10, children: [
                      RowDetailsContent(
                        colors: colors,
                        name: "From",
                        value: truncatedValue(tr.from),
                        valueStyle: defaultValueStyle,
                        titleStyle: defaultTitleStyle,
                        onClick: () => copy(tr.from),
                      ),
                      RowDetailsContent(
                        colors: colors,
                        name: "To",
                        value: truncatedValue(tr.to),
                        valueStyle: defaultValueStyle,
                        titleStyle: defaultTitleStyle,
                        onClick: () => copy(tr.to),
                      ),
                    ])),
                SizedBox(
                  height: 10,
                ),
                StandardContainer(
                  backgroundColor: colors.secondaryColor,
                  padding:
                      const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                  child: Column(spacing: 10, children: [
                    TimerBuilder.periodic(
                      Duration(seconds: 5),
                      builder: (ctx) {
                        return RowDetailsContent(
                            colors: colors,
                            name: "Date",
                            value: formatTimeElapsed(tr.timeStamp),
                            valueStyle: defaultValueStyle,
                            titleStyle: defaultTitleStyle);
                      },
                    ),
                    RowDetailsContent(
                        colors: colors,
                        name: "Status",
                        value: (tr.status?.toLowerCase() ?? "..."),
                        valueStyle: defaultValueStyle?.copyWith(
                            color: tr.status?.toLowerCase() == "success"
                                ? colors.themeColor
                                : colors.textColor),
                        titleStyle: defaultTitleStyle),
                  ]),
                ),
                SizedBox(
                  height: 10,
                ),
                if (metadataList.isNotEmpty)
                  StandardContainer(
                    backgroundColor: colors.secondaryColor,
                    child: Column(
                      spacing: 10,
                      children: metadataList.map((e) {
                        return RowDetailsContent(
                          colors: colors,
                          name: e.key,
                          value: e.value is String
                              ? e.value
                              : (e.value).toString(),
                          copyOnClick: true,
                        );
                      }).toList(),
                    ),
                  ),
                SizedBox(
                  height: 30,
                ),
                ElevatedLowOpacityButton(
                  icon: Icon(
                    LucideIcons.box,
                    color: colors.themeColor,
                  ),
                  onPressed: () {
                    final url = token.tokenNetwork?.explorers?.firstOrNull;
                    if (url == null) {
                      return;
                    }
                    launchUrl(Uri.parse("$url/tx/${tr.transactionId}"));
                  },
                  colors: colors,
                  text: "View on Explorer",
                  padding:
                      const EdgeInsets.symmetric(vertical: 0, horizontal: 10),
                  rounded: 10,
                )
              ],
            ),
          ),
        );
      });
}
