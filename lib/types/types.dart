import 'package:flutter/material.dart';

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

  PublicData({
    required this.keyId,
    required this.creationDate,
    required this.walletName,
    required this.address,
  });

  factory PublicData.fromJson(Map<String, dynamic> json) {
    return PublicData(
      keyId: json['keyId'] as String,
      creationDate: json['creationDate'] as int,
      walletName: json['walletName'] as String,
      address: json['address'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'keyId': keyId,
      'creationDate': creationDate,
      'walletName': walletName,
      'address': address,
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

class Network {
  final String name;
  final String icon;
  final int chainId;
  final Color color;
  final String? rpc;

  Network({
    required this.name,
    required this.icon,
    required this.chainId,
    required this.color,
    this.rpc,
  });

  factory Network.fromJson(Map<String, dynamic> json) {
    return Network(
      name: json['name'],
      icon: json['icon'],
      chainId: json['chainId'],
      color: Color(json['color']),
      rpc: json['rpc'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'icon': icon,
      'chainId': chainId,
      'color': color.value,
      'rpc': rpc,
    };
  }
}

class Networks {
  final List<Network> networks;

  Networks({required this.networks});

  factory Networks.fromJson(List<dynamic> jsonList) {
    return Networks(
      networks: jsonList.map((json) => Network.fromJson(json)).toList(),
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
