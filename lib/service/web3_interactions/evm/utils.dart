import 'dart:typed_data';

import 'package:decimal/decimal.dart';
import 'package:moonwallet/logger/logger.dart';

class EthUtils {
  Uint8List hexToUint8List(String hex) {
    if (hex.startsWith("0x") || hex.startsWith("0X")) {
      hex = hex.substring(2);
    }
    if (hex.length % 2 != 0) {
      throw 'Odd number of hex digits';
    }
    var l = hex.length ~/ 2;
    var result = Uint8List(l);
    for (var i = 0; i < l; ++i) {
      var x = int.parse(hex.substring(2 * i, 2 * (i + 1)), radix: 16);
      if (x.isNaN) {
        throw 'Expected hex string';
      }
      result[i] = x;
    }
    return result;
  }




  BigInt parseHex(String hex) {
    log("Parsing hex $hex");
    if (hex.startsWith("0x")) {
      hex = hex.substring(2);
      log(hex);
      final hexParsed = BigInt.parse(hex, radix: 16);
      log("The hex parsed is $hexParsed");
      return hexParsed;
    }
    return BigInt.parse(hex, radix: 16);
  }

  BigInt ethToBigInt(String str, int decimals) {
    final value = Decimal.parse(str);
    final factor = Decimal.fromInt(10).pow(decimals);
    final result = value * factor.toDecimal();
    log("Multiplication result $result");
    return BigInt.parse((result).toStringAsFixed(0));
  }

  String bigIntToHex(BigInt value) {
    return "0x${(value).toRadixString(16)}";
  }
}
