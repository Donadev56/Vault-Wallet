// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:moonwallet/types/account_related_types.dart';
import 'package:moonwallet/types/transaction.dart';
import 'package:moonwallet/types/types.dart';
import 'package:moonwallet/utils/constant.dart';
import 'package:moonwallet/utils/number_formatter.dart';
import 'package:moonwallet/widgets/func/transactions/history/show_transaction_details.dart';
import 'package:timer_builder/timer_builder.dart';

class TransactionsListElement extends StatelessWidget {
  final Color surfaceTintColor;

  final bool isFrom;
  final Transaction tr;
  final AppColors colors;
  final Color textColor;

  final Crypto token;
  final DoubleFactor roundedOf;
  final DoubleFactor fontSizeOf;

  const TransactionsListElement(
      {super.key,
      required this.surfaceTintColor,
      required this.isFrom,
      required this.tr,
      required this.textColor,
      required this.token,
      required this.colors,
      required this.fontSizeOf,
      required this.roundedOf});

  @override
  Widget build(BuildContext context) {
    final formattedAmount =
        NumberFormatter().formatCrypto(value: double.parse(tr.uiAmount));
    final textTheme = TextTheme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Material(
        color: Colors.transparent,
        child: ListTile(
          visualDensity: VisualDensity(horizontal: -2, vertical: -4),
          onTap: () {
            showTransactionDetails(
                isFrom: isFrom,
                context: context,
                colors: colors,
                address: tr.from,
                tr: tr,
                token: token);
          },
          leading: Container(
            height: 25,
            width: 25,
            decoration: BoxDecoration(
                color: surfaceTintColor.withOpacity(0.3),
                borderRadius: BorderRadius.circular(50)),
            child: Icon(
              isFrom ? FeatherIcons.arrowUpRight : FeatherIcons.arrowDown,
              size: 15,
              color: isFrom ? textColor.withOpacity(0.4) : colors.themeColor,
            ),
          ),
          title: Text(
            isFrom ? "Send" : "Receive",
            style: textTheme.bodyMedium?.copyWith(
                color: textColor,
                fontWeight: FontWeight.bold,
                fontSize: fontSizeOf(14)),
          ),
          subtitle: Text(
              isFrom
                  ? tr.to.length > 6
                      ? "To : ${tr.to.substring(0, 6)}...${tr.to.substring(tr.to.length - 6, tr.to.length)}"
                      : "To : ...."
                  : tr.from.length > 6
                      ? "From : ${tr.from.substring(0, 6)}... ${tr.from.substring(tr.from.length - 6, tr.from.length)}"
                      : "From : ...",
              style: textTheme.bodyMedium?.copyWith(
                  color: textColor.withOpacity(0.4), fontSize: fontSizeOf(12))),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                isFrom ? "-$formattedAmount" : "+$formattedAmount",
                style: textTheme.bodyMedium?.copyWith(
                    fontSize: fontSizeOf(12),
                    color: textColor,
                    fontWeight: FontWeight.bold),
              ),
              TimerBuilder.periodic(
                Duration(seconds: 5),
                builder: (ctx) {
                  return Text(
                    formatTimeElapsed(tr.timeStamp),
                    style: textTheme.bodyMedium?.copyWith(
                        color: textColor.withOpacity(0.5),
                        fontSize: fontSizeOf(12)),
                  );
                },
              )
            ],
          ),
        ),
      ),
    );
  }
}
