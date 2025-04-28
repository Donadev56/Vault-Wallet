import 'package:moonwallet/utils/constant/mnemonic_words/chinese_simplified_mnemonic.dart';
import 'package:moonwallet/utils/constant/mnemonic_words/chinese_traditional_mnemonic.dart';
import 'package:moonwallet/utils/constant/mnemonic_words/czech_mnemonic.dart';
import 'package:moonwallet/utils/constant/mnemonic_words/english_mnemonic.dart';
import 'package:moonwallet/utils/constant/mnemonic_words/french_mnemonic.dart';
import 'package:moonwallet/utils/constant/mnemonic_words/italian_mnemonic.dart';
import 'package:moonwallet/utils/constant/mnemonic_words/japanese_mnemonic.dart';
import 'package:moonwallet/utils/constant/mnemonic_words/korean_mnemonic.dart';
import 'package:moonwallet/utils/constant/mnemonic_words/portuguese_mnemonic.dart';
import 'package:moonwallet/utils/constant/mnemonic_words/spanish_mnemonic.dart';

class MnemonicLanguagesManager {
  List<List<String>> get languagesList => [
        englishMnemonicWords,
        frenchMnemonicWords,
        chinese_simplifiedMnemonicWords,
        chinese_traditionalMnemonicWords,
        czechMnemonicWords,
        italianMnemonicWords,
        japaneseMnemonicWords,
        koreanMnemonicWords,
        portugueseMnemonicWords,
        spanishMnemonicWords,
      ];

  List<String> get allLanguages => languagesList.expand((e) => e).toList();
  List<String> get french => frenchMnemonicWords;
  List<String> get english => englishMnemonicWords;
  List<String> get italian => italianMnemonicWords;
  List<String> get chineseTraditional => chinese_traditionalMnemonicWords;
  List<String> get chineseSimplified => chinese_simplifiedMnemonicWords;
  List<String> get czech => czechMnemonicWords;
  List<String> get japanese => japaneseMnemonicWords;
  List<String> get korean => koreanMnemonicWords;
  List<String> get portuguese => portugueseMnemonicWords;
  List<String> get spanish => spanishMnemonicWords;
}
