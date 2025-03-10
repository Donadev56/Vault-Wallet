import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:moonwallet/logger/logger.dart';
import 'package:moonwallet/main.dart';
import 'package:moonwallet/service/wallet_saver.dart';
import 'package:moonwallet/types/types.dart';
import 'package:moonwallet/widgets/bottom_pin.dart';
import 'package:moonwallet/widgets/snackbar.dart';

class CreatePrivateKey extends StatefulWidget {
  const CreatePrivateKey({super.key});

  @override
  State<CreatePrivateKey> createState() => _CreatePrivateKeyState();
}

class _CreatePrivateKeyState extends State<CreatePrivateKey> {
  late TextEditingController _textController;
  Map<String, dynamic>? data;
  String firstPassword = "";
  String secondPassword = "";
  final manager = WalletSaver();
  AppColors colors = AppColors(
      primaryColor: Color(0XFF0D0D0D),
      themeColor: Colors.greenAccent,
      greenColor: Colors.greenAccent,
      secondaryColor: Color(0XFF121212),
      grayColor: Color(0XFF353535),
      textColor: Colors.white,
      redColor: Colors.pinkAccent);
  @override
  void initState() {
    _textController = TextEditingController();
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Color(0xFF0D0D0D),
        statusBarIconBrightness: Brightness.light,
      ),
    );
    createKey();
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

          primaryColor: colors.primaryColor,
          context: context,
          message: "Failed to create a key");
    }
  }

  Future<PinSubmitResult> handleSubmit(String numbers) async {
    if (firstPassword.isEmpty) {
      setState(() {
        firstPassword = numbers;
      });
      return PinSubmitResult(
          success: true, repeat: true, newTitle: "Re-enter the password");
    } else if (firstPassword == numbers) {
      log("The password is correct");

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
      if (data == null) {
        throw Exception("No key generated yet.");
      }
      final key = data!["key"];
      final mnemonic = data!["seed"];
      if (firstPassword.isEmpty || firstPassword != secondPassword) {
        throw Exception("passwords must not be empty or not equal ");
      }
      final result = await manager.savePrivatekeyInStorage(
          key, firstPassword, "MoonWallet-1", mnemonic);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0XFF0D0D0D),
      body: Container(
        decoration: BoxDecoration(color: Color(0XFF0D0D0D)),
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
                  child: TextField(
                    style: GoogleFonts.exo(color: Colors.white),
                    readOnly: true,
                    minLines: 3,
                    maxLines: 5,
                    controller: _textController,
                    decoration: InputDecoration(
                      enabledBorder: OutlineInputBorder(
                          borderSide:
                              BorderSide(width: 1, color: Colors.greenAccent)),
                      focusedBorder: OutlineInputBorder(
                          borderSide:
                              BorderSide(width: 1, color: Colors.greenAccent)),
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
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: OutlinedButton.icon(
                  onPressed: () {
                    Clipboard.setData(
                        ClipboardData(text: _textController.text));
                  },
                  icon: const Icon(Icons.copy, color: Colors.greenAccent),
                  label: Text(
                    "Copy the Private key",
                    style: GoogleFonts.exo2(
                      fontSize: 16,
                      color: Colors.greenAccent,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.greenAccent),
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
                                  color: Colors.white,
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
                        side: BorderSide(color: Colors.greenAccent, width: 1),
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
                        showPinModalBottomSheet(
                            colors: colors,
                            handleSubmit: handleSubmit,
                            context: context,
                            title: "Enter a secure password");
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
    );
  }
}
