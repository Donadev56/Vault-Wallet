import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:moonwallet/logger/logger.dart';
import 'package:moonwallet/screens/dashboard/wallet_actions/private/backup.dart';
import 'package:moonwallet/service/external_data/price_manager.dart';
import 'package:moonwallet/service/db/wallet_db.dart';
import 'package:moonwallet/types/types.dart';
import 'package:moonwallet/utils/colors.dart';
import 'package:moonwallet/utils/crypto.dart';
import 'package:moonwallet/utils/prefs.dart';
import 'package:moonwallet/utils/themes.dart';
import 'package:moonwallet/widgets/alerts/show_alert.dart';
import 'package:moonwallet/widgets/backup/warning_static_message.dart';
import 'package:moonwallet/widgets/custom_filled_text_field.dart';
import 'package:moonwallet/widgets/func/snackbar.dart';
import 'package:page_transition/page_transition.dart';

class PrivateKeyScreen extends StatefulHookConsumerWidget {
  final String? password;
  final PublicData account;
  final AppColors? colors;

  const PrivateKeyScreen(
      {super.key, this.password, required this.account, this.colors});

  @override
  ConsumerState<PrivateKeyScreen> createState() => _PrivateKeyScreenState();
}

class _PrivateKeyScreenState extends ConsumerState<PrivateKeyScreen> {
  bool isDarkMode = false;
  AppColors colors = AppColors.defaultTheme;

  Themes themes = Themes();
  String savedThemeName = "";
  Future<void> getSavedTheme() async {
    try {
      final manager = ColorsManager();
      final savedName = await manager.getThemeName();
      setState(() {
        savedThemeName = savedName ?? "";
      });
      final savedTheme = await manager.getDefaultTheme();
      setState(() {
        colors = savedTheme;
      });
    } catch (e) {
      logError(e.toString());
    }
  }

  final TextEditingController _mnemonicController = TextEditingController();
  final TextEditingController _privateKeyController = TextEditingController();
  bool _isInitialized = false;

  final web3Manager = WalletDatabase();
  final encryptService = EncryptService();
  final priceManager = PriceManager();
  final publicDataManager = PublicDataManager();
  SecureData? secureData;
  late PublicData account;

  String walletKeyId = "";
  String password = "";

  @override
  void initState() {
    getSavedTheme();
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      showWarn();
    });
    if (widget.password != null) {
      password = widget.password!;
    }
    if (widget.colors != null) {
      colors = widget.colors!;
    }
    account = widget.account;
  }

  void showWarn() {
    showWarning(
        context: context,
        colors: colors,
        title: "Warning",
        titleColor: Colors.orange,
        content: Text(
          "You are about to view sensitive information, make sure you are not in a public place and that no one is looking at your screen.",
          style: TextTheme.of(context)
              .bodyMedium
              ?.copyWith(color: Colors.pinkAccent),
        ),
        actions: [
          TextButton.icon(
            icon: Icon(
              Icons.arrow_back,
              color: colors.textColor,
            ),
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            label: Text(
              "Go back",
              style: TextTheme.of(context)
                  .bodyMedium
                  ?.copyWith(color: colors.textColor),
            ),
          ),
          TextButton.icon(
            icon: Icon(
              Icons.remove_red_eye,
              color: colors.textColor,
            ),
            onPressed: () {
              getSecureData();
              Navigator.pop(context);
            },
            label: Text(
              "View",
              style: TextTheme.of(context)
                  .bodyMedium
                  ?.copyWith(color: colors.textColor),
            ),
          ),
        ]);
  }

  Future<void> getSecureData() async {
    try {
      final data = await WalletDatabase()
          .getSecureData(password: password, account: account);
      if (data != null) {
        _mnemonicController.text = data.mnemonic ?? "No Mnemonic";
        _privateKeyController.text = data.privateKey;

        setState(() {
          secureData = data;
        });
      }
    } catch (e) {
      logError(e.toString());
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      final data = ModalRoute.of(context)?.settings.arguments;
      if (data != null &&
          (data as Map<String, dynamic>)["keyId"] != null &&
          (data["password"] as String?) != null) {
        final keyId = data["keyId"] as String;
        final userPassword = data["password"];
        log("$keyId and $userPassword");
        setState(() {
          walletKeyId = keyId;
          password = userPassword;
        });
      }
      _isInitialized = true;
    }
  }

  notifyError(String message) => showCustomSnackBar(
      context: context,
      message: message,
      colors: colors,
      type: MessageType.error);

  double calcDouble(double value) {
    return value;
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final TextTheme textTheme = Theme.of(context).textTheme;
    return Scaffold(
      backgroundColor: colors.primaryColor,
      appBar: AppBar(
        backgroundColor: colors.primaryColor,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: colors.textColor),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Text(
          "Private Data Overview",
          style: textTheme.headlineMedium?.copyWith(
              color: colors.textColor,
              fontSize: 20,
              fontWeight: FontWeight.bold),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: ListView(
          children: [
            CustomFilledTextFormField(
              colors: colors,
              readOnly: true,
              fontSizeOf: calcDouble,
              iconSizeOf: calcDouble,
              roundedOf: calcDouble,
              maxLines: 5,
              minLines: 4,
              labelText: "Mnemonic",
              controller: _mnemonicController,
            ),
            SizedBox(
              height: 15,
            ),
            CustomFilledTextFormField(
              colors: colors,
              readOnly: true,
              fontSizeOf: calcDouble,
              iconSizeOf: calcDouble,
              roundedOf: calcDouble,
              maxLines: 3,
              minLines: 3,
              labelText: "Private Key",
              controller: _privateKeyController,
            ),
            SizedBox(
              height: 15,
            ),
            if (secureData?.createdLocally == false ||
                secureData?.isBackup == true)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  ConstrainedBox(
                    constraints: BoxConstraints(minWidth: width * 0.35),
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                          backgroundColor: colors.themeColor),
                      onPressed: () {
                        if (_mnemonicController.text.isEmpty) {
                          notifyError("No Mnemonic found");
                          return;
                        }
                        Clipboard.setData(
                            ClipboardData(text: _mnemonicController.text));
                      },
                      label: Text(
                        'Mnemonic',
                        style: textTheme.bodyMedium
                            ?.copyWith(color: colors.primaryColor),
                      ),
                      icon: Icon(
                        Icons.copy,
                        color: colors.primaryColor,
                      ),
                    ),
                  ),
                  ConstrainedBox(
                    constraints: BoxConstraints(minWidth: width * 0.35),
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                          backgroundColor: colors.themeColor),
                      onPressed: () {
                        if (_privateKeyController.text.isEmpty) {
                          notifyError("No Private Key found");
                          return;
                        }
                        Clipboard.setData(
                            ClipboardData(text: _privateKeyController.text));
                      },
                      label: Text(
                        'PrivateKey',
                        style: textTheme.bodyMedium
                            ?.copyWith(color: colors.primaryColor),
                      ),
                      icon: Icon(
                        Icons.copy,
                        color: colors.primaryColor,
                      ),
                    ),
                  )
                ],
              )
            else
              SizedBox(
                width: width,
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.push(
                      context,
                      PageTransition(
                          type: PageTransitionType.fade,
                          child: BackupSeedScreen(
                              publicAccount: account,
                              password: password,
                              wallet: secureData!,
                              colors: colors))),
                  label: Text(
                    "Backup phrases",
                    style: textTheme.bodyMedium
                        ?.copyWith(color: colors.primaryColor),
                  ),
                  icon: Icon(
                    Icons.info,
                    color: colors.primaryColor,
                  ),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      )),
                ),
              ),
            Align(
              alignment: Alignment.topLeft,
              child: WarningStaticMessage(
                colors: colors,
                title: "Important :",
                content:
                    "The private key and Mnemonic are secret and is the only way to access your funds. Never share your private key or Mnemonic with anyone.",
              ),
            ),
          ],
        ),
      ),
    );
  }
}
