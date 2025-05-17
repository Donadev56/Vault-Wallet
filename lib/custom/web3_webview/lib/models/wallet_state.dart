// lib/ethereum/models/wallet_state.dart
import 'package:moonwallet/custom/web3_webview/lib/models/network_config.dart';
import 'package:moonwallet/types/account_related_types.dart';

class WalletState {
  final String? address;
  final bool isConnected;
  final String chainId;
  final Map<String, NetworkConfig> networks ;
  final PublicAccount account;

  WalletState({
    this.address,
    this.isConnected = false,
    required this.chainId,
    required this.networks,
    required this.account
  });

  WalletState copyWith({
    String? address,
    bool? isConnected,
    String? chainId,
    Map<String, NetworkConfig>? networks,
    PublicAccount? account 
    
  }) {
    return WalletState(
      address: address ?? this.address,
      isConnected: isConnected ?? this.isConnected,
      chainId: chainId ?? this.chainId,
      networks: networks ??  this.networks,
      account: account ?? this.account
    );
  }

  Map<String, dynamic> toJson() => {
        'address': address,
        'isConnected': isConnected,
        'chainId': chainId,
        "account" : account.toJson()
      };

  factory WalletState.fromJson(Map<String, dynamic> json) {
    return WalletState(
      address: json['address'],
      isConnected: json['isConnected'],
      chainId: json['chainId'],
      networks: {},
      account: PublicAccount.fromJson(json["account"])
    );
  }

  factory WalletState.initial() => WalletState(
        chainId: "0x1",
        address: null,
        isConnected: false,
        networks: {},
        account: PublicAccount(keyId: "", creationDate: 0, walletName: "Null Account", addresses: [], isWatchOnly: true, createdLocally: false, origin: Origin.publicAddress, supportedNetworks: [])
      );
}
