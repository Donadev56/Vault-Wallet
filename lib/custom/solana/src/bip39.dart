import 'package:bip39/bip39.dart' as bip39;

Future<bool> isValidateMnemonic(String mnemonic) async {
  bool ischcek = await bip39.validateMnemonic(mnemonic);
  return ischcek;
}

Future<String> getMnemonic() async {
  String mnemonic = await bip39.generateMnemonic();
  return mnemonic;
}


  bool isValidSolanaAddress(String address) {
    final pattern = r'^[1-9A-HJ-NP-Za-km-z]{32,44}$';
    final regExp = RegExp(pattern);
    return regExp.hasMatch(address);
  }