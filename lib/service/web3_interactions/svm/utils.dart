import 'package:decimal/decimal.dart';

class SolanaUtils {
  String solToLamportsString(String amount) {
    return (Decimal.parse(amount) * Decimal.fromInt(10).pow(9).toDecimal())
        .toStringAsFixed(0);
  }

  String parseTokenAmount(String amount, int decimals) {
    return (Decimal.parse(amount) *
            Decimal.fromInt(10).pow(decimals).toDecimal())
        .toStringAsFixed(0);
  }

  Decimal solToLamportsDecimal(String amount) {
    return Decimal.parse(amount) * Decimal.fromInt(10).pow(9).toDecimal();
  }
}
