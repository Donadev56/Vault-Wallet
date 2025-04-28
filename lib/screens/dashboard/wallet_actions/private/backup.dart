import 'package:flutter/material.dart';
import 'package:moonwallet/screens/dashboard/wallet_actions/private/backup_test.dart';
import 'package:moonwallet/types/types.dart';
import 'package:moonwallet/widgets/backup/backup_related.dart';
import 'package:page_transition/page_transition.dart';

class BackupSeedScreen extends StatefulWidget {
  final String password;
  final SecureData wallet;
  final AppColors colors;
  final PublicData publicAccount;

  const BackupSeedScreen(
      {super.key,
      required this.password,
      required this.wallet,
      required this.colors,
      required this.publicAccount});

  @override
  State<BackupSeedScreen> createState() => _BackupSeedScreenState();
}

class _BackupSeedScreenState extends State<BackupSeedScreen> {
  late String password;
  late SecureData wallet;
  late PublicData publicAccount;

  AppColors colors = AppColors.defaultTheme;

  @override
  void initState() {
    super.initState();
    password = widget.password;
    wallet = widget.wallet;
    colors = widget.colors;
    publicAccount = widget.publicAccount;
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = TextTheme.of(context);
    final words = wallet.mnemonic ?? "";
    final wordsList = words.split(" ");

    return Scaffold(
      backgroundColor: colors.primaryColor,
      appBar: AppBar(
        backgroundColor: colors.primaryColor,
        surfaceTintColor: colors.primaryColor,
        leading: IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(
              Icons.arrow_back,
              color: colors.textColor,
            )),
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
        child: SpaceWithBottomButton(
          children: [
            Column(
              spacing: 15,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Column(
                    spacing: 10,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Backup Seed Phrase",
                        style: textTheme.headlineMedium?.copyWith(
                          color: colors.textColor,
                          fontSize: 25,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        "Record your passphrase manually and save it in a secure location that only you have access to.",
                        style: textTheme.bodySmall?.copyWith(
                            color: colors.textColor.withValues(
                          alpha: 0.7,
                        )),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                      color: colors.secondaryColor,
                      borderRadius: BorderRadius.circular(10)),
                  child: Wrap(
                    children: List.generate(wordsList.length, (index) {
                      final word = wordsList[index];
                      return MnemonicChip(
                          density: VisualDensity(vertical: -2, horizontal: -2),
                          colors: colors,
                          index: index,
                          word: word);
                    }),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 10),
              child: SizedBox(
                width: MediaQuery.of(context).size.width,
                child: ElevatedButton.icon(
                    onPressed: () => Navigator.push(
                        context,
                        PageTransition(
                            type: PageTransitionType.fade,
                            child: BackupTestScreen(
                              publicAccount: publicAccount,
                                colors: colors,
                                password: password,
                                wallet: wallet))),
                    label: Text(
                      "Continue",
                      style: textTheme.bodyMedium
                          ?.copyWith(color: colors.primaryColor),
                    )),
              ),
            )
          ],
        ),
      ),
    );
  }
}
