import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:moonwallet/logger/logger.dart';
import 'package:moonwallet/main.dart';
import 'package:moonwallet/service/wallet_saver.dart' show WalletSaver;
import 'package:moonwallet/types/types.dart';
import 'package:moonwallet/utils/prefs.dart';
import 'package:moonwallet/widgets/bottom_pin.dart';
import 'package:moonwallet/widgets/snackbar.dart';
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
  Color primaryColor = Color(0XFF1B1B1B);
  Color textColor = Color.fromARGB(255, 255, 255, 255);
  Color secondaryColor = Colors.greenAccent;
  Color actionsColor = Color(0XFF353535);
  Color surfaceTintColor = Color(0XFF454545);
  final manager = WalletSaver();

  @override
  void initState() {
    _textController = TextEditingController();
    getThemeMode();
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: primaryColor,
        statusBarIconBrightness: Brightness.light,
      ),
    );
    super.initState();
  }

  void setLightMode() {
    setState(() {
      isDarkMode = !isDarkMode;
      primaryColor = Color(0xFFE4E4E4);
      textColor = Color(0xFF0A0A0A);
      actionsColor = Color(0xFFCACACA);
      surfaceTintColor = Color(0xFFBABABA);
      secondaryColor = Color(0xFF960F51);
    });
  }

  void setDarkMode() {
    setState(() {
      isDarkMode = !isDarkMode;
      primaryColor = Color(0XFF1B1B1B);
      textColor = Color.fromARGB(255, 255, 255, 255);
      secondaryColor = Colors.greenAccent;
      actionsColor = Color(0XFF353535);
      surfaceTintColor = Color(0XFF454545);
    });
  }

  Future<void> getThemeMode() async {
    try {
      final savedMode =
          await publicDataManager.getDataFromPrefs(key: "isDarkMode");
      if (savedMode == null) {
        return;
      }
      if (savedMode == "true") {
        setDarkMode();
      } else {
        setLightMode();
      }
    } catch (e) {
      logError(e.toString());
    }
  }

  Future<void> toggleMode() async {
    try {
      if (isDarkMode) {
        setLightMode();

        await publicDataManager.saveDataInPrefs(
            data: "false", key: "isDarkMode");
      } else {
        setDarkMode();
        await publicDataManager.saveDataInPrefs(
            data: "true", key: "isDarkMode");
      }
    } catch (e) {
      logError(e.toString());
    }
  }

  Future<PinSubmitResult> handleSubmit(String numbers) async {
    attempt++;
    secAttempt++;
    final password = await manager.getSavedPassword();
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
            context: context,
            message: "Data saved successfully",
            icon: Icons.check_circle,
            iconColor: secondaryColor);
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
      final key = data.trim();
      if (key.length < 60) {
        showCustomSnackBar(
            context: context,
            message: "Private key is not valid.",
            iconColor: Colors.pinkAccent);
        return false;
      }
      String hexKey;
      if (key.isEmpty) {
        showCustomSnackBar(
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: primaryColor,
        body: Form(
          key: _formKey,
          child: Container(
            decoration: BoxDecoration(color: primaryColor),
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
                            color: textColor,
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
                          color: textColor,
                        ),
                        cursorColor: secondaryColor,
                        minLines: 3,
                        maxLines: 5,
                        controller: _textController,
                        decoration: InputDecoration(
                          enabledBorder: OutlineInputBorder(
                              borderSide:
                                  BorderSide(width: 1, color: secondaryColor)),
                          focusedBorder: OutlineInputBorder(
                              borderSide:
                                  BorderSide(width: 1, color: secondaryColor)),
                          labelText: 'Private Key',
                          labelStyle: TextStyle(color: textColor),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: textColor),
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
                            icon: Icon(Icons.paste, color: secondaryColor),
                            label: Text(
                              "Paste",
                              style: GoogleFonts.exo2(
                                fontSize: 16,
                                color: secondaryColor,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: secondaryColor),
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
                                color: secondaryColor),
                            label: Text(
                              "Scan",
                              style: GoogleFonts.exo2(
                                fontSize: 16,
                                color: secondaryColor,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: secondaryColor),
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
                                      color: textColor,
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
                                    color: textColor.withOpacity(0.5),
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
                            backgroundColor: primaryColor,
                            side: BorderSide(color: secondaryColor, width: 1),
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
                              color: secondaryColor,
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
                                  handleSubmit: handleSubmit,
                                  context: context,
                                  title: "Enter a secure password");
                            }
                          },
                          child: Text(
                            "Next",
                            style: GoogleFonts.exo(
                              fontSize: 18,
                              color: primaryColor,
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
