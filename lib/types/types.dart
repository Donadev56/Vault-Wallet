import 'package:flutter/material.dart';

enum CryptoType { network, token }

class SecureData {
  final String privateKey;
  final String keyId;
  final int creationDate;
  final String walletName;
  final String? mnemonic;
  final String address;

  SecureData({
    required this.privateKey,
    required this.keyId,
    required this.creationDate,
    required this.walletName,
    this.mnemonic,
    required this.address,
  });

  factory SecureData.fromJson(Map<String, dynamic> json) {
    return SecureData(
      privateKey: json['privatekey'] as String,
      keyId: json['keyId'] as String,
      creationDate: json['creationDate'] as int,
      walletName: json['walletName'] as String,
      mnemonic: json['mnemonic'] as String,
      address: json['address'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'privatekey': privateKey,
      'keyId': keyId,
      'creationDate': creationDate,
      'walletName': walletName,
      'mnemonic': mnemonic,
      'address': address,
    };
  }
}

class SearchingContractInfo {
  final String name;
  final BigInt decimals;
  final String symbol;

  SearchingContractInfo({
    required this.name,
    required this.decimals,
    required this.symbol,
  });

  factory SearchingContractInfo.fromMap(Map<String, dynamic> map) {
    return SearchingContractInfo(
      name: map['name'] as String,
      decimals: BigInt.parse(map['decimals'] as String),
      symbol: map['symbol'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'decimals': decimals.toString(),
      'symbol': symbol,
    };
  }
}

class PinSubmitResult {
  final bool success;
  final bool repeat;
  final String? error;
  final String? newTitle;

  PinSubmitResult({
    required this.success,
    required this.repeat,
    this.error,
    this.newTitle,
  });

  factory PinSubmitResult.fromMap(Map<String, dynamic> map) {
    return PinSubmitResult(
      success: map['success'] as bool,
      repeat: map['repeat'] as bool,
      error: map['error'] as String?,
      newTitle: map['newTitle'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'success': success,
      'repeat': repeat,
      'error': error,
      'newTitle': newTitle,
    };
  }
}

class PublicData {
  final String keyId;
  final int creationDate;
  final String walletName;
  final String address;
  final bool isWatchOnly;

  PublicData({
    required this.keyId,
    required this.creationDate,
    required this.walletName,
    required this.address,
    required this.isWatchOnly,
  });

  factory PublicData.fromJson(Map<String, dynamic> json) {
    return PublicData(
      keyId: json['keyId'] as String,
      creationDate: json['creationDate'] as int,
      walletName: json['walletName'] as String,
      address: json['address'] as String,
      isWatchOnly: json['isWatchOnly'] as bool,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'keyId': keyId,
      'creationDate': creationDate,
      'walletName': walletName,
      'address': address,
      'isWatchOnly': isWatchOnly,
    };
  }
}

class DApp {
  final String name;
  final String icon;
  final String description;
  final String link;
  final bool isNetworkImage;

  DApp({
    required this.name,
    required this.icon,
    required this.description,
    required this.link,
    required this.isNetworkImage,
  });

  factory DApp.fromJson(Map<String, dynamic> json) {
    return DApp(
      name: json['name'],
      icon: json['icon'],
      description: json['description'],
      link: json['link'],
      isNetworkImage: json['isNetworkImage'] as bool,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'icon': icon,
      'description': description,
      'link': link,
      'isNetworkImage': isNetworkImage,
    };
  }
}

class EthTransaction {
  final String from;
  final String to;
  final String data;
  final String? gas;
  final String value;

  EthTransaction({
    required this.from,
    required this.to,
    required this.data,
    this.gas,
    required this.value,
  });

  factory EthTransaction.fromJson(Map<String, dynamic> json) {
    return EthTransaction(
      from: json['from'],
      to: json['to'],
      data: json['data'],
      gas: json['gas'],
      value: json['value'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'from': from,
      'to': to,
      'data': data,
      'gas': gas,
      'value': value,
    };
  }
}

class Crypto {
  final String name;
  final String? icon;
  final int? chainId;
  final Crypto? network;
  final Color? color;
  final String? rpc;
  final String? binanceSymbol;
  final String? explorer;
  final CryptoType type;
  final String? contractAddress;
  final int? decimals;
  final double valueUsd;
  final String cryptoId;
  final bool canDisplay;
  final String? apiKey;
  final String? apiBaseUrl;
  final String symbol;

  Crypto(
      {required this.name,
      this.icon,
      this.chainId,
      required this.color,
      this.rpc,
      this.binanceSymbol,
      required this.type,
      this.explorer,
      this.network,
      this.contractAddress,
      this.decimals,
      required this.valueUsd,
      required this.cryptoId,
      required this.canDisplay,
      this.apiKey,
      this.apiBaseUrl,
      required this.symbol});

  factory Crypto.fromJson(Map<String, dynamic> cryptoJson) {
    return Crypto(
        apiKey: cryptoJson["apiKey"],
        apiBaseUrl: cryptoJson["apiBaseUrl"],
        canDisplay: cryptoJson["canDisplay"],
        cryptoId: cryptoJson["cryptoId"],
        name: cryptoJson["name"],
        color: Color(cryptoJson["color"]),
        type: CryptoType.values[cryptoJson["type"]],
        icon: cryptoJson["icon"],
        rpc: cryptoJson["rpc"],
        decimals: cryptoJson["decimals"],
        chainId: cryptoJson["chainId"],
        binanceSymbol: cryptoJson["binanceSymbol"],
        network: cryptoJson["network"] != null
            ? Crypto.fromJson(cryptoJson["network"])
            : null,
        contractAddress: cryptoJson["contractAddress"],
        explorer: cryptoJson["explorer"],
        valueUsd: cryptoJson["valueUsd"],
        symbol: cryptoJson["symbol"]);
  }

  Map<String, dynamic> toJson() {
    return {
      "apiKey": apiKey,
      "apiBaseUrl": apiBaseUrl,
      "canDisplay": canDisplay,
      "cryptoId": cryptoId,
      "name": name,
      "color": color?.value ?? Colors.orangeAccent.value,
      "type": type.index,
      "icon": icon,
      "rpc": rpc,
      "decimals": decimals,
      "chainId": chainId,
      "binanceSymbol": binanceSymbol,
      "network": network?.toJson(),
      "contractAddress": contractAddress,
      "explorer": explorer,
      "valueUsd": valueUsd,
      "symbol": symbol
    };
  }
}

class Cryptos {
  final List<Crypto> networks;

  Cryptos({required this.networks});

  factory Cryptos.fromJson(List<dynamic> jsonList) {
    return Cryptos(
      networks: jsonList.map((json) => Crypto.fromJson(json)).toList(),
    );
  }

  List<Map<String, dynamic>> toJson() {
    return networks.map((network) => network.toJson()).toList();
  }
}

class HistoryItem {
  final String link;
  final String title;

  HistoryItem({
    required this.link,
    required this.title,
  });

  // Convert a JSON Map to a HistoryItem instance
  factory HistoryItem.fromJson(Map<String, dynamic> json) {
    return HistoryItem(
      link: json['link'],
      title: json['title'],
    );
  }

  // Convert a HistoryItem instance to a JSON Map
  Map<String, dynamic> toJson() {
    return {
      'link': link,
      'title': title,
    };
  }
}

class History {
  final List<HistoryItem> history;

  History({required this.history});

  // Convert a JSON List to a History instance
  factory History.fromJson(List<dynamic> jsonList) {
    return History(
      history: jsonList.map((json) => HistoryItem.fromJson(json)).toList(),
    );
  }

  // Convert a History instance to a JSON List
  List<Map<String, dynamic>> toJson() {
    return history.map((item) => item.toJson()).toList();
  }
}

class UserRequestResponse {
  final bool ok;
  final BigInt gasPrice;
  final BigInt gasLimit;

  UserRequestResponse({
    required this.ok,
    required this.gasPrice,
    required this.gasLimit,
  });

  // Convert a JSON Map to a HistoryItem instance
  factory UserRequestResponse.fromJson(Map<String, dynamic> json) {
    return UserRequestResponse(
      ok: json['ok'],
      gasPrice: BigInt.parse(json['gasPrice']),
      gasLimit: BigInt.parse(json['gasLimit']),
    );
  }

  // Convert a HistoryItem instance to a JSON Map
  Map<String, dynamic> toJson() {
    return {
      'ok': ok,
      'gasPrice': gasPrice.toString(),
      'gasLimit': gasLimit.toString(),
    };
  }
}

class BscScanTransaction {
  final String blockNumber;
  final String timeStamp;
  final String hash;
  final String from;
  final String to;
  final String value;
  final String? gas;
  final String? gasUsed;
  final String? gasPrice;
  final String? isError;
  final String? txreceiptStatus;
  final String? input;
  final String? contractAddress;
  final String? methodId;
  final String? functionName;

  BscScanTransaction({
    required this.blockNumber,
    required this.timeStamp,
    required this.hash,
    required this.from,
    required this.to,
    required this.value,
    this.gas,
    this.gasUsed,
    this.gasPrice,
    this.isError,
    this.txreceiptStatus,
    this.input,
    this.contractAddress,
    this.methodId,
    this.functionName,
  });

  factory BscScanTransaction.fromJson(Map<String, dynamic> json) {
    return BscScanTransaction(
      blockNumber: json['blockNumber'] ?? '',
      timeStamp: json['timeStamp'] ?? '',
      hash: json['hash'] ?? '',
      from: json['from'] ?? '',
      to: json['to'] ?? '',
      value: json['value'] ?? '',
      gas: json['gas'] ?? '',
      gasUsed: json['gasUsed'] ?? '',
      gasPrice: json['gasPrice'] ?? '',
      isError: json['isError'] ?? '',
      txreceiptStatus: json['txreceipt_status'] ?? '',
      input: json['input'] ?? '',
      contractAddress: json['contractAddress'] ?? '',
      methodId: json['methodId'] ?? '',
      functionName: json['functionName'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'blockNumber': blockNumber,
      'timeStamp': timeStamp,
      'hash': hash,
      'from': from,
      'to': to,
      'value': value,
      'gas': gas,
      'gasUsed': gasUsed,
      'gasPrice': gasPrice,
      'isError': isError,
      'txreceipt_status': txreceiptStatus,
      'input': input,
      'contractAddress': contractAddress,
      'methodId': methodId,
      'functionName': functionName,
    };
  }
}

class TransactionListResponseType {
  final String status;
  final String message;
  final List<BscScanTransaction> result;

  TransactionListResponseType({
    required this.status,
    required this.message,
    required this.result,
  });

  factory TransactionListResponseType.fromJson(Map<String, dynamic> json) {
    return TransactionListResponseType(
      status: json['status'] ?? '',
      message: json['message'] ?? '',
      result: (json['result'] as List<dynamic>?)
              ?.map((e) => BscScanTransaction.fromJson(e))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'message': message,
      'result': result.map((tx) => tx.toJson()).toList(),
    };
  }
}

class Balance {
  final Crypto crypto;
  final double balanceUsd;
  final double balanceCrypto;
  final double cryptoTrendPercent;
  final double cryptoPrice;

  Balance({
    required this.crypto,
    required this.balanceUsd,
    required this.balanceCrypto,
    required this.cryptoTrendPercent,
    required this.cryptoPrice,
  });

  // Convert a JSON Map to a HistoryItem instance
  factory Balance.fromJson(Map<String, dynamic> json) {
    return Balance(
      crypto: Crypto.fromJson(json['crypto']),
      balanceUsd: json['balanceUsd'] ?? 0,
      balanceCrypto: json['balanceCrypto'] ?? 0,
      cryptoTrendPercent: json['cryptoTrendPercent'] ?? 0,
      cryptoPrice: json['cryptoPrice'] ?? 0,
    );
  }

  // Convert a HistoryItem instance to a JSON Map
  Map<String, dynamic> toJson() {
    return {
      'crypto': crypto.toJson(),
      'balanceUsd': balanceUsd,
      'balanceCrypto': balanceCrypto,
      'cryptoTrendPercent': cryptoTrendPercent,
      'cryptoPrice': cryptoPrice,
    };
  }
}
