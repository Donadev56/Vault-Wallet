import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:moonwallet/logger/logger.dart';
import 'package:moonwallet/main.dart';
import 'package:moonwallet/service/wallet_saver.dart';
import 'package:moonwallet/types/types.dart';
import 'package:moonwallet/widgets/bottom_pin_copy.dart';
import 'package:moonwallet/widgets/snackbar.dart';
import 'package:web3dart/web3dart.dart';

class AddPrivateKey extends StatefulWidget {
  const AddPrivateKey({super.key});

  @override
  State<AddPrivateKey> createState() => _AddPrivateKeyState();
}

class _AddPrivateKeyState extends State<AddPrivateKey> {
  late TextEditingController _textController;
  final _formKey = GlobalKey<FormState>();
  AppColors colors = AppColors(
      primaryColor: Color(0XFF0D0D0D),
      themeColor: Colors.greenAccent,
      greenColor: Colors.greenAccent,
      secondaryColor: Color(0XFF121212),
      grayColor: Color(0XFF353535),
      textColor: Colors.white,
      redColor: Colors.pinkAccent);
  String firstPassword = "";
  String secondPassword = "";

  @override
  void initState() {
    _textController = TextEditingController();
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Color(0xFF0D0D0D),
        statusBarIconBrightness: Brightness.light,
      ),
    );
    super.initState();
  }

  Future<PinSubmitResult> handleSubmit(String numbers) async {
    if (firstPassword.isEmpty) {
      setState(() {
        firstPassword = numbers;
      });
      return PinSubmitResult(
          success: true, repeat: true, newTitle: "Re-enter the password");
    } else if (firstPassword == numbers) {
      setState(() {
        secondPassword = numbers;
      });
      saveData();
      return PinSubmitResult(success: true, repeat: false);
    } else {
      setState(() {
        firstPassword = "";
        secondPassword = "";
      });
      return PinSubmitResult(
          success: false,
          repeat: true,
          newTitle: "Enter a secure password",
          error: "Password does not match");
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
      final web3Manager = WalletSaver();
      final key = _textController.text.trim();
      if (firstPassword.isEmpty || firstPassword != secondPassword) {
        throw Exception("passwords must not be empty or not equal ");
      }
      final result = await web3Manager.savePrivatekeyInStorage(
          key, firstPassword, "MoonWallet-1", null);

      if (result) {
        if (!mounted) return;
        showCustomSnackBar(
            colors: colors,
            primaryColor: colors.primaryColor,
            context: context,
            message: "Data saved successfully",
            icon: Icons.check_circle,
            iconColor: Colors.greenAccent);
        Navigator.pushNamed(context, Routes.pageManager);
      } else {
        throw Exception("Failed to save the key.");
      }
    } catch (e) {
      logError(e.toString());
      showCustomSnackBar(
          colors: colors,
          primaryColor: colors.primaryColor,
          context: context,
          message: "Failed to save the key.",
          iconColor: Colors.pinkAccent);
      setState(() {
        firstPassword = "";
        secondPassword = "";
      });
    }
  }

  bool keyTester(String data) {
    try {
      final key = data.trim();
      String hexKey;
      if (key.isEmpty) {
        showCustomSnackBar(
            colors: colors,
            primaryColor: colors.primaryColor,
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
        backgroundColor: Color(0XFF0D0D0D),
        body: Form(
          key: _formKey,
          child: Container(
            decoration: BoxDecoration(color: Color(0XFF0D0D0D)),
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
                            color: Colors.white,
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
                        style: GoogleFonts.exo2(color: Colors.white),
                        cursorColor: Colors.greenAccent,
                        minLines: 3,
                        maxLines: 5,
                        controller: _textController,
                        decoration: InputDecoration(
                          enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                  width: 1, color: Colors.greenAccent)),
                          focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                  width: 1, color: Colors.greenAccent)),
                          labelText: 'Private Key',
                          labelStyle: TextStyle(color: Colors.white),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: Colors.white),
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
                            icon: const Icon(Icons.paste,
                                color: Colors.greenAccent),
                            label: Text(
                              "Paste",
                              style: GoogleFonts.exo2(
                                fontSize: 16,
                                color: Colors.greenAccent,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Colors.greenAccent),
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
                            icon: const Icon(LucideIcons.maximize,
                                color: Colors.greenAccent),
                            label: Text(
                              "Scan",
                              style: GoogleFonts.exo2(
                                fontSize: 16,
                                color: Colors.greenAccent,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Colors.greenAccent),
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
                                      color: Colors.white,
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
                                    color: Colors.white.withOpacity(0.5),
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
                            backgroundColor: Colors.transparent,
                            side:
                                BorderSide(color: Colors.greenAccent, width: 1),
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
                              color: Colors.greenAccent,
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
                              color: Colors.black,
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
