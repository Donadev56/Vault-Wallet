// lib/ethereum/models/network_config.dart
import 'package:moonwallet/types/account_related_types.dart';

class NetworkConfig {
  final String chainId;
  final String chainName;
  final Crypto nativeCurrency;
  final List<String> rpcUrls;
  final List<String>? blockExplorerUrls;
  final List<String>? iconUrls;

  NetworkConfig({
    required this.chainId,
    required this.chainName,
    required this.nativeCurrency,
    required this.rpcUrls,
    this.blockExplorerUrls,
    this.iconUrls,
  });

  Map<String, dynamic> toJson() => {
        'chainId': chainId,
        'chainName': chainName,
        'nativeCurrency': nativeCurrency.toJson(),
        'rpcUrls': rpcUrls,
        'blockExplorerUrls': blockExplorerUrls,
        'iconUrls': iconUrls,
      };

  factory NetworkConfig.fromJson(Map<String, dynamic> json) {
    return NetworkConfig(
      chainId: json['chainId'],
      chainName: json['chainName'],
      nativeCurrency: Crypto.fromJson(json['nativeCurrency']),
      rpcUrls: List<String>.from(json['rpcUrls']),
      blockExplorerUrls: json['blockExplorerUrls'] != null
          ? List<String>.from(json['blockExplorerUrls'])
          : null,
      iconUrls:
          json['iconUrls'] != null ? List<String>.from(json['iconUrls']) : null,
    );
  }
}
