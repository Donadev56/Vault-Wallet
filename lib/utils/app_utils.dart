import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:moonwallet/logger/logger.dart';

class AppUtils {
  static String getFormattedCurrency(BuildContext context, double value,
      {bool noDecimals = true, required String symbol}) {
    final germanFormat = NumberFormat.currency(
      symbol: symbol,
      decimalDigits: noDecimals && value % 1 == 0 ? 0 : 2,
    );
    return germanFormat.format(value);
  }
}

Future<String> getAvailableEthRpc(List<String> rpcUrls) async {
  for (final url in rpcUrls) {
    try {
      if (await isRpcAvailable(url)) {
        return url;
      }
    } catch (e) {
      logError(e.toString());
    }
  }
  return rpcUrls.firstOrNull ?? "";
}

Future<bool> isRpcAvailable(String rpcUrl) async {
  try {
    log("Checking rpc $rpcUrl");
    final response = await http.post(
      Uri.parse(rpcUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(
          {"jsonrpc": "2.0", "method": "eth_chainId", "params": [], "id": 1}),
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      return json['result'] != null;
    }
  } catch (e) {
    log("An error has occurred $e");
  }
  return false;
}
