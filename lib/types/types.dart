// ignore_for_file: deprecated_member_use

import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:moonwallet/logger/logger.dart';
import 'package:moonwallet/types/account_related_types.dart';

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

extension StringDecimal on String {
  Decimal toDecimal() {
    if (isEmpty) {
      return Decimal.zero;
    }
    return Decimal.parse(this);
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

class UserCustomGasRequestResponse {
  final bool ok;
  final BigInt? gasPrice;
  final BigInt? gasLimit;

  UserCustomGasRequestResponse({
    required this.ok,
    this.gasPrice,
    this.gasLimit,
  });

  // Convert a JSON Map to a HistoryItem instance
  factory UserCustomGasRequestResponse.fromJson(Map<String, dynamic> json) {
    return UserCustomGasRequestResponse(
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

  static const defaultTheme = AppColors(
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
  final ShapeBorder? shape;
  final String title;
  final Widget icon;
  final double iconSize;
  final Widget trailing;
  final Widget? subtitle;
  final Color color;
  final TextStyle? titleStyle;
  final Color? tileColor;
  final Color? splashColor;
  final VisualDensity? density;
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
      this.shape,
      this.iconSize = 30,
      this.density});

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
/*
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

*/

class WidgetInitialData {
  final Crypto crypto;
  final AppColors colors;
  final String? initialBalanceUsd;
  final String initialBalanceCrypto;
  final PublicAccount account;
  final String cryptoPrice;

  WidgetInitialData({
    required this.account,
    required this.crypto,
    required this.initialBalanceCrypto,
    this.initialBalanceUsd,
    required this.cryptoPrice,
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
  final String amount;
  final Crypto crypto;
  final PublicAccount account;

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
  final PublicAccount account;
  final String? gasHex;
  final BigInt? gasBigint;
  final String? data;
  final String valueEth;
  final String cryptoPrice;
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
    this.borderOpacity = 0.3,
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
  final String amountInEth;
  final PublicAccount account;
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

class TransactionReceiptData {
  final String from;
  final String to;
  final String? transactionId;
  final String? value;
  final String? block;
  final bool? status;

  TransactionReceiptData({
    required this.from,
    required this.to,
    this.transactionId,
    this.value,
    this.block,
    this.status,
  });
  Map<String, dynamic> toJson() {
    return {
      'from': from,
      'to': to,
      'transactionId': transactionId,
      'value': value,
      'block': block,
      'status': status,
    };
  }

  factory TransactionReceiptData.fromJson(Map<String, dynamic> json) {
    return TransactionReceiptData(
      from: json['from'],
      to: json['to'],
      transactionId: json['transactionId'],
      value: json['value'],
      block: json['block'],
      status: json['status'] ?? false,
    );
  }
}

class SolanaRequestResponse {
  final bool ok;
  final String? memo;

  SolanaRequestResponse({
    required this.ok,
    this.memo,
  });
}

class LocalSession {
  final int startTime;
  final int endTime;
  final String sessionId;
  final DerivateKeys sessionKey;
  final bool isAuthenticated;
  final bool hasExpired;

  LocalSession(
      {required this.startTime,
      required this.endTime,
      required this.sessionId,
      required this.sessionKey,
      required this.isAuthenticated,
      required this.hasExpired});

  Map<dynamic, dynamic> toJson() {
    return {
      'startTime': startTime,
      'endTime': endTime,
      'sessionId': sessionId,
      'sessionKey': sessionKey.toJson(),
      'isAuthenticated': isAuthenticated,
      "hasExpired": hasExpired
    };
  }

  factory LocalSession.fromJson(Map<dynamic, dynamic> json) {
    return LocalSession(
        startTime: json['startTime'] as int,
        endTime: json['endTime'] as int,
        sessionId: json['sessionId'] as String,
        sessionKey: DerivateKeys.fromJson(json['sessionKey']),
        isAuthenticated: json['isAuthenticated'] ?? false,
        hasExpired: json["hasExpired"] ?? true);
  }

  LocalSession copyWith({
    int? startTime,
    int? endTime,
    String? sessionId,
    DerivateKeys? sessionKey,
    bool? isAuthenticated,
    bool? hasExpired,
  }) {
    return LocalSession(
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      sessionId: sessionId ?? this.sessionId,
      sessionKey: sessionKey ?? this.sessionKey,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      hasExpired: hasExpired ?? this.hasExpired,
    );
  }
}
