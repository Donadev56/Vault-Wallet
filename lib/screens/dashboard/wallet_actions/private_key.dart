import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:moonwallet/logger/logger.dart';
import 'package:moonwallet/main.dart';
import 'package:moonwallet/service/web3.dart';
import 'package:moonwallet/types/types.dart';
import 'package:moonwallet/widgets/bottom_pin.dart';
import 'package:moonwallet/widgets/snackbar.dart';

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
  Color primaryColor = Color(0XFF1B1B1B);
  Color textColor = Color.fromARGB(255, 255, 255, 255);
  Color secondaryColor = Colors.greenAccent;
  Color actionsColor = Color(0XFF353535);
  Color surfaceTintColor = Color(0XFF454545);

  @override
  void initState() {
    _textController = TextEditingController();
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: secondaryColor,
        statusBarIconBrightness: Brightness.light,
      ),
    );
    createKey();
    super.initState();
  }

  Future<void> createKey() async {
    try {
      final manager = Web3Manager();

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
      showCustomSnackBar(context: context, message: "Failed to create a key");
    }
  }

  Future<PinSubmitResult> handleSubmit(String numbers) async {
    attempt++;

    final manager = Web3Manager();
    final password = await manager.getSavedPassword();
    if (password != null && numbers.trim() == password.trim()) {
      setState(() {
        userPassword = numbers.trim();
      });
      saveData();

      return PinSubmitResult(success: true, repeat: false);
    } else if (password != null && numbers.trim() != password.trim()) {
      if (attempt == 3) {
        setState(() {
          attempt = 0;
        });
        if (mounted) {
          showCustomSnackBar(
              context: context,
              message: "Too many failed attempts. Please try again later.",
              icon: Icons.error,
              iconColor: secondaryColor);
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
      if (data == null) {
        throw Exception("No key generated yet.");
      }
      final web3Manager = Web3Manager();
      final key = data!["key"];
      final mnemonic = data!["seed"];
      if (userPassword.isEmpty) {
        throw Exception("passwords must not be empty or not equal ");
      }
      final result = await web3Manager.savePrivatekeyInStorage(
          key, userPassword, "MoonWallet-1", mnemonic);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primaryColor,
      body: Container(
        decoration: BoxDecoration(color: primaryColor),
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
                  child: TextField(
                    style: GoogleFonts.exo(color: textColor),
                    readOnly: true,
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
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: OutlinedButton.icon(
                  onPressed: () {
                    Clipboard.setData(
                        ClipboardData(text: _textController.text));
                  },
                  icon: Icon(Icons.copy, color: secondaryColor),
                  label: Text(
                    "Copy the Private key",
                    style: GoogleFonts.exo2(
                      fontSize: 16,
                      color: secondaryColor,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: secondaryColor),
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
                            "The private key is secret and is the only way to access your funds. Never share your private key with anyone.",
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
                        showPinModalBottomSheet(
                            handleSubmit: handleSubmit,
                            context: context,
                            title: "Enter a secure password");
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
    );
  }
}
