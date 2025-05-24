import 'package:currency_formatter/currency_formatter.dart';
import 'package:decimal/decimal.dart';

class NumberFormatter {
  CurrencyFormat formatterSettings = CurrencyFormat(
    symbol: "",
    symbolSide: SymbolSide.left,
    thousandSeparator: ',',
    decimalSeparator: '.',
    symbolSeparator: ' ',
  );

  CurrencyFormat formatterSettingsCrypto = CurrencyFormat(
    symbol: "",
    symbolSide: SymbolSide.right,
    thousandSeparator: ',',
    decimalSeparator: '.',
    symbolSeparator: ' ',
  );

  String formatValue({required String str, int maxDecimals = 8}) {
    String formatted =
        CurrencyFormatter.format(str, formatterSettings, decimal: maxDecimals);
    if (formatted.contains('.')) {
      formatted = formatted.replaceAll(RegExp(r'0+$'), '');
      formatted = formatted.replaceAll(RegExp(r'\.$'), '');
    }
    return formatted.trim();
  }

  String formatCrypto({required double value, int maxDecimals = 8}) {
    String str = value.toStringAsFixed(maxDecimals);

    String formatted =
        CurrencyFormatter.format(str, formatterSettings, decimal: maxDecimals);
    if (formatted.contains('.')) {
      formatted = formatted.replaceAll(RegExp(r'0+$'), '');
      formatted = formatted.replaceAll(RegExp(r'\.$'), '');
    }
    return formatted.trim();
  }

  int getDecimalToUse(Decimal dec, int maxDec) {
    final integerPart = dec.truncate();
    final isLargeValue = integerPart >= Decimal.one;
    if (isLargeValue) {
      return 2;
    }
    final fixedDecimal = dec.toStringAsFixed(2);
    if (double.parse(fixedDecimal) > 0.09) {
      return 2;
    }

    return maxDec;
  }

  String formatDecimal(String numberStr, {int maxDecimals = 13}) {
    final dec = Decimal.parse(numberStr);
    final decimalsToUse = getDecimalToUse(dec, maxDecimals);

    final fixed = dec.toStringAsFixed(decimalsToUse);
    return fixed
        .replaceFirst(RegExp(r'0+$'), '')
        .replaceFirst(RegExp(r'\.$'), '');
  }

  /*

  String formatDecimal(String numberStr, {int maxDecimals = 13}) {
    final dec = Decimal.parse(numberStr);
    final fixed = dec.toStringAsFixed(maxDecimals);
    return fixed
        .replaceFirst(RegExp(r'0+$'), '')
        .replaceFirst(RegExp(r'\.$'), '');
  }
 */

/*
  String formatSmallDecimal(String numberStr, {int maxDecimals = 13}) {
    final dec = Decimal.parse(numberStr);
    final fixed = dec.toStringAsFixed(maxDecimals);

    if (!fixed.startsWith("0.")) return fixed;

    final decimalPart = fixed.split('.')[1];
    final match = RegExp(r'^(0+)(\d+)$').firstMatch(decimalPart);

    if (match != null) {
      final zeroCount = match.group(1)!.length;
      final significantDigits = match.group(2)!;
      return '0.(${zeroCount}z)$significantDigits';
    }

    return fixed;
  }
*/
  String formatUsd({required double value}) {
    String formatted =
        CurrencyFormatter.format(value, formatterSettingsCrypto, decimal: 2);
    if (formatted.contains('.')) {
      formatted = formatted.replaceAll(RegExp(r'0+$'), '');
      formatted = formatted.replaceAll(RegExp(r'\.$'), '');
    }
    return formatted;
  }
}
