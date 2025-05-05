import 'package:solana/solana.dart';

abstract class KeyOrigin {}

class EthereumKey extends KeyOrigin {
  final String privateKeyHex;
  EthereumKey(this.privateKeyHex);
}

class SolanaKey extends KeyOrigin {
  final Ed25519HDKeyPair keyPair;
  SolanaKey(this.keyPair);
}
