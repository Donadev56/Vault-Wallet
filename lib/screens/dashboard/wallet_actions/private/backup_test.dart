import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:moonwallet/custom/web3_webview/lib/utils/loading.dart';
import 'package:moonwallet/logger/logger.dart';
import 'package:moonwallet/notifiers/providers.dart';
import 'package:moonwallet/screens/dashboard/page_manager.dart';
import 'package:moonwallet/service/db/wallet_db.dart';
import 'package:moonwallet/types/account_related_types.dart';
import 'package:moonwallet/types/types.dart';
import 'dart:math';

import 'package:moonwallet/widgets/backup/backup_related.dart';
import 'package:moonwallet/widgets/func/snackbar.dart';
import 'package:page_transition/page_transition.dart';

class BackupTestScreen extends ConsumerStatefulWidget {
  final String password;
  final PrivateAccount wallet;
  final AppColors colors;
  final PublicAccount publicAccount;

  const BackupTestScreen(
      {super.key,
      required this.colors,
      required this.password,
      required this.wallet,
      required this.publicAccount});

  @override
  ConsumerState<BackupTestScreen> createState() => _BackupTestScreenState();
}

class _BackupTestScreenState extends ConsumerState<BackupTestScreen> {
  late String password;
  late PrivateAccount wallet;
  AppColors colors = AppColors.defaultTheme;
  String originalWorlds = "";
  List<String> originalWorldsList = [];
  List<String> mixedWordsList = [];
  List<int> randomNumbers = [];
  List<String> selectedWords = [];
  late PublicAccount publicAccount;

  @override
  void initState() {
    super.initState();
    password = widget.password;
    wallet = widget.wallet;
    colors = widget.colors;
    publicAccount = widget.publicAccount;
    init();
  }

  void notify(String message) {
    showCustomSnackBar(context: context, message: message, colors: colors);
  }

  void init() {
    setState(() {
      originalWorlds = wallet.keyOrigin;
      originalWorldsList = originalWorlds.split(" ");
      mixedWordsList = originalWorldsList..shuffle(Random());
    });
    log("Original words $originalWorlds");
    setState(() {
      randomNumbers =
          (List.generate(originalWorldsList.length, (index) => index + 1)
                  .toList()
                ..shuffle())
              .toList()
              .sublist(0, 3);
    });
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = TextTheme.of(context);

    Future<void> handleSave() async {
      try {
        final walletDb = WalletDatabase();
        final pos1 = randomNumbers[0];
        final pos2 = randomNumbers[1];
        final pos3 = randomNumbers[2];

        final word1 = selectedWords[0];
        final word2 = selectedWords[1];
        final word3 = selectedWords[2];
        final originals = originalWorlds.split(" ");

        final respectiveWord1 = originals[pos1 - 1];
        final respectiveWord2 = originals[pos2 - 1];
        final respectiveWord3 = originals[pos3 - 1];

        if (word1 != respectiveWord1) {
          throw "$word1 doesn't match";
        }
        if (word2 != respectiveWord2) {
          throw "$word2 doesn't match ";
        }
        if (word3 != respectiveWord3) {
          throw "$word3 doesn't match ";
        }

        final derive = await walletDb.deriveEncryptionKeyStateless(password);

        await walletDb.editPrivateWalletData(
            account: wallet, deriveKey: derive.derivateKey, isBackup: true);
        await walletDb.editWallet(account: publicAccount, isBackup: true);

        Future.delayed((Duration(seconds: 2))).withLoading(context, colors);
        ref.invalidate(accountsNotifierProvider);
        Future.delayed((Duration(seconds: 1))).withLoading(context, colors);

        Navigator.push(
          context,
          PageTransition(
              type: PageTransitionType.theme,
              child: PagesManagerView(colors: colors)),
        );
      } catch (e) {
        logError(e.toString());
        notify(e.toString());
      }
    }

    return Scaffold(
      backgroundColor: colors.primaryColor,
      appBar: AppBar(
        leading: IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(
              Icons.arrow_back,
              color: colors.textColor,
            )),
        backgroundColor: colors.primaryColor,
        surfaceTintColor: colors.primaryColor,
        title: Text(
          "Backup",
          style: textTheme.headlineMedium?.copyWith(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: colors.textColor),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: ListView(
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Column(
                spacing: 10,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Select the correct words",
                    style: textTheme.headlineMedium?.copyWith(
                      color: colors.textColor,
                      fontSize: 25,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    "Select the words that exactly match these indexes.",
                    style: textTheme.bodySmall?.copyWith(
                        color: colors.textColor.withValues(
                      alpha: 0.7,
                    )),
                  ),
                  SizedBox(
                    height: 15,
                  ),
                  Align(
                    alignment: Alignment.center,
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                          color: colors.secondaryColor,
                          borderRadius: BorderRadius.circular(50)),
                      child: Wrap(
                        children: List.generate(randomNumbers.length, (index) {
                          return MnemonicChip(
                              density:
                                  VisualDensity(vertical: -2, horizontal: -2),
                              colors: colors,
                              index: randomNumbers[index] - 1,
                              word: selectedWords.isEmpty ||
                                      selectedWords.length < index + 1
                                  ? "     "
                                  : selectedWords[index]);
                        }),
                      ),
                    ),
                  ),
                  SizedBox(
                    height: 25,
                  ),
                  Align(
                    alignment: Alignment.center,
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                          color: colors.secondaryColor,
                          borderRadius: BorderRadius.circular(10)),
                      child: Wrap(
                        children: List.generate(mixedWordsList.length, (index) {
                          final word = mixedWordsList[index];
                          final isSelected = selectedWords.contains(word);
                          return InkWell(
                            onTap: () {
                              if (selectedWords.length >= 3 && !isSelected) {
                                return;
                              }

                              if (isSelected) {
                                final selectedWordsInstance = selectedWords;
                                final wordIndex =
                                    selectedWordsInstance.indexOf(word);
                                selectedWordsInstance.removeAt(wordIndex);

                                setState(() {
                                  selectedWords = selectedWordsInstance;
                                });
                                return;
                              }
                              setState(() {
                                selectedWords = [...selectedWords, word];
                              });
                            },
                            child: MnemonicChip(
                              density:
                                  VisualDensity(vertical: -2, horizontal: -2),
                              sideColor: isSelected ? Colors.transparent : null,
                              textColor:
                                  isSelected ? colors.primaryColor : null,
                              bgColor: isSelected ? colors.themeColor : null,
                              colors: colors,
                              index: index,
                              word: word,
                              withIndex: false,
                            ),
                          );
                        }),
                      ),
                    ),
                  ),
                  SizedBox(
                    height: 20,
                  ),
                  if (selectedWords.length == 3)
                    Align(
                        alignment: Alignment.center,
                        child: SizedBox(
                          width: MediaQuery.of(context).size.width,
                          child: ElevatedButton.icon(
                              onPressed: handleSave,
                              label: Text(
                                "Continue",
                                style: textTheme.bodyMedium
                                    ?.copyWith(color: colors.primaryColor),
                              )),
                        ))
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
