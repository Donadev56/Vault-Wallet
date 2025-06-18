import 'package:bs58/bs58.dart';
import 'package:cryptography/cryptography.dart';
import 'package:ed25519_hd_key/ed25519_hd_key.dart';
import 'package:moonwallet/logger/logger.dart';
import 'package:solana/base58.dart';
import 'package:solana/solana.dart';

import 'package:bip39/bip39.dart' as bip39;

class SolanaAddress {
  Future<Ed25519HDKeyPair?> getKeyPair(String mnemonic) async {
    try {
      final keyPair = await Ed25519HDKeyPair.fromMnemonic(mnemonic, account: 0, change: 0);
      return keyPair;
    } catch (e) {
      logError(e.toString());
      return null;
    }
  }
  Future<String?> generatePrivateKeyFromMnemonic(String mnemonic) async {
    try {
      final keyPair = await Ed25519HDKeyPair.fromMnemonic(mnemonic, account: 0, change: 0);
      final keyPairData =await  keyPair.extract();
      final privateKey = base58encode(keyPairData.bytes);
      return privateKey + keyPairData.publicKey.toBase58();

    } catch (e) {
      logError(e.toString());
      return null;
    }
  }
  Future<Ed25519HDKeyPair?> getKeyPairByPrivateKey(String privateKey) async {
    try {
      final decodedPrivateKey = base58.decode(privateKey).sublist(0, 32);
      final keyPair = await Ed25519HDKeyPair.fromPrivateKeyBytes(
          privateKey: decodedPrivateKey);
      return keyPair;
    } catch (e) {
      logError(e.toString());
      rethrow;
    }
  }

  Future<String?> generateAddressFromPrivateKey(String privateKey) async {
    try {
      final keyPair = await getKeyPairByPrivateKey(privateKey);
      if (keyPair == null) {
        throw "Invalid Key Pair";
      }

      return keyPair.address;
    } catch (e) {
      logError(e.toString());
      rethrow;
    }
  }

  Future<String?> generateAddress(String mnemonic) async {
    try {
      final keyPair = await getKeyPair(mnemonic);
      if (keyPair == null) {
        throw "Failed to generate key pair";
      }
      final address = keyPair.address;
      log("Generated address: $address");
      return address;
    } catch (e) {
      logError(e.toString());
      return null;
    }
  }

  bool isAddressValid(String address) {
    try {
      final decoded = base58.decode(address);
      return decoded.length == 32;
    } catch (e) {
      return false;
    }
  }

  Future<bool> isPrivateKeyValid(String privateKey) async {
    try {
      final keyPair = await getKeyPairByPrivateKey(privateKey);
      return keyPair != null;
    } catch (e) {
      rethrow;
    }
  }

  Future<Ed25519HDKeyPair> deriveSolanaKeypair(String mnemonic) async {
    final seed = bip39.mnemonicToSeed(mnemonic);

    final keyData = await ED25519_HD_KEY.derivePath("m/44'/501'/0'/0'", seed);

    final keyPair = await Ed25519HDKeyPair.fromPrivateKeyBytes(
      privateKey: keyData.key,
    );

    return keyPair;
  }

    Future<String> getPrivateKey(String mnemonic) async {
    final seed = bip39.mnemonicToSeed(mnemonic);

    final keyData = await ED25519_HD_KEY.derivePath("m/44'/501'/0'/0'", seed);
    final algorithm = Ed25519();
    final keyPair = await algorithm.newKeyPairFromSeed(keyData.key);
    final keyPairData = await keyPair.extract();
    final privateKey =await keyPairData.extractPrivateKeyBytes();
    final pubKey =  keyPairData.publicKey.bytes;
    final fullKey = privateKey + pubKey;
    return base58encode(fullKey);

  }
}
