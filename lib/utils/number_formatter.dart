import 'package:currency_formatter/currency_formatter.dart';

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

  String formatCrypto({required String value}) {
    String formatted =
        CurrencyFormatter.format(value, formatterSettings, decimal: 8);
    if (formatted.contains('.')) {
      formatted = formatted.replaceAll(RegExp(r'0+$'), '');
      formatted = formatted.replaceAll(RegExp(r'\.$'), '');
    }
    return formatted;
  }

  String formatUsd({required String value}) {
    String formatted =
        CurrencyFormatter.format(value, formatterSettingsCrypto, decimal: 2);
    if (formatted.contains('.')) {
      formatted = formatted.replaceAll(RegExp(r'0+$'), '');
      formatted = formatted.replaceAll(RegExp(r'\.$'), '');
    }
    return formatted;
  }
}
