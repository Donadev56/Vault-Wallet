import 'dart:convert';

import 'package:decimal/decimal.dart';
import 'package:moonwallet/logger/logger.dart';
import 'package:moonwallet/types/account_related_types.dart';

abstract class Transaction {
  final String uiAmount;
  final String? networkFees;
  final String from;
  final String to;
  final String? status;
  final int timeStamp;
  final Crypto token;
  final String transactionId;

  Transaction(
      {required this.from,
      this.networkFees,
      this.status,
      required this.timeStamp,
      required this.to,
      required this.uiAmount,
      required this.token,
      required this.transactionId});

  Map<String, dynamic> get metadata;
  Map<String, dynamic> toJson();
}

class StandardTransaction extends Transaction {
  StandardTransaction({
    required super.from,
    required super.to,
    super.networkFees,
    required super.timeStamp,
    required super.uiAmount,
    super.status,
    required super.token,
    required super.transactionId,
  });

  @override
  Map<String, dynamic> get metadata => {};

  @override
  Map<String, dynamic> toJson() => {
        "from": from,
        "to": to,
        "networkFees": networkFees,
        "timeStamp": timeStamp,
        "uiAmount": uiAmount,
        "status": status,
        "transactionId": transactionId,
        "token": token.toJson()
      };

  factory StandardTransaction.fromJson(Map<String, dynamic> json) {
    return StandardTransaction(
        from: json["from"],
        to: json["to"],
        networkFees: json["networkFees"],
        timeStamp: json["timeStamp"],
        uiAmount: json["uiAmount"],
        status: json["status"],
        transactionId: json["transactionId"],
        token: Crypto.fromJson(json["token"]));
  }
}

class SolanaTransaction extends Transaction {
  final String txId;

  SolanaTransaction(
      {required super.from,
      required super.networkFees,
      required super.timeStamp,
      required super.to,
      required super.uiAmount,
      required this.txId,
      required super.transactionId,
      required super.token});

  @override
  Map<String, dynamic> get metadata => {
        "txId": txId,
      };

  @override
  Map<String, dynamic> toJson() {
    return {
      "from": from,
      "to": to,
      "networkFees": networkFees,
      "timeStamp": timeStamp,
      "uiAmount": uiAmount,
      "txId": txId,
      "token": token.toJson(),
      "transactionId": transactionId,
    };
  }

  factory SolanaTransaction.fromJson(Map<String, dynamic> json) {
    return SolanaTransaction(
        from: json["from"],
        to: json["to"],
        networkFees: json["networkFees"],
        timeStamp: json["timeStamp"],
        uiAmount: json["uiAmount"],
        txId: json["txId"],
        transactionId: json["transactionId"],
        token: Crypto.fromJson(json["token"]));
  }
}

class EthereumTransaction extends Transaction {
  final String hash;
  final String blockNumber;

  EthereumTransaction(
      {required super.transactionId,
      required super.token,
      required super.from,
      required super.networkFees,
      required super.timeStamp,
      required super.to,
      required super.uiAmount,
      required this.hash,
      required this.blockNumber,
      required super.status});

  @override
  Map<String, dynamic> get metadata => {
        "Hash": hash,
        "Block": blockNumber,
      };

  @override
  Map<String, dynamic> toJson() {
    return {
      "from": from,
      "to": to,
      "networkFees": networkFees,
      "timeStamp": timeStamp,
      "uiAmount": uiAmount,
      "hash": hash,
      "nonce": blockNumber,
      "token": token.toJson(),
      "transactionId": transactionId,
      "blockNumber": blockNumber,
      "status": status
    };
  }

  factory EthereumTransaction.fromInternalJson(Map<dynamic, dynamic> json,
      {required Crypto token}) {
    return EthereumTransaction(
        from: json["from"] ?? "",
        to: json["to"] ?? "",
        networkFees: null,
        timeStamp: json["timeStamp"] != null
            ? (json["timeStamp"] is String
                ? int.parse(json["timeStamp"])
                : json["timeStamp"])
            : 0,
        uiAmount: json["uiAmount"],
        hash: json["hash"] ?? "",
        blockNumber: json["blockNumber"] ?? "",
        transactionId: json["hash"],
        status: json["status"],
        token: token);
  }
  factory EthereumTransaction.fromJson(Map<dynamic, dynamic> json,
      {required Crypto token}) {
    final value = json["value"];
    String uiAmount = "0";
    if (value != null) {
      final decimalAmount = Decimal.parse(value);
      final decimals = Decimal.fromInt(10).pow(token.decimals);
      final amountEth = (decimalAmount / decimals.toDecimal());
      uiAmount = amountEth.toDecimal().toString();
    }
    final txReceipt = json["txreceipt_status"];
    String status = "";
    switch (txReceipt) {
      case null:
        status = "...";
      case "1":
        status = "success";
      case "0":
        status = "Fail";
      default:
        status = "unknown";
    }

    return EthereumTransaction(
        status: status,
        from: json["from"] ?? "",
        to: json["to"] ?? "",
        networkFees: null,
        timeStamp: json["timeStamp"] != null
            ? (json["timeStamp"] is String
                ? int.parse(json["timeStamp"])
                : json["timeStamp"])
            : 0,
        uiAmount: uiAmount,
        hash: json["hash"] ?? "",
        blockNumber: json["blockNumber"] ?? "",
        transactionId: json["hash"],
        token: token);
  }
}

extension TransactionJson on List<Transaction> {
  String toJsonString() {
    return json.encode(toJson());
  }

  List<Map<String, dynamic>> toJson() {
    return map((e) => e.toJson()).toList();
  }
}

class AccountWithToken {
  final PublicAccount account;
  final Crypto token;

  AccountWithToken({required this.account, required this.token});
}
