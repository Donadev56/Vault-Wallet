import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:moonwallet/logger/logger.dart';
import 'package:moonwallet/main.dart';
import 'package:moonwallet/service/wallet_saver.dart';
import 'package:moonwallet/types/types.dart';
import 'package:moonwallet/utils/colors.dart';
import 'package:moonwallet/utils/prefs.dart';
import 'package:moonwallet/utils/themes.dart';
import 'package:moonwallet/widgets/bottom_pin.dart';
import 'package:moonwallet/widgets/snackbar.dart';

class AddMnemonicScreen extends StatefulWidget {
  const AddMnemonicScreen({super.key});

  @override
  State<AddMnemonicScreen> createState() => _AddPrivateKeyState();
}

class _AddPrivateKeyState extends State<AddMnemonicScreen> {
  late TextEditingController _textController;
  final _formKey = GlobalKey<FormState>();
  String userPassword = "";
  int attempt = 0;
  int secAttempt = 0;
  final web3Manager = WalletSaver();
  final publicDataManager = PublicDataManager();
  bool isDarkMode = false;

  AppColors colors = AppColors(
      primaryColor: Color(0XFF0D0D0D),
      themeColor: Colors.greenAccent,
      greenColor: Colors.greenAccent,
      secondaryColor: Color(0XFF121212),
      grayColor: Color(0XFF353535),
      textColor: Colors.white,
      redColor: Colors.pinkAccent);
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

    super.initState();
    getSavedTheme();
  }

  Future<PinSubmitResult> handleSubmit(String numbers) async {
    attempt++;
    secAttempt++;
    final password = await web3Manager.getSavedPassword();
    if (password != null && numbers.trim() == password.trim()) {
      setState(() {
        userPassword = numbers.trim();
      });
      saveData();

      return PinSubmitResult(success: true, repeat: false);
    } else if (password != null && numbers.trim() != password.trim()) {
      if (secAttempt == 6) {
        setState(() {
          secAttempt = 0;
        });
        if (mounted) {
          Navigator.pushNamed(context, Routes.main);
        }
      }
      if (attempt == 3) {
        if (mounted) {
          setState(() {
            attempt = 0;
          });
          showCustomSnackBar(
              context: context,
              message: "Too many failed attempts.",
              icon: Icons.error,
              iconColor: Colors.pinkAccent);
          return PinSubmitResult(success: false, repeat: false);
        }
      }

      return PinSubmitResult(
          success: false,
          repeat: true,
          newTitle: "Enter a correct password",
          error: "Incorrect password");
    } else {
      logError('The password is not defined $password');

      return PinSubmitResult(
        success: false,
        repeat: false,
      );
    }
  }

  Future<void> saveData() async {
    try {
      final bool testResult = keyTester(_textController.text);

      if (!testResult) {
        throw Exception("Invalid Seed.");
      }
      if (_textController.text.isEmpty) {
        throw Exception("No Seed generated yet.");
      }
      final secretData =
          await web3Manager.createPrivatekeyFromSeed(_textController.text);

      final key = secretData["key"];
      if (userPassword.isEmpty) {
        throw Exception("passwords must not be empty ");
      }
      final result = await web3Manager.savePrivatekeyInStorage(
          key, userPassword, "New Wallet", _textController.text);
      if (result) {
        if (!mounted) return;
        showCustomSnackBar(
            context: context,
            message: "Data saved successfully",
            icon: Icons.check_circle,
            iconColor: colors.themeColor);
        Navigator.pushNamed(context, Routes.main);
      } else {
        throw Exception("Failed to save the key.");
      }
    } catch (e) {
      logError(e.toString());
      showCustomSnackBar(
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
      if (data.trim() != data) return false;

      if (data.contains('  ')) return false;

      final words = data.split(' ');

      if (words.length != 12) return false;

      if (words.any((word) => word.isEmpty)) return false;
      return true;
    } catch (e) {
      logError(e.toString());
      return false;
    }
  }

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
                        "Add Mnemonic phrase",
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
                        inputFormatters: [SingleSpaceTextInputFormatter()],
                        validator: (value) {
                          if (value != null) {
                            final res = keyTester(value);
                            if (res) {
                              return null;
                            } else {
                              return "Invalid 12 words";
                            }
                          } else {
                            return "Please enter your 12 words";
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
                          enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                  width: 1, color: colors.themeColor)),
                          focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                  width: 1, color: colors.themeColor)),
                          labelText: 'Mnemonic',
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
                                color: colors.primaryColor,
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
                            onPressed: () {},
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
                                "The Seed phrase is secret and is the only way to access your funds. Never share your private key with anyone and keep it in a safe place.",
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
                        child: ElevatedButton(
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
                          ),
                          onPressed: () {
                            if (_formKey.currentState?.validate() ?? false) {
                              showPinModalBottomSheet(
                                  colors: colors,
                                  handleSubmit: handleSubmit,
                                  context: context,
                                  title: "Enter a secure password");
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

class SingleSpaceTextInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final cleanedText = newValue.text.replaceAll(RegExp(r'\s{2,}'), ' ');

    List<String> words =
        cleanedText.split(' ').where((word) => word.isNotEmpty).toList();

    if (words.length == 12 && cleanedText.endsWith(' ')) {
      return oldValue;
    }

    if (words.length > 12) {
      return oldValue;
    }

    int selectionIndex =
        newValue.selection.end - (newValue.text.length - cleanedText.length);
    if (selectionIndex < 0) selectionIndex = 0;

    return TextEditingValue(
      text: cleanedText.toLowerCase(),
      selection: TextSelection.collapsed(offset: selectionIndex),
    );
  }
}
