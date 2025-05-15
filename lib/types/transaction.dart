import 'dart:convert';

import 'package:decimal/decimal.dart';
import 'package:moonwallet/types/account_related_types.dart';

enum SolInstruction { lamports, token, memo, unknown }

extension SolInstructionExtension on SolInstruction {
  String toShortString() => toString().split('.').last;

  static SolInstruction fromString(String value) {
    return SolInstruction.values.firstWhere((e) => e.toShortString() == value);
  }
}

abstract class Transaction {
  final String uiAmount;
  final String? networkFees;
  final String from;
  final String to;
  final String? status;
  final int timeStamp;
  final Crypto? token;
  final String transactionId;

  Transaction(
      {required this.from,
      this.networkFees,
      this.status,
      required this.timeStamp,
      required this.to,
      required this.uiAmount,
      this.token,
      required this.transactionId});

  Map<dynamic, dynamic> get metadata;
  Map<dynamic, dynamic> toJson();
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
  Map<dynamic, dynamic> get metadata => {};

  @override
  Map<dynamic, dynamic> toJson() => {
        "from": from,
        "to": to,
        "networkFees": networkFees,
        "timeStamp": timeStamp,
        "uiAmount": uiAmount,
        "status": status,
        "transactionId": transactionId,
        "token": token?.toJson()
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
  final int slot;

  SolanaTransaction(
      {required super.from,
      required super.networkFees,
      required super.timeStamp,
      required super.to,
      required super.uiAmount,
      required this.txId,
      required super.transactionId,
      required super.status,
      required this.slot,
      super.token});

  @override
  Map<String, dynamic> get metadata => {"TxId": txId, "Slot": slot};

  @override
  Map<dynamic, dynamic> toJson() {
    return {
      "from": from,
      "to": to,
      "networkFees": networkFees,
      "timeStamp": timeStamp,
      "uiAmount": uiAmount,
      "txId": txId,
      "token": token?.toJson(),
      "transactionId": transactionId,
      "slot": slot,
      "status": status,
    };
  }

  factory SolanaTransaction.fromJson(Map<dynamic, dynamic> json) {
    return SolanaTransaction(
      status: json["status"],
      slot: json["slot"],
      from: json["from"],
      to: json["to"],
      networkFees: json["networkFees"],
      timeStamp: json["timeStamp"],
      uiAmount: json["uiAmount"],
      txId: json["txId"],
      transactionId: json["transactionId"],
    );
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
      "token": token?.toJson(),
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

  List<Map<dynamic, dynamic>> toJson() {
    return map((e) => e.toJson()).toList();
  }
}

class AccountWithToken {
  final PublicAccount account;
  final Crypto token;

  AccountWithToken({required this.account, required this.token});
}
