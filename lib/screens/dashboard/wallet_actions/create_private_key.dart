import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:moonwallet/custom/web3_webview/lib/utils/loading.dart';
import 'package:moonwallet/logger/logger.dart';
import 'package:moonwallet/main.dart';
import 'package:moonwallet/service/wallet_saver.dart';
import 'package:moonwallet/types/types.dart';
import 'package:moonwallet/utils/colors.dart';
import 'package:moonwallet/utils/prefs.dart';
import 'package:moonwallet/utils/themes.dart';
import 'package:moonwallet/widgets/func/ask_password.dart';
import 'package:moonwallet/widgets/func/snackbar.dart';

class CreatePrivateKeyMain extends StatefulWidget {
  const CreatePrivateKeyMain({super.key});

  @override
  State<CreatePrivateKeyMain> createState() => _CreatePrivateKeyState();
}

class _CreatePrivateKeyState extends State<CreatePrivateKeyMain> {
  late TextEditingController _textController;
  Map<String, dynamic>? data;
  String userPassword = "";
  int attempt = 0;

  final publicDataManager = PublicDataManager();
  bool isDarkMode = false;
  final manager = WalletSaver();
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

  @override
  void initState() {
    _textController = TextEditingController();
    getSavedTheme();
    WidgetsBinding.instance.addPostFrameCallback((time) async {
      await createKey().withLoading(context, colors);
    });

    super.initState();
  }

  Future<void> createKey() async {
    try {
      final key = await manager.createPrivatekey();
      if (key.isNotEmpty) {
        setState(() {
          _textController.text = "0x${key["key"]}";
          data = key;
        });
      } else {
        throw Exception("The key is Null");
      }
    } catch (e) {
      if (!mounted) return;
      showCustomSnackBar(
          colors: colors,
          type: MessageType.error,
          context: context,
          message: "Failed to create a key");
    }
  }

  Future<void> handleSubmit() async {
    try {
      final password = await askPassword(context: context, colors: colors);
      if (password.isNotEmpty) {
        setState(() {
          userPassword = password;
        });
        saveData();
      }
    } catch (e) {
      logError(e.toString());
      showCustomSnackBar(
          colors: colors,
          type: MessageType.error,
          context: context,
          message: "Error occurred while creating private key.",
          icon: Icons.error,
          iconColor: Colors.redAccent);
    }
  }

  Future<void> saveData() async {
    try {
      if (data == null) {
        throw Exception("No key generated yet.");
      }
      final key = data!["key"];
      final mnemonic = data!["seed"];
      if (userPassword.isEmpty) {
        throw Exception("passwords must not be empty or not equal ");
      }
      final result = await manager.savePrivatekeyInStorage(
          key, userPassword, "MoonWallet-1", mnemonic);
      if (result) {
        if (!mounted) return;
        showCustomSnackBar(
            colors: colors,
            type: MessageType.success,
            context: context,
            message: "Data saved successfully",
            icon: Icons.check_circle,
            iconColor: colors.themeColor);

        Navigator.pushNamed(context, Routes.pageManager);
      } else {
        throw Exception("Failed to save the key.");
      }
    } catch (e) {
      logError(e.toString());
      showCustomSnackBar(
          colors: colors,
          type: MessageType.error,
          context: context,
          message: "Failed to save the key.",
          iconColor: Colors.pinkAccent);
      setState(() {
        userPassword = "";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      backgroundColor: colors.primaryColor,
      body: Container(
        decoration: BoxDecoration(color: colors.primaryColor),
        child: SafeArea(
            child: SingleChildScrollView(
          child: Column(
            children: [
              Align(
                alignment: Alignment.topLeft,
                child: Container(
                  margin: const EdgeInsets.only(top: 25, left: 20),
                  child: Text(
                    "Create private key",
                    style: textTheme.headlineMedium?.copyWith(
                        color: colors.textColor,
                        fontSize: 24,
                        decoration: TextDecoration.none),
                  ),
                ),
              ),
              SizedBox(
                height: 20,
              ),
              Container(
                margin: const EdgeInsets.all(20),
                child: Material(
                  color: Colors.transparent,
                  child: TextField(
                    style: textTheme.bodyMedium?.copyWith(color: colors.textColor),
                    readOnly: true,
                    minLines: 3,
                    maxLines: 5,
                    controller: _textController,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: colors.secondaryColor,
                      enabledBorder: OutlineInputBorder(
                          borderSide:
                              BorderSide(width: 0, color: Colors.transparent)),
                      focusedBorder: OutlineInputBorder(
                          borderSide:
                              BorderSide(width: 0, color: Colors.transparent)),
                      labelText: 'Private Key',
                      labelStyle: TextStyle(color: colors.textColor),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: colors.textColor),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: OutlinedButton.icon(
                  onPressed: () {
                    Clipboard.setData(
                        ClipboardData(text: _textController.text));
                  },
                  icon: Icon(Icons.copy, color: colors.themeColor),
                  label: Text(
                    "Copy the Private key",
                    style: textTheme.bodyMedium?.copyWith(
                      fontSize: 16,
                      color: colors.themeColor,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: colors.themeColor),
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                ),
              ),
              SizedBox(
                height: 20,
              ),
              Align(
                alignment: Alignment.topLeft,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: RichText(
                    text: TextSpan(children: [
                      WidgetSpan(
                          child: Row(
                        children: [
                          Icon(
                            LucideIcons.circleAlert,
                            color: Colors.pinkAccent,
                          ),
                          SizedBox(
                            width: 5,
                          ),
                          Text("Important :",
                              style: textTheme.bodyMedium?.copyWith(
                                  fontSize: 16,
                                  color: colors.textColor,
                                  decoration: TextDecoration.none)),
                        ],
                      )),
                      WidgetSpan(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 10),
                          child: Text(
                            "The private key is secret and is the only way to access your funds. Never share your private key with anyone.",
                            style: textTheme.bodyMedium?.copyWith(
                                fontSize: 16,
                                color: colors.textColor.withOpacity(0.5),
                                decoration: TextDecoration.none),
                          ),
                        ),
                      ),
                    ]),
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Padding(
                    padding: EdgeInsets.only(
                        bottom: 20, left: 20), // Optional padding
                    child: OutlinedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colors.primaryColor,
                        side: BorderSide(color: colors.themeColor, width: 1),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: Text(
                        "Previous",
                        style: textTheme.bodyMedium?.copyWith(
                          fontSize: 18,
                          color: colors.themeColor,
                          decoration: TextDecoration.none,
                        ),
                      ),
                    ),
                  ),
                  Spacer(),
                  Padding(
                    padding: EdgeInsets.only(
                        bottom: 20, right: 20), // Optional padding
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          backgroundColor: colors.themeColor),
                      onPressed: () async {
                        await handleSubmit();
                      },
                      child: Text(
                        "Next",
                        style: textTheme.bodyMedium?.copyWith(
                          fontSize: 18,
                          color: colors.primaryColor,
                          decoration: TextDecoration.none,
                        ),
                      ),
                    ),
                  ),
                ],
              )
            ],
          ),
        )),
      ),
    );
  }
}
