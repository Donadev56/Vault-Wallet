// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:web3dart/credentials.dart';

enum CryptoType { native, token }

enum ColorType { dark, light, other }

enum MessageType { success, error, warning, info }

enum SignatureRequestType { ethPersonalSign, ethSign, ethSignTypedData }

extension IconJson on IconData {
  Map<dynamic, dynamic> toJson() => {
        'codePoint': codePoint,
        'fontFamily': fontFamily,
        'fontPackage': fontPackage,
        'matchTextDirection': matchTextDirection,
      };
}

class SecureData {
  final String privateKey;
  final String keyId;
  final int creationDate;
  final String walletName;
  final String? mnemonic;
  final String address;
  final bool createdLocally;
  final bool isBackup;

  SecureData(
      {required this.createdLocally,
      required this.privateKey,
      required this.keyId,
      required this.creationDate,
      required this.walletName,
      this.mnemonic,
      required this.address,
      required this.isBackup});

  factory SecureData.fromJson(Map<dynamic, dynamic> json) {
    return SecureData(
        privateKey: json['privatekey'],
        keyId: json['keyId'] ?? "",
        creationDate: json['creationDate'] ?? 0,
        walletName: json['walletName'] ?? "",
        mnemonic: json['mnemonic'],
        address: json['address'] ?? "",
        createdLocally: json["createdLocally"] ?? false,
        isBackup: json["isBackup"] ?? false);
  }

  Map<String, dynamic> toJson() {
    return {
      'privatekey': privateKey,
      'keyId': keyId,
      'creationDate': creationDate,
      'walletName': walletName,
      'mnemonic': mnemonic,
      'address': address,
      "createdLocally": createdLocally,
      "isBackup": isBackup
    };
  }

  SecureData copyWith({
    String? privateKey,
    String? keyId,
    int? creationDate,
    String? walletName,
    String? mnemonic,
    String? address,
    bool? isBackup,
    bool? createdLocally,
  }) {
    return SecureData(
        privateKey: privateKey ?? this.privateKey,
        keyId: keyId ?? this.keyId,
        creationDate: creationDate ?? this.creationDate,
        walletName: walletName ?? this.walletName,
        mnemonic: mnemonic ?? this.mnemonic,
        address: address ?? this.address,
        createdLocally: createdLocally ?? this.createdLocally,
        isBackup: isBackup ?? this.isBackup);
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

  factory SearchingContractInfo.fromMap(Map<dynamic, dynamic> map) {
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

  factory PinSubmitResult.fromMap(Map<dynamic, dynamic> map) {
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
  int id;
  final String keyId;
  final int creationDate;
  final String walletName;
  final String address;
  final bool isWatchOnly;
  final IconData? walletIcon;
  final Color? walletColor;
  final bool isBackup;
  final bool createdLocally;

  PublicData(
      {required this.keyId,
      required this.creationDate,
      required this.walletName,
      required this.address,
      required this.isWatchOnly,
      this.walletIcon = LucideIcons.wallet,
      this.walletColor = Colors.transparent,
      this.isBackup = false,
      required this.createdLocally,
      this.id = 0});

  factory PublicData.fromJson(Map<dynamic, dynamic> json) {
    return PublicData(
        keyId: json['keyId'] as String,
        creationDate: json['creationDate'] as int,
        walletName: json['walletName'] as String,
        address: json['address'] as String,
        isWatchOnly: json['isWatchOnly'] as bool,
        walletIcon: json["walletIcon"] != null
            ? IconData(json['walletIcon']["codePoint"],
                fontFamily: json['walletIcon']['fontFamily'],
                matchTextDirection: json['walletIcon']["matchTextDirection"],
                fontPackage: json['walletIcon']['fontPackage'])
            : Icons.wallet,
        walletColor: json['walletColor'] != null
            ? Color(json['walletColor'] ?? 0x00000000)
            : Colors.transparent,
        id: json['id'] ?? 0,
        isBackup: json["isBackup"] ?? false,
        createdLocally: json["createdLocally"] ?? false);
  }

  Map<String, dynamic> toJson() {
    return {
      'keyId': keyId,
      'creationDate': creationDate,
      'walletName': walletName,
      'address': address,
      'isWatchOnly': isWatchOnly,
      'walletIcon': walletIcon?.toJson() ?? Icons.wallet.toJson(),
      'walletColor': walletColor?.value ?? Colors.transparent.value,
      'id': id,
      "isBackup": isBackup,
      "createdLocally": createdLocally
    };
  }

  PublicData copyWith({
    int? id,
    String? keyId,
    int? creationDate,
    String? walletName,
    String? address,
    bool? isWatchOnly,
    IconData? walletIcon,
    Color? walletColor,
    bool? isBackup,
    bool? createdLocally,
  }) {
    return PublicData(
        id: id ?? this.id,
        keyId: keyId ?? this.keyId,
        creationDate: creationDate ?? this.creationDate,
        walletName: walletName ?? this.walletName,
        address: address ?? this.address,
        isWatchOnly: isWatchOnly ?? this.isWatchOnly,
        walletIcon: walletIcon ?? this.walletIcon,
        walletColor: walletColor ?? this.walletColor,
        isBackup: isBackup ?? this.isBackup,
        createdLocally: createdLocally ?? this.createdLocally);
  }
}

class DApp {
  int id;
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
    this.id = 0,
  });

  factory DApp.fromJson(Map<String, dynamic> json) {
    return DApp(
      name: json['name'],
      icon: json['icon'],
      description: json['description'],
      link: json['link'],
      isNetworkImage: json['isNetworkImage'] as bool,
      id: json['id'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'icon': icon,
      'description': description,
      'link': link,
      'isNetworkImage': isNetworkImage,
      'id': id,
    };
  }
}

class EthTransaction {
  int id;
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
    this.id = 0,
  });

  factory EthTransaction.fromJson(Map<String, dynamic> json) {
    return EthTransaction(
      from: json['from'],
      to: json['to'],
      data: json['data'],
      gas: json['gas'],
      value: json['value'],
      id: json['id'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'from': from,
      'to': to,
      'data': data,
      'gas': gas,
      'value': value,
      'id': id,
    };
  }
}

class Crypto {
  final String name;
  final String? icon;
  final int? chainId;
  final Crypto? network;
  final Color? color;
  final List<String>? rpcUrls;
  final List<String>? explorers;
  final CryptoType type;
  final String? contractAddress;
  final int decimals;
  final double valueUsd;
  final String cryptoId;
  final bool canDisplay;
  final String symbol;
  final String? cgSymbol;

  Crypto(
      {required this.name,
      this.icon,
      this.chainId,
      required this.color,
      this.rpcUrls,
      required this.type,
      this.explorers,
      this.network,
      this.contractAddress,
      required this.decimals,
      required this.valueUsd,
      required this.cryptoId,
      required this.canDisplay,
      required this.symbol,
      this.cgSymbol});
  factory Crypto.fromJsonRequest(Map<String, dynamic> cryptoJson) {
    return Crypto(
        canDisplay: cryptoJson["canDisplay"],
        cryptoId: cryptoJson["cryptoId"],
        name: cryptoJson["name"],
        color: Color(cryptoJson["color"] ?? 0x00000000),
        type: CryptoType.values[cryptoJson["type"]],
        icon: cryptoJson["icon"],
        rpcUrls: cryptoJson["rpcUrls"] != null
            ? (cryptoJson["rpcUrls"] as List<dynamic>)
                .map((e) => e.toString())
                .toList()
            : null,
        decimals: cryptoJson["decimals"],
        chainId: cryptoJson["chainId"],
        network: cryptoJson["network"] != null
            ? Crypto.fromJsonRequest(cryptoJson["network"])
            : null,
        contractAddress: cryptoJson["contractAddress"],
        explorers: cryptoJson["explorers"] != null
            ? (cryptoJson["explorers"] as List<dynamic>)
                .map((e) => e.toString())
                .toList()
            : null,
        valueUsd: cryptoJson["valueUsd"],
        symbol: cryptoJson["symbol"],
        cgSymbol: cryptoJson["cgSymbol"] ?? "");
  }

  factory Crypto.fromJson(Map<String, dynamic> cryptoJson) {
    return Crypto(
        canDisplay: cryptoJson["canDisplay"],
        cryptoId: cryptoJson["cryptoId"],
        name: cryptoJson["name"],
        color: cryptoJson["color"] != null
            ? Color(cryptoJson["color"])
            : Colors.transparent,
        type: CryptoType.values[cryptoJson["type"]],
        icon: cryptoJson["icon"],
        rpcUrls: cryptoJson["rpcUrls"] != null
            ? (cryptoJson["rpcUrls"] as List<dynamic>)
                .map((e) => e.toString())
                .toList()
            : null,
        decimals: cryptoJson["decimals"] ?? 18,
        chainId: cryptoJson["chainId"],
        network: cryptoJson["network"] != null
            ? Crypto.fromJson(cryptoJson["network"])
            : null,
        contractAddress: cryptoJson["contractAddress"],
        explorers: cryptoJson["explorers"] != null
            ? (cryptoJson["explorers"] as List<dynamic>)
                .map((e) => e.toString())
                .toList()
            : null,
        valueUsd: cryptoJson["valueUsd"] ?? 0,
        symbol: cryptoJson["symbol"],
        cgSymbol: cryptoJson["cgSymbol"] ?? "");
  }

  Map<String, dynamic> toJson() {
    return {
      "canDisplay": canDisplay,
      "cryptoId": cryptoId,
      "name": name,
      "color": color?.value ?? Colors.orangeAccent.value,
      "type": type.index,
      "icon": icon,
      "rpcUrls": rpcUrls,
      "decimals": decimals,
      "chainId": chainId,
      "network": network?.toJson(),
      "contractAddress": contractAddress,
      "explorers": explorers,
      "valueUsd": valueUsd,
      "symbol": symbol,
      "cgSymbol": cgSymbol,
    };
  }

  bool get isNative => type == CryptoType.native;

  Crypto copyWith({
    String? name,
    String? icon,
    int? chainId,
    Crypto? network,
    Color? color,
    List<String>? rpcUrls,
    List<String>? explorers,
    CryptoType? type,
    String? contractAddress,
    int? decimals,
    double? valueUsd,
    String? cryptoId,
    bool? canDisplay,
    String? symbol,
    String? cgSymbol,
  }) {
    return Crypto(
      name: name ?? this.name,
      icon: icon ?? this.icon,
      chainId: chainId ?? this.chainId,
      network: network ?? this.network,
      color: color ?? this.color,
      rpcUrls: rpcUrls ?? this.rpcUrls,
      explorers: explorers ?? this.explorers,
      type: type ?? this.type,
      contractAddress: contractAddress ?? this.contractAddress,
      decimals: decimals ?? this.decimals,
      valueUsd: valueUsd ?? this.valueUsd,
      cryptoId: cryptoId ?? this.cryptoId,
      canDisplay: canDisplay ?? this.canDisplay,
      symbol: symbol ?? this.symbol,
      cgSymbol: cgSymbol ?? this.cgSymbol,
    );
  }
}

class Cryptos {
  final List<Crypto> networks;

  Cryptos({
    required this.networks,
  });

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
  int id;
  final String link;
  final String title;

  HistoryItem({
    required this.link,
    required this.title,
    this.id = 0,
  });

  // Convert a JSON Map to a HistoryItem instance
  factory HistoryItem.fromJson(Map<String, dynamic> json) {
    return HistoryItem(
      link: json['link'],
      title: json['title'],
      id: json['id'] ?? 0,
    );
  }

  // Convert a HistoryItem instance to a JSON Map
  Map<String, dynamic> toJson() {
    return {
      'link': link,
      'title': title,
      'id': id,
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
  final BigInt? gasPrice;
  final BigInt? gasLimit;

  UserRequestResponse({
    required this.ok,
    this.gasPrice,
    this.gasLimit,
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

class EsTransaction {
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

  EsTransaction({
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

  factory EsTransaction.fromJson(Map<dynamic, dynamic> json) {
    return EsTransaction(
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

  Map<dynamic, dynamic> toJson() {
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
  final List<EsTransaction> result;

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
              ?.map((e) => EsTransaction.fromJson(e))
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

class Asset {
  final Crypto crypto;
  final double balanceUsd;
  final double balanceCrypto;
  final double cryptoTrendPercent;
  final double cryptoPrice;
  final CryptoMarketData? marketData;

  Asset(
      {required this.crypto,
      required this.balanceUsd,
      required this.balanceCrypto,
      required this.cryptoTrendPercent,
      required this.cryptoPrice,
      this.marketData});

  // Convert a JSON Map to a HistoryItem instance
  factory Asset.fromJson(Map<String, dynamic> json) {
    return Asset(
        crypto: Crypto.fromJson(json['crypto']),
        balanceUsd: json['balanceUsd'] ?? 0,
        balanceCrypto: json['balanceCrypto'] ?? 0,
        cryptoTrendPercent: json['cryptoTrendPercent'] ?? 0,
        cryptoPrice: json['cryptoPrice'] ?? 0,
        marketData: json["marketData"] != null
            ? CryptoMarketData.fromJson(json["marketData"])
            : null);
  }

  // Convert a HistoryItem instance to a JSON Map
  Map<String, dynamic> toJson() {
    return {
      'crypto': crypto.toJson(),
      'balanceUsd': balanceUsd,
      'balanceCrypto': balanceCrypto,
      'cryptoTrendPercent': cryptoTrendPercent,
      'cryptoPrice': cryptoPrice,
      "marketData": marketData?.toJson()
    };
  }
}

class AppColors {
  final Color primaryColor;
  final Color themeColor;
  final Color greenColor;
  final Color secondaryColor;
  final Color grayColor;
  final Color textColor;
  final Color redColor;
  final ColorType type;

  const AppColors({
    required this.primaryColor,
    required this.themeColor,
    required this.greenColor,
    required this.secondaryColor,
    required this.grayColor,
    required this.textColor,
    required this.type,
    required this.redColor,
  });

  static const defaultTheme =  AppColors(
      primaryColor: Color(0XFFFFFFFF),
      themeColor: Colors.lightBlueAccent,
      greenColor: const Color.fromARGB(255, 0, 175, 90),
      secondaryColor: Color(0XFFF0F0F0),
      grayColor: Color(0XFFBDBDBD),
      textColor: Colors.black,
      redColor: Colors.redAccent,
      type: ColorType.light);

 

  Map<dynamic, dynamic> toJson() {
    return {
      'primaryColor': primaryColor.value,
      'themeColor': themeColor.value,
      'greenColor': greenColor.value,
      'secondaryColor': secondaryColor.value,
      'grayColor': grayColor.value,
      'textColor': textColor.value,
      'redColor': redColor.value,
      'type': type.index,
    };
  }

  factory AppColors.fromJson(Map<dynamic, dynamic> json) {
    return AppColors(
      type: ColorType.values[(json['type'] is int)
          ? json['type']
          : int.tryParse(json['type'].toString()) ?? 0],
      primaryColor: Color(json['primaryColor'] ?? Colors.black.value),
      themeColor: Color(json['themeColor'] ?? Colors.black.value),
      greenColor: Color(json['greenColor'] ?? Colors.black.value),
      secondaryColor: Color(json['secondaryColor'] ?? Colors.black.value),
      grayColor: Color(json['grayColor'] ?? Colors.black.value),
      textColor: Color(json['textColor'] ?? Colors.black.value),
      redColor: Color(json['redColor'] ?? Colors.black.value),
    );
  }
}

class Option {
  final String title;
  final Widget icon;
  final double iconSize;
  final Widget trailing;
  final Widget? subtitle;
  final Color color;
  final TextStyle? titleStyle;
  final Color? tileColor;
  final Color? splashColor;
  final void Function()? onPressed;

  Option(
      {required this.title,
      required this.icon,
      required this.trailing,
      required this.color,
      this.titleStyle,
      this.tileColor,
      this.subtitle,
      this.splashColor,
      this.onPressed,
      this.iconSize = 30});

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'icon': icon.runtimeType.toString(),
      'trailing': trailing.runtimeType.toString(),
      'color': color.value,
      'titleStyle': titleStyle?.toString(),
      'tileColor': tileColor?.value,
      'subtitle': subtitle?.runtimeType.toString(),
    };
  }

  factory Option.fromJson(Map<String, dynamic> json) {
    return Option(
      title: json['title'],
      icon: json['icon'] == 'Icon' ? Icon(Icons.home) : SizedBox(),
      trailing: json['trailing'] == ' SizedBox' ? SizedBox() : SizedBox(),
      color: Color(json['color']),
      tileColor: json['tileColor'] != null ? Color(json['tileColor']) : null,
      subtitle: json['subtitle'] == ' SizedBox' ? SizedBox() : SizedBox(),
    );
  }

  @override
  String toString() {
    return 'Option(title: $title, icon: $icon, trailing: $trailing, color: $color )';
  }
}

class TransactionDetails {
  final String from;
  final String to;
  final String value;
  final String timeStamp;
  final String hash;
  final String blockNumber;
  final String status;

  TransactionDetails(
      {required this.from,
      required this.to,
      required this.value,
      required this.timeStamp,
      required this.hash,
      required this.blockNumber,
      required this.status});
  Map<String, dynamic> toJson() {
    return {
      'from': from,
      'to': to,
      'value': value,
      'timeStamp': timeStamp,
      'hash': hash,
      'blockNumber': blockNumber,
      "status": status
    };
  }

  factory TransactionDetails.fromJson(Map<String, dynamic> json) {
    return TransactionDetails(
        from: json['from'],
        to: json['to'],
        value: json['value'],
        timeStamp: json['timeStamp'],
        hash: json['hash'],
        blockNumber: json['blockNumber'],
        status: json["status"] ?? "");
  }
}

class WidgetInitialData {
  final Crypto crypto;
  final AppColors colors;
  final double? initialBalanceUsd;
  final double? initialBalanceCrypto;
  final PublicData account;
  final double? cryptoPrice;

  WidgetInitialData({
    required this.account,
    required this.crypto,
    this.initialBalanceCrypto,
    this.initialBalanceUsd,
    this.cryptoPrice,
    required this.colors,
  });
}

class DataWithCache {
  final int lastUpdate;
  final int validationTime;
  final String currentData;
  final List<String> lastVersions;

  DataWithCache(
      {required this.currentData,
      required this.lastUpdate,
      required this.lastVersions,
      required this.validationTime});

  factory DataWithCache.fromJson(Map<String, dynamic> json) {
    return DataWithCache(
        currentData: json["current_data"],
        lastUpdate: json["lastUpdate"],
        validationTime: json["validationTime"],
        lastVersions: json["last_versions"]);
  }

  Map<dynamic, dynamic> toJson() {
    return {
      "lastUpdate": lastUpdate,
      "validationTime": validationTime,
      "current_data": currentData,
      "last_versions": lastVersions
    };
  }
}

class TradeData {
  final double price;
  final String binanceSymbol;

  TradeData({required this.price, required this.binanceSymbol});

  factory TradeData.fromJson(Map<String, dynamic> json) {
    return TradeData(price: json['p'], binanceSymbol: json['s']);
  }
}

/*

class Chain {
  final int chainId;
  final String name;
  final NetworkType type;
  final String keyId;
  final String symbol;
  final String path;
  final String imageUrl;
  final Crypto nativeToken;
  final Color color;
  final List<String> rpcUrls;
  final List<String> explorers;

  Chain({
    required this.chainId,
    required this.keyId,
    required this.name,
    required this.symbol,
    required this.path,
    required this.nativeToken,
    required this.explorers,
    required this.imageUrl,
    required this.rpcUrls,
    required this.color,
    required this.type,
  });

  Map<String, dynamic> toJson() {
    return {
      'chainId': chainId,
      'keyId': keyId,
      'name': name,
      'symbol': symbol,
      'path': path,
      'nativeToken': nativeToken.toJson(), 
      'explorers': explorers,
      'imageUrl': imageUrl,
      'rpcUrls': rpcUrls,
      'color': color.value,
      'type': type.index
    };
  }

  factory Chain.fromJson(Map<String, dynamic> json) {
    return Chain(
      chainId: json['chainId'],
      keyId: json['keyId'],
      name: json['name'],
      symbol: json['symbol'],
      path: json['path'],
      nativeToken: Crypto.fromJson(json['nativeToken']),
      explorers: List<String>.from(json['explorers']),
      imageUrl: json['imageUrl'],
      rpcUrls: List<String>.from(json['rpcUrls']),
      color: Color(json['color']),
      type: NetworkType.values[json["type"] as int] 
      
    );
  }
}
*/

class CryptoMarketData {
  final String id;
  final String symbol;
  final String name;
  final String? image;
  final double currentPrice;
  final double? marketCap;
  final int? marketCapRank;
  final double? fullyDilutedValuation;
  final double? totalVolume;
  final double? high24h;
  final double? low24h;
  final double? priceChange24h;
  final double priceChangePercentage24h;
  final double? marketCapChange24h;
  final double? marketCapChangePercentage24h;
  final double? circulatingSupply;
  final double? totalSupply;
  final double? maxSupply;
  final double? ath;
  final double? athChangePercentage;
  final DateTime? athDate;
  final double? atl;
  final double? atlChangePercentage;
  final DateTime? atlDate;
  final Roi? roi;
  final DateTime lastUpdated;

  CryptoMarketData({
    required this.id,
    required this.symbol,
    required this.name,
    this.image,
    required this.currentPrice,
    this.marketCap,
    this.marketCapRank,
    this.fullyDilutedValuation,
    this.totalVolume,
    this.high24h,
    this.low24h,
    this.priceChange24h,
    required this.priceChangePercentage24h,
    this.marketCapChange24h,
    this.marketCapChangePercentage24h,
    this.circulatingSupply,
    this.totalSupply,
    this.maxSupply,
    this.ath,
    this.athChangePercentage,
    this.athDate,
    this.atl,
    this.atlChangePercentage,
    this.atlDate,
    this.roi,
    required this.lastUpdated,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'symbol': symbol,
      'name': name,
      'image': image,
      'current_price': currentPrice,
      'market_cap': marketCap,
      'market_cap_rank': marketCapRank,
      'fully_diluted_valuation': fullyDilutedValuation,
      'total_volume': totalVolume,
      'high_24h': high24h,
      'low_24h': low24h,
      'price_change_24h': priceChange24h,
      'price_change_percentage_24h': priceChangePercentage24h,
      'market_cap_change_24h': marketCapChange24h,
      'market_cap_change_percentage_24h': marketCapChangePercentage24h,
      'circulating_supply': circulatingSupply,
      'total_supply': totalSupply,
      'max_supply': maxSupply,
      'ath': ath,
      'ath_change_percentage': athChangePercentage,
      'ath_date': athDate?.toIso8601String(),
      'atl': atl,
      'atl_change_percentage': atlChangePercentage,
      'atl_date': atlDate?.toIso8601String(),
      'roi': roi?.toJson(),
      'last_updated': lastUpdated.toIso8601String(),
    };
  }

  factory CryptoMarketData.fromJson(Map<String, dynamic> json) {
    double? parseDouble(dynamic value) =>
        value != null ? (value as num).toDouble() : null;

    DateTime? parseDate(dynamic value) =>
        value != null ? DateTime.tryParse(value) : null;

    return CryptoMarketData(
      id: json['id'] ?? '',
      symbol: json['symbol'] ?? '',
      name: json['name'] ?? '',
      image: json['image'],
      currentPrice: (json['current_price'] as num).toDouble(),
      marketCap: parseDouble(json['market_cap']),
      marketCapRank: json['market_cap_rank'],
      fullyDilutedValuation: parseDouble(json['fully_diluted_valuation']),
      totalVolume: parseDouble(json['total_volume']),
      high24h: parseDouble(json['high_24h']),
      low24h: parseDouble(json['low_24h']),
      priceChange24h: parseDouble(json['price_change_24h']),
      priceChangePercentage24h:
          parseDouble(json['price_change_percentage_24h']) ?? 0.0,
      marketCapChange24h: parseDouble(json['market_cap_change_24h']),
      marketCapChangePercentage24h:
          parseDouble(json['market_cap_change_percentage_24h']),
      circulatingSupply: parseDouble(json['circulating_supply']),
      totalSupply: parseDouble(json['total_supply']),
      maxSupply: parseDouble(json['max_supply']),
      ath: parseDouble(json['ath']),
      athChangePercentage: parseDouble(json['ath_change_percentage']),
      athDate: parseDate(json['ath_date']),
      atl: parseDouble(json['atl']),
      atlChangePercentage: parseDouble(json['atl_change_percentage']),
      atlDate: parseDate(json['atl_date']),
      roi: json['roi'] != null ? Roi.fromJson(json['roi']) : null,
      lastUpdated: DateTime.parse(json['last_updated']),
    );
  }
}

class Roi {
  final double times;
  final String currency;
  final double percentage;

  Roi({
    required this.times,
    required this.currency,
    required this.percentage,
  });

  Map<String, dynamic> toJson() {
    return {
      'times': times,
      'currency': currency,
      'percentage': percentage,
    };
  }

  factory Roi.fromJson(Map<String, dynamic> json) {
    double? parseDouble(dynamic value) =>
        value != null ? (value as num).toDouble() : 0.0;

    return Roi(
      times: parseDouble(json['times']) ?? 0.0,
      currency: json['currency'] ?? '',
      percentage: parseDouble(json['percentage']) ?? 0.0,
    );
  }
}

class BasicTransactionData {
  final String addressTo;
  final double amount;
  final Crypto crypto;
  final PublicData account;

  BasicTransactionData(
      {required this.addressTo,
      required this.amount,
      required this.account,
      required this.crypto});
}

class TransactionToConfirm {
  final String addressTo;
  final String valueHex;
  final BigInt valueBigInt;
  final Crypto crypto;
  final PublicData account;
  final String? gasHex;
  final BigInt? gasBigint;
  final String? data;
  final double valueEth;
  final double cryptoPrice;
  final BigInt gasPrice;

  TransactionToConfirm(
      {required this.addressTo,
      required this.valueHex,
      required this.account,
      required this.crypto,
      required this.valueEth,
      required this.cryptoPrice,
      required this.valueBigInt,
      required this.gasPrice,
      this.gasBigint,
      this.gasHex,
      this.data});
}

class AppUIConfig {
  final bool isCryptoHidden;
  final AppColors colors;
  final AppStyle styles;

  const AppUIConfig({
    required this.colors,
    required this.isCryptoHidden,
    required this.styles,
  });

  AppUIConfig copyWith({
    AppColors? colors,
    AppStyle? styles,
    bool? isCryptoHidden,
    bool? canUseBio,
  }) {
    return AppUIConfig(
      colors: colors ?? this.colors,
      styles: styles ?? this.styles,
      isCryptoHidden: isCryptoHidden ?? this.isCryptoHidden,
    );
  }

  static const defaultConfig = AppUIConfig(
      colors: AppColors.defaultTheme,
      isCryptoHidden: false,
      styles: AppStyle());

  Map<dynamic, dynamic> toJson() => {
        'isCryptoHidden': isCryptoHidden,
        'colors': colors.toJson(),
        'styles': styles.toJson(),
      };

  factory AppUIConfig.fromJson(Map<dynamic, dynamic> json) {
    return AppUIConfig(
      isCryptoHidden: json['isCryptoHidden'] ?? false,
      colors: AppColors.fromJson(json['colors'] ?? {}),
      styles: AppStyle.fromJson(json['styles'] ?? {}),
    );
  }
}

class AppStyle {
  final double radiusScaleFactor;
  final double fontSizeScaleFactor;
  final double borderOpacity;
  final double iconSizeScaleFactor;
  final double imageSizeScaleFactor;
  final double listTitleVisualDensityVerticalFactor;
  final double listTitleVisualDensityHorizontalFactor;

  const AppStyle({
    this.radiusScaleFactor = 1,
    this.borderOpacity = 0,
    this.fontSizeScaleFactor = 1,
    this.iconSizeScaleFactor = 1,
    this.imageSizeScaleFactor = 1,
    this.listTitleVisualDensityVerticalFactor = 1,
    this.listTitleVisualDensityHorizontalFactor = 1,
  });

  static const defaultStyle = AppStyle();

  static const small2x = AppStyle(
    iconSizeScaleFactor: 0.5,
    imageSizeScaleFactor: 0.5,
    fontSizeScaleFactor: 0.5,
  );

  static const large2x = AppStyle(
    iconSizeScaleFactor: 2,
    imageSizeScaleFactor: 2,
    fontSizeScaleFactor: 2,
  );

  static const noRadius = AppStyle(radiusScaleFactor: 0);
  static const withBorder = AppStyle(borderOpacity: 1);

  double getFontSize(double base) => base * fontSizeScaleFactor;
  double getIconSize(double base) => base * iconSizeScaleFactor;
  double getImageSize(double base) => base * imageSizeScaleFactor;
  AppStyle getDefault() => defaultStyle;

  Map<dynamic, dynamic> toJson() => {
        'radius': radiusScaleFactor,
        'borderOpacity': borderOpacity,
        'fontSizeScaleFactor': fontSizeScaleFactor,
        'iconSizeScaleFactor': iconSizeScaleFactor,
        'imageSizeScaleFactor': imageSizeScaleFactor,
        'listTitleVisualDensityVerticalFactor':
            listTitleVisualDensityVerticalFactor,
        'listTitleVisualDensityHorizontalFactor':
            listTitleVisualDensityHorizontalFactor,
      };

  factory AppStyle.fromJson(Map<dynamic, dynamic> json) => AppStyle(
        radiusScaleFactor: (json['radius'] ?? 20).toDouble(),
        borderOpacity: (json['borderOpacity'] ?? 0).toDouble(),
        fontSizeScaleFactor: (json['fontSizeScaleFactor'] ?? 1).toDouble(),
        iconSizeScaleFactor: (json['iconSizeScaleFactor'] ?? 1).toDouble(),
        imageSizeScaleFactor: (json['imageSizeScaleFactor'] ?? 1).toDouble(),
        listTitleVisualDensityVerticalFactor:
            (json['listTitleVisualDensityVerticalFactor'] ?? 1).toDouble(),
        listTitleVisualDensityHorizontalFactor:
            (json['listTitleVisualDensityHorizontalFactor'] ?? 1).toDouble(),
      );
  AppStyle copyWith({
    double? radiusScaleFactor,
    double? borderOpacity,
    double? fontSizeScaleFactor,
    double? iconSizeScaleFactor,
    double? imageSizeScaleFactor,
    double? listTitleVisualDensityVerticalFactor,
    double? listTitleVisualDensityHorizontalFactor,
  }) {
    return AppStyle(
      radiusScaleFactor: radiusScaleFactor ?? this.radiusScaleFactor,
      borderOpacity: borderOpacity ?? this.borderOpacity,
      fontSizeScaleFactor: fontSizeScaleFactor ?? this.fontSizeScaleFactor,
      iconSizeScaleFactor: iconSizeScaleFactor ?? this.iconSizeScaleFactor,
      imageSizeScaleFactor: imageSizeScaleFactor ?? this.imageSizeScaleFactor,
      listTitleVisualDensityVerticalFactor:
          listTitleVisualDensityVerticalFactor ??
              this.listTitleVisualDensityVerticalFactor,
      listTitleVisualDensityHorizontalFactor:
          listTitleVisualDensityHorizontalFactor ??
              this.listTitleVisualDensityHorizontalFactor,
    );
  }
}

class AppSecureConfig {
  final bool useBioMetric;
  final bool lockAtStartup;

  AppSecureConfig({this.useBioMetric = false, this.lockAtStartup = false});

  factory AppSecureConfig.fromJson(Map<dynamic, dynamic> json) {
    return AppSecureConfig(
      useBioMetric: json["useBioMetric"] ?? false,
      lockAtStartup: json["lockAtStartup"] ?? false,
    );
  }

  AppSecureConfig copyWith({bool? useBioMetric, bool? lockAtStartup}) {
    return AppSecureConfig(
      useBioMetric: useBioMetric ?? this.useBioMetric,
      lockAtStartup: lockAtStartup ?? this.lockAtStartup,
    );
  }

  Map<dynamic, dynamic> toJson() {
    return {
      "useBioMetric": useBioMetric,
      "lockAtStartup": lockAtStartup,
    };
  }
}

class FiatCurrency {
  final String code;
  final double valueInUsd;
  final int lastUpdate;

  FiatCurrency({
    required this.code,
    required this.lastUpdate,
    required this.valueInUsd,
  });

  factory FiatCurrency.fromJson(Map<dynamic, dynamic> json) {
    return FiatCurrency(
      code: json['code'],
      valueInUsd: (json['valueInUsd'] as num).toDouble(),
      lastUpdate: json['lastUpdate'],
    );
  }

  Map<dynamic, dynamic> toJson() {
    return {
      'code': code,
      'valueInUsd': valueInUsd,
      'lastUpdate': lastUpdate,
    };
  }
}

class TransferData {
  final double amountInEth;
  final PublicData account;
  final Crypto crypto;
  final BigInt gas;
  final String to;

  TransferData(
      {required this.amountInEth,
      required this.account,
      required this.crypto,
      required this.to,
      required this.gas});
}

typedef DoubleFactor = double Function(double size);

class AccountAccess {
  final Credentials cred;
  final String key;
  final String address;

  AccountAccess({required this.address, required this.cred, required this.key});
}
