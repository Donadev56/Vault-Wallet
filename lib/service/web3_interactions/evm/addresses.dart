import 'dart:typed_data';

import 'package:bip39/bip39.dart' as bip39;
import 'package:bip32/bip32.dart' as bip32;
import 'package:hex/hex.dart';
import 'package:moonwallet/custom/web3_webview/lib/web3_webview.dart';
import 'package:moonwallet/logger/logger.dart';

class EthAddresses {
  String generateEthAddress(String privateKey) {
    final credentials = EthPrivateKey.fromHex(privateKey);
    final address = credentials.address;
    return address.hex;
  }

  bip32.BIP32? derivateBip32KeyFromPath(String mnemonic, String path) {
    try {
      Uint8List seed = bip39.mnemonicToSeed(mnemonic);

      final bip32.BIP32 root = bip32.BIP32.fromSeed(seed);

      final bip32.BIP32 child = root.derivePath(path);

      return child;
    } catch (e) {
      logError(e.toString());
      rethrow;
    }
  }

  String? derivateEthereumKeyFromMnemonic(String mnemonic) {
    try {
      final child = derivateBip32KeyFromPath(mnemonic, "m/44'/60'/0'/0/0");
      if (child == null) {
        throw "Invalid Mnemonic";
      }
      final privateKey = child.privateKey;
      if (privateKey == null) {
        throw "Private Key not found";
      }
      return HEX.encode(privateKey);
    } catch (e) {
      logError(e.toString());
      rethrow;
    }
  }

  bool isAddressValid(String address) {
    try {
      EthereumAddress.fromHex(address);
      return true;
    } catch (e) {
      return false;
    }
  }

  bool isPrivateKeyValid(String privateKey) {
    try {
      final address = generateEthAddress(privateKey);
      return address.isNotEmpty;
    } catch (e) {
      rethrow;
    }
  }
}
