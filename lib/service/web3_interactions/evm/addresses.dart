import 'package:moonwallet/logger/logger.dart';

import 'package:bip39/bip39.dart' as bip39;
import 'package:bip32/bip32.dart' as bip32;
import 'package:hex/hex.dart';
import 'dart:typed_data';

class EthAddresses {
  Future<Map<String, dynamic>> createWallet() async {
    try {
      final seed = generateMnemonic();
      final privateKey = deriveEthereumPrivateKey(seed);

      if (privateKey == null) {
        logError("Private key is null");
        return {};
      }
      final data = {"key": privateKey, "seed": seed};

      return data;
    } catch (e) {
      logError(e.toString());
      return {};
    }
  }

  Future<Map<String, dynamic>> createPrivatekeyFromSeed(String seed) async {
    try {
      final privateKey = deriveEthereumPrivateKey(seed);
      if (privateKey == null) {
        logError("Private key is null");
        return {};
      }
      final data = {"key": privateKey, "seed": seed};

      return data;
    } catch (e) {
      logError(e.toString());
      return {};
    }
  }

  String generateMnemonic() {
    return bip39.generateMnemonic();
  }

  String? deriveEthereumPrivateKey(String mnemonic) {
    Uint8List seed = bip39.mnemonicToSeed(mnemonic);

    final bip32.BIP32 root = bip32.BIP32.fromSeed(seed);

    final bip32.BIP32 child = root.derivePath("m/44'/60'/0'/0/0");

    final privateKey = child.privateKey;
    if (privateKey == null) {
      logError("Private key is null");
      return null;
    }
    return HEX.encode(privateKey);
  }
}
