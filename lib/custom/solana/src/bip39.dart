import 'package:bip39/bip39.dart' as bip39;

bool isValidateMnemonic(String mnemonic) {
  return bip39.validateMnemonic(mnemonic);
}

String getMnemonic() {
  return bip39.generateMnemonic();
}

bool isValidSolanaAddress(String address) {
  final pattern = r'^[1-9A-HJ-NP-Za-km-z]{32,44}$';
  final regExp = RegExp(pattern);
  return regExp.hasMatch(address);
}
