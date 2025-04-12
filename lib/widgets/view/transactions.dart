// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:moonwallet/types/types.dart';
import 'package:moonwallet/utils/constant.dart';
import 'package:moonwallet/widgets/view/show_transaction_details.dart';
import 'package:timer_builder/timer_builder.dart';

class TransactionsListElement extends StatelessWidget {
  final Color surfaceTintColor;

  final bool isFrom;
  final EsTransaction tr;
  final AppColors colors;
  final Color textColor;
  final Color secondaryColor;
  final Color primaryColor;
  final Color darkColor;
  final Crypto currentNetwork;
  const TransactionsListElement({
    super.key,
    required this.surfaceTintColor,
    required this.isFrom,
    required this.tr,
    required this.textColor,
    required this.secondaryColor,
    required this.primaryColor,
    required this.darkColor,
    required this.currentNetwork,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: ListTile(
        onTap: () {
          showTransactionDetails(
            isFrom: isFrom,
              context: context,
              colors: colors,
              address: tr.from,
              tr: TransactionDetails(
                  from: tr.from,
                  to: tr.to,
                  value: tr.value,
                  timeStamp: tr.timeStamp,
                  hash: tr.hash,
                  blockNumber: tr.blockNumber),
              currentNetwork: currentNetwork);
        },
        leading: Container(
          height: 35,
          width: 35,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
              color: surfaceTintColor.withOpacity(0.3),
              borderRadius: BorderRadius.circular(50)),
          child: Icon(
            isFrom ? FeatherIcons.arrowUpRight : FeatherIcons.arrowDown,
            size: 15,
            color: isFrom ? textColor.withOpacity(0.4) : secondaryColor,
          ),
        ),
        title: Text(
          isFrom ? "Send" : "Receive",
          style: GoogleFonts.roboto(
              color: textColor, fontWeight: FontWeight.bold, fontSize: 15),
        ),
        subtitle: Text(
            isFrom
                ? tr.to.length > 6
                    ? "To : ${tr.to.substring(0, 6)}...${tr.to.substring(tr.to.length - 6, tr.to.length)}"
                    : "To : ...."
                : tr.from.length > 6
                    ? "From : ${tr.from.substring(0, 6)}... ${tr.from.substring(tr.from.length - 6, tr.from.length)}"
                    : "From : ...",
            style: GoogleFonts.roboto(
                color: textColor.withOpacity(0.4), fontSize: 12)),
        trailing: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              isFrom
                  ? "- ${BigInt.parse(tr.value).toDouble() / 1e18}"
                  : "+ ${BigInt.parse(tr.value).toDouble() / 1e18}",
              style: GoogleFonts.roboto(
                  color: textColor, fontWeight: FontWeight.bold),
            ),
            TimerBuilder.periodic(
              Duration(seconds: 5),
              builder: (ctx) {
                return Text(
                  formatTimeElapsed(int.parse(tr.timeStamp)),
                  style: GoogleFonts.roboto(
                      color: textColor.withOpacity(0.5), fontSize: 12),
                );
              },
            )
          ],
        ),
      ),
    );
  }
}
