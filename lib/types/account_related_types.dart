import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:moonwallet/custom/web3_webview/lib/web3_webview.dart';
import 'package:moonwallet/types/ecosystem_config.dart';
import 'package:moonwallet/types/types.dart';

enum NetworkType { evm, svm }

enum CryptoType { native, token }

enum Origin {
  mnemonic,
  privateKey,
  publicAddress,
}

extension OriginExtension on Origin {
  String toShortString() => toString().split('.').last;

  static Origin fromString(String value) {
    return Origin.values.firstWhere((e) => e.toShortString() == value);
  }

  bool get isMnemonic => this == Origin.mnemonic;
  bool get isPrivateKey => this == Origin.privateKey;
  bool get isPublicAddress => this == Origin.publicAddress;
}

extension StringFormat on List<PrivateAccount> {
  String toJsonString() => json.encode(map((e) => e.toJson()).toList());
}

extension NetworkTypeExtension on NetworkType {
  String toShortString() => toString().split('.').last;

  static NetworkType fromString(String value) {
    return NetworkType.values.firstWhere((e) => e.toShortString() == value);
  }
}

class PublicAccount {
  final String keyId;
  final int creationDate;
  final String walletName;
  final List<PublicAddress> addresses;
  final bool isWatchOnly;
  final IconData? walletIcon;
  final Color? walletColor;
  final bool isBackup;
  final bool createdLocally;
  final Origin origin;
  final List<NetworkType> supportedNetworks;

  PublicAccount(
      {required this.keyId,
      required this.creationDate,
      required this.walletName,
      required this.addresses,
      required this.isWatchOnly,
      this.walletIcon = LucideIcons.wallet,
      this.walletColor = Colors.transparent,
      this.isBackup = false,
      required this.createdLocally,
      required this.origin,
      required this.supportedNetworks});
  bool hasAddress(NetworkType type) {
    return addresses.any((address) => address.type == type);
  }

  String addressByToken(Crypto crypto) {
    final type =
        crypto.isNative ? crypto.networkType : crypto.network?.networkType;
    if (type == null) {
      throw ArgumentError("Network type is null");
    }
    return addresses.firstWhere((address) => address.type == type).address;
  }

  String? get evmAddress => addresses
      .where((address) => address.type == NetworkType.evm)
      .firstOrNull
      ?.address;

  TokenEcosystem? getEcosystem() {
    if (origin.isMnemonic) {
      return null;
    }

    return ecosystemInfo[supportedNetworks.first];
  }

  String? get svmAddress => addresses
      .where((address) => address.type == NetworkType.svm)
      .firstOrNull
      ?.address;

  factory PublicAccount.fromJson(Map<dynamic, dynamic> json) {
    List<PublicAddress> addresses() {
      if (json["address"] != null && json["addresses"] == null) {
        return [PublicAddress(address: json["address"], type: NetworkType.evm)];
      } else if (json["addresses"] != null) {
        return (json["addresses"] as List<dynamic>)
            .map((e) => PublicAddress.fromJson(e))
            .toList();
      } else {
        return [];
      }
    }

    return PublicAccount(
      keyId: json['keyId'] as String,
      creationDate: json['creationDate'] as int,
      walletName: json['walletName'] as String,
      addresses: addresses(),
      isWatchOnly: json['isWatchOnly'] as bool,
      walletIcon: json["walletIcon"] != null
          ? IconData(json['walletIcon']["codePoint"],
              fontFamily: json['walletIcon']['fontFamily'],
              matchTextDirection: json['walletIcon']["matchTextDirection"],
              fontPackage: json['walletIcon']['fontPackage'])
          : Icons.wallet,
      walletColor: json['walletColor'] != null
          ? Color(json['walletColor'])
          : Colors.transparent,
      isBackup: json["isBackup"] ?? false,
      createdLocally: json["createdLocally"] ?? false,
      origin: OriginExtension.fromString(json['origin']),
      supportedNetworks: (json['supportedNetworks'] as List<dynamic>)
          .map((e) => NetworkTypeExtension.fromString(e))
          .toList(),
    );
  }

  bool get isSaved => createdLocally && isBackup;

  Map<dynamic, dynamic> toJson() {
    return {
      'keyId': keyId,
      'creationDate': creationDate,
      'walletName': walletName,
      'addresses': addresses.map((e) => e.toJson()).toList(),
      'isWatchOnly': isWatchOnly,
      'walletIcon': walletIcon?.toJson() ?? Icons.wallet.toJson(),
      'walletColor': walletColor?.value ?? Colors.transparent.value,
      "isBackup": isBackup,
      "createdLocally": createdLocally,
      "origin": origin.toShortString(),
      "supportedNetworks":
          supportedNetworks.map((e) => e.toShortString()).toList(),
    };
  }

  PublicAccount copyWith({
    int? id,
    String? keyId,
    int? creationDate,
    String? walletName,
    List<PublicAddress>? addresses,
    bool? isWatchOnly,
    IconData? walletIcon,
    Color? walletColor,
    bool? isBackup,
    bool? createdLocally,
    Origin? origin,
    List<NetworkType>? supportedNetworks,
  }) {
    return PublicAccount(
        keyId: keyId ?? this.keyId,
        creationDate: creationDate ?? this.creationDate,
        walletName: walletName ?? this.walletName,
        addresses: addresses ?? this.addresses,
        isWatchOnly: isWatchOnly ?? this.isWatchOnly,
        walletIcon: walletIcon ?? this.walletIcon,
        walletColor: walletColor ?? this.walletColor,
        isBackup: isBackup ?? this.isBackup,
        createdLocally: createdLocally ?? this.createdLocally,
        supportedNetworks: supportedNetworks ?? this.supportedNetworks,
        origin: origin ?? this.origin);
  }
}

class PrivateAccount {
  final String keyId;
  final int creationDate;
  final String walletName;
  final bool createdLocally;
  final bool isBackup;
  final Origin origin;
  final List<NetworkType> supportedNetworks;
  final String keyOrigin;
  PrivateAccount(
      {required this.createdLocally,
      required this.keyOrigin,
      required this.keyId,
      required this.creationDate,
      required this.walletName,
      required this.origin,
      required this.supportedNetworks,
      required this.isBackup}) {
    if (keyOrigin.isEmpty) {
      throw ArgumentError(
          "key origin must be provided and should not be empty");
    }
  }

  get isFromMnemonic => origin == Origin.mnemonic;
  get isFromPublic => origin == Origin.publicAddress;
  get isFromKey => origin == Origin.privateKey;
  get isWatchOnly => isFromPublic;

  factory PrivateAccount.fromJson(Map<dynamic, dynamic> json) {
    return PrivateAccount(
      keyOrigin: json["keyOrigin"],
      keyId: json['keyId'] ?? "",
      creationDate: json['creationDate'] ?? 0,
      walletName: json['walletName'] ?? "",
      createdLocally: json["createdLocally"] ?? false,
      origin: OriginExtension.fromString(json["origin"]),
      supportedNetworks: (json["supportedNetworks"] as List<dynamic>)
          .map((e) => NetworkTypeExtension.fromString(e))
          .toList(),
      isBackup: json["isBackup"] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'keyId': keyId,
      'creationDate': creationDate,
      'walletName': walletName,
      "createdLocally": createdLocally,
      "isBackup": isBackup,
      "origin": origin.toShortString(),
      "supportedNetworks":
          supportedNetworks.map((e) => e.toShortString()).toList(),
      "keyOrigin": keyOrigin
    };
  }

  PrivateAccount copyWith({
    String? privateKey,
    String? keyId,
    int? creationDate,
    String? walletName,
    String? mnemonic,
    String? address,
    bool? isBackup,
    bool? createdLocally,
    Origin? origin,
    List<NetworkType>? supportedNetworks,
    String? keyOrigin,
  }) {
    return PrivateAccount(
        keyId: keyId ?? this.keyId,
        creationDate: creationDate ?? this.creationDate,
        walletName: walletName ?? this.walletName,
        createdLocally: createdLocally ?? this.createdLocally,
        isBackup: isBackup ?? this.isBackup,
        supportedNetworks: supportedNetworks ?? this.supportedNetworks,
        origin: origin ?? this.origin,
        keyOrigin: keyOrigin ?? this.keyOrigin);
  }
}

class Asset {
  final Crypto crypto;
  final String balanceUsd;
  final String balanceCrypto;
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
        balanceUsd: json['balanceUsd'] ?? "0",
        balanceCrypto: json['balanceCrypto'] ?? "0",
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

class AccountAccess {
  final Credentials cred;
  final String key;
  final String address;

  AccountAccess({required this.address, required this.cred, required this.key});
}

class PublicAddress {
  final String address;
  final NetworkType type;

  PublicAddress({required this.address, required this.type});
  Map<dynamic, dynamic> toJson() {
    return {
      'address': address,
      'type': type.index,
    };
  }

  factory PublicAddress.fromJson(Map<dynamic, dynamic> json) {
    return PublicAddress(
      address: json['address'],
      type: NetworkType.values[json['type'] as int],
    );
  }

  @override
  String toString() {
    return 'PublicAddress{address: $address, type: $type}';
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
  final String cryptoId;
  final bool canDisplay;
  final String symbol;
  final String? cgSymbol;
  final NetworkType? networkType;

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
      required this.cryptoId,
      required this.canDisplay,
      required this.symbol,
      this.networkType,
      this.cgSymbol}) {
    if (type == CryptoType.token) {
      if (contractAddress == null || network == null) {
        throw ArgumentError(
            "A token should have a contract address and a valid network");
      }
    }
    if (type == CryptoType.native) {
      if (chainId == null || rpcUrls == null) {
        throw ArgumentError(
            "A network should have Chain ID and a valid rpcUrl");
      }
      if (networkType == null) {
        throw ArgumentError("A network should have a valid network type");
      }
    }
  }
  factory Crypto.fromJsonRequest(Map<String, dynamic> cryptoJson) {
    return Crypto(
        canDisplay: cryptoJson["canDisplay"],
        cryptoId: cryptoJson["cryptoId"],
        name: cryptoJson["name"],
        color: Color(cryptoJson["color"] ?? 0x00000000),
        type: CryptoType.values[cryptoJson["type"]],
        icon: cryptoJson["icon"],
        networkType: cryptoJson["networkType"] != null
            ? NetworkType.values[cryptoJson["networkType"]]
            : null,
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
        symbol: cryptoJson["symbol"],
        networkType: cryptoJson["networkType"] != null
            ? NetworkType.values[cryptoJson["networkType"]]
            : null,
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
      "symbol": symbol,
      "cgSymbol": cgSymbol,
      "networkType": networkType?.index,
    };
  }

  bool get isNative => type == CryptoType.native;
  String get getRpcUrl => isNative
      ? (rpcUrls?.firstOrNull ?? "")
      : (network?.rpcUrls?.firstOrNull ?? "");
  NetworkType get getNetworkType =>
      isNative ? networkType! : network!.networkType!;
  Crypto? get tokenNetwork => isNative ? this : network;

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
    NetworkType? networkType,
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
      cryptoId: cryptoId ?? this.cryptoId,
      canDisplay: canDisplay ?? this.canDisplay,
      symbol: symbol ?? this.symbol,
      cgSymbol: cgSymbol ?? this.cgSymbol,
      networkType: networkType ?? this.networkType,
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

class DerivateKeys {
  List<int> salt;
  String derivateKey;

  DerivateKeys({required this.derivateKey, required this.salt});
  Map<String, dynamic> toJson() => {
        'salt': base64Encode(salt),
        'derivateKey': derivateKey,
      };

  factory DerivateKeys.fromJson(Map<String, dynamic> json) {
    return DerivateKeys(
      derivateKey: json['derivateKey'] as String,
      salt: base64Decode(json['salt'] as String),
    );
  }
}

class TokenEcosystem {
  final String name;
  final NetworkType type;
  final String iconUrl;

  TokenEcosystem(
      {required this.name, required this.type, required this.iconUrl});
}

class EncryptionInfo {
  List<int> mac;
  List<int> nonce;

  EncryptionInfo({required this.mac, required this.nonce});

  Map<String, dynamic> toJson() => {
        'mac': base64Encode(mac),
        'nonce': base64Encode(nonce),
      };

  factory EncryptionInfo.fromJson(Map<String, dynamic> json) {
    return EncryptionInfo(
      mac: base64Decode(json['mac'] as String),
      nonce: base64Decode(json['nonce'] as String),
    );
  }
}
