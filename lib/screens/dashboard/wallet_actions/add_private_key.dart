import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:moonwallet/logger/logger.dart';
import 'package:moonwallet/main.dart';
import 'package:moonwallet/service/wallet_saver.dart' show WalletSaver;
import 'package:moonwallet/types/types.dart';
import 'package:moonwallet/utils/colors.dart';
import 'package:moonwallet/utils/prefs.dart';
import 'package:moonwallet/utils/themes.dart';
import 'package:moonwallet/widgets/func/ask_password.dart';
import 'package:moonwallet/widgets/func/snackbar.dart';
import 'package:moonwallet/widgets/scanner/scanner.dart';
import 'package:moonwallet/widgets/scanner/show_scanner.dart';
import 'package:web3dart/web3dart.dart';

class AddPrivateKeyInMain extends StatefulWidget {
  const AddPrivateKeyInMain({super.key});

  @override
  State<AddPrivateKeyInMain> createState() => _AddPrivateKeyState();
}

class _AddPrivateKeyState extends State<AddPrivateKeyInMain> {
  late TextEditingController _textController;
  final _formKey = GlobalKey<FormState>();
  String userPassword = "";
  int attempt = 0;
  int secAttempt = 0;
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

    super.initState();
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
      final bool testResult = keyTester(_textController.text);
      if (!testResult) {
        throw Exception("Invalid private key.");
      }
      if (_textController.text.isEmpty) {
        throw Exception("No key generated yet.");
      }
      final key = _textController.text.trim();
      if (userPassword.isEmpty) {
        throw Exception("passwords must not be empty ");
      }
      final result = await manager.savePrivatekeyInStorage(
          key, userPassword, "MoonWallet-1", null);
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

  bool keyTester(String data) {
    try {
      final key = data.trim();
      if (key.length < 60) {
        showCustomSnackBar(
            colors: colors,
            type: MessageType.error,
            context: context,
            message: "Private key is not valid.",
            iconColor: Colors.pinkAccent);
        return false;
      }
      String hexKey;
      if (key.isEmpty) {
        showCustomSnackBar(
            colors: colors,
            type: MessageType.error,
            context: context,
            message: "Please enter a private key !",
            iconColor: Colors.pinkAccent);
        return false;
      }

      if (key.startsWith("0x")) {
        hexKey = key.substring(2);
        log("The new key is  : $hexKey");
      } else {
        hexKey = key;
      }

      Credentials fromHex = EthPrivateKey.fromHex(hexKey);
      if (fromHex.address.hex.isNotEmpty) {
        log("Address found : ${fromHex.address.hex}");
        return true;
      } else {
        return false;
      }
    } catch (e) {
      logError(e.toString());
      return false;
    }
  }

  final MobileScannerController _mobileScannerController =
      MobileScannerController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: colors.primaryColor,
        body: Form(
          key: _formKey,
          child: Container(
            decoration: BoxDecoration(color: colors.primaryColor),
            child: SafeArea(
                child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.max,
                children: [
                  Align(
                    alignment: Alignment.topLeft,
                    child: Container(
                      margin: const EdgeInsets.only(top: 25, left: 20),
                      child: Text(
                        "Add Private Key",
                        style: GoogleFonts.exo2(
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
                      child: TextFormField(
                        validator: (value) {
                          if (value != null) {
                            final res = keyTester(value);
                            if (res) {
                              return null;
                            } else {
                              return "Invalid private key";
                            }
                          } else {
                            return "Please enter a private key";
                          }
                        },
                        style: GoogleFonts.exo2(
                          color: colors.textColor,
                        ),
                        cursorColor: colors.themeColor,
                        minLines: 3,
                        maxLines: 5,
                        controller: _textController,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: colors.secondaryColor,
                          enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                  width: 0, color: Colors.transparent)),
                          focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                  width: 0, color: Colors.transparent)),
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
                  Row(
                    children: [
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              final data =
                                  await Clipboard.getData("text/plain");
                              if (data != null && data.text != null) {
                                log(data.toString());
                                setState(() {
                                  String text = data.text ?? "";
                                  _textController.text = text;
                                });
                              }
                            },
                            icon: Icon(Icons.paste, color: colors.themeColor),
                            label: Text(
                              "Paste",
                              style: GoogleFonts.exo2(
                                fontSize: 16,
                                color: colors.themeColor,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: colors.themeColor),
                              // Instead of setting an infinite width, just set the height.
                              minimumSize: const Size.fromHeight(50),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: OutlinedButton.icon(
                            onPressed: () {
                              showScanner(
                                  context: context,
                                  controller: _mobileScannerController,
                                  colors: colors,
                                  onResult: (result) {
                                    setState(() {
                                      _textController.text = result;
                                    });
                                  });
                            },
                            icon: Icon(LucideIcons.maximize,
                                color: colors.themeColor),
                            label: Text(
                              "Scan",
                              style: GoogleFonts.exo2(
                                fontSize: 16,
                                color: colors.themeColor,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: colors.themeColor),
                              minimumSize: const Size.fromHeight(50),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
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
                                  style: GoogleFonts.exo(
                                      fontSize: 16,
                                      color: colors.textColor,
                                      decoration: TextDecoration.none)),
                            ],
                          )),
                          WidgetSpan(
                            child: Padding(
                              padding: const EdgeInsets.only(top: 10),
                              child: Text(
                                "The private key is secret and is the only way to access your funds. Never share your private key with anyone and keep it in a safe place.",
                                style: GoogleFonts.exo(
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
                            side:
                                BorderSide(color: colors.themeColor, width: 1),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          child: Text(
                            "Previous",
                            style: GoogleFonts.exo(
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
                            if (_formKey.currentState?.validate() ?? false) {
                              await handleSubmit();
                            }
                          },
                          child: Text(
                            "Next",
                            style: GoogleFonts.exo(
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
        ));
  }
}
