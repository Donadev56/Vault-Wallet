import 'package:flutter/material.dart';
import 'package:moonwallet/custom/candlesticks/lib/candlesticks.dart';
import 'package:moonwallet/custom/candlesticks/lib/src/utils/helper_functions.dart';
import 'package:moonwallet/types/types.dart';

class CandleInfoText extends StatelessWidget {
  final AppColors colors;
  const CandleInfoText({
    super.key,
    required this.candle,
    required this.colors,
  });

  final Candle candle;

  String numberFormat(int value) {
    return "${value < 10 ? 0 : ""}$value";
  }

  String dateFormatter(DateTime date) {
    return "${date.year}-${numberFormat(date.month)}-${numberFormat(date.day)} ${numberFormat(date.hour)}:${numberFormat(date.minute)}";
  }

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        text: dateFormatter(candle.date),
        style: TextStyle(color: colors.grayColor, fontSize: 10),
        children: <TextSpan>[
          TextSpan(text: " O:"),
          TextSpan(
              text: HelperFunctions.priceToString(candle.open),
              style: TextStyle(
                  color: candle.isBull ? colors.greenColor : colors.redColor)),
          TextSpan(text: " H:"),
          TextSpan(
              text: HelperFunctions.priceToString(candle.high),
              style: TextStyle(
                  color: candle.isBull ? colors.greenColor : colors.redColor)),
          TextSpan(text: " L:"),
          TextSpan(
              text: HelperFunctions.priceToString(candle.low),
              style: TextStyle(
                  color: candle.isBull ? colors.greenColor : colors.redColor)),
          TextSpan(text: " C:"),
          TextSpan(
              text: HelperFunctions.priceToString(candle.close),
              style: TextStyle(
                  color: candle.isBull ? colors.greenColor : colors.redColor)),
        ],
      ),
    );
  }
}
