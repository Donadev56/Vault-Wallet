import 'package:bip39/bip39.dart' as bip39;

import 'package:moonwallet/logger/logger.dart';
import 'package:moonwallet/service/web3_interactions/evm/addresses.dart';
import 'package:moonwallet/service/web3_interactions/svm/solana_address.dart';
import 'package:moonwallet/types/account_related_types.dart' as types;

class AddressManager {
  final ethAddress = EthAddresses();
  final solanaAddress = SolanaAddress();
  String generateMnemonic() {
    return bip39.generateMnemonic();
  }

  String generateEthAddress(String mnemonic) {
    try {
      final privateKey = ethAddress.derivateEthereumKeyFromMnemonic(mnemonic);
      if (privateKey == null) {
        throw "Invalid Key";
      }
      return ethAddress.generateEthAddress(privateKey);
    } catch (e) {
      logError(e.toString());
      rethrow;
    }
  }

  Future<String?> generateSolanaAddress(String mnemonic) async {
    try {
      final keyPair = await solanaAddress.getKeyPair(mnemonic);
      if (keyPair == null) {
        throw "Key Pair Should not be null";
      }
      return keyPair.address;
    } catch (e) {
      logError(e.toString());
      rethrow;
    }
  }

  Future<String?> generateAddressFromPrivateKey(
      {required String privateKey,
      required types.NetworkType networkType}) async {
    try {
      switch (networkType) {
        case types.NetworkType.evm:
          return ethAddress.generateEthAddress(privateKey);
        case types.NetworkType.svm:
          return solanaAddress.generateAddressFromPrivateKey(privateKey);
      }
    } catch (e) {
      logError(e.toString());
      return null;
    }
  }

  Future<String?> generateAddressFromMnemonic(
      {required String mnemonic,
      required types.NetworkType networkType}) async {
    try {
      switch (networkType) {
        case types.NetworkType.evm:
          return generateEthAddress(mnemonic);
        case types.NetworkType.svm:
          return generateSolanaAddress(mnemonic);
      }
    } catch (e) {
      logError(e.toString());
      return null;
    }
  }

  Future<List<types.PublicAddress>> generateAddressFromOrigin(String keyOrigin,
      types.Origin origin, List<types.NetworkType> networks) async {
    try {
      List<types.PublicAddress> accountAddresses = [];

      if (origin.isMnemonic) {
        accountAddresses = await (Future.wait(networks.map((e) async {
          try {
            final address = await generateAddressFromMnemonic(
                mnemonic: keyOrigin, networkType: e);
            if (address != null) {
              return types.PublicAddress(address: address, type: e);
            }

            return types.PublicAddress(address: "", type: e);
          } catch (err) {
            logError(err.toString());
            return types.PublicAddress(address: "", type: e);
          }
        })));
      } else if (origin.isPrivateKey) {
        final address = await generateAddressFromPrivateKey(
            privateKey: keyOrigin, networkType: networks.first);
        final publicAddress =
            types.PublicAddress(address: address ?? "", type: networks.first);
        accountAddresses.add(publicAddress);
      } else {
        accountAddresses
            .add(types.PublicAddress(address: keyOrigin, type: networks.first));
      }
      return accountAddresses;
    } catch (e) {
      logError(e.toString());
      return [];
    }
  }
}
