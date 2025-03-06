import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:moonwallet/logger/logger.dart';
import 'package:moonwallet/service/price_manager.dart';
import 'package:moonwallet/service/wallet_saver.dart';
import 'package:moonwallet/service/web3_interaction.dart';
import 'package:moonwallet/types/types.dart';
import 'package:moonwallet/utils/crypto.dart';
import 'package:moonwallet/utils/prefs.dart';
import 'package:moonwallet/widgets/snackbar.dart';

class PrivateKeyScreen extends StatefulWidget {
  const PrivateKeyScreen({super.key});

  @override
  State<PrivateKeyScreen> createState() => _PrivateKeyScreenState();
}

class _PrivateKeyScreenState extends State<PrivateKeyScreen> {
  Color primaryColor = Color(0XFF1B1B1B);
  Color textColor = Color.fromARGB(255, 255, 255, 255);
  Color secondaryColor = Colors.greenAccent;
  Color actionsColor = Color(0XFF353535);
  Color surfaceTintColor = Color(0XFF454545);
  Color darkNavigatorColor = Color(0XFF0D0D0D);
  bool isDarkMode = false;

  final TextEditingController _mnemonicController = TextEditingController();
  final TextEditingController _privateKeyController = TextEditingController();
  bool _isInitialized = false;

  final web3Manager = WalletSaver();
  final encryptService = EncryptService();
  final priceManager = PriceManager();
  final web3InteractManager = Web3InteractionManager();
  final publicDataManager = PublicDataManager();
  String walletKeyId = "";
  String password = "";

  @override
  void initState() {
    getThemeMode();
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      showWarn();
    });
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

  @override
  void dispose() {
    _mnemonicController.dispose();
    _privateKeyController.dispose();
    super.dispose();
  }

  Future<void> getDecryptedData() async {
    try {
      final decryptedData = await web3Manager.getDecryptedData(password);
      final List<SecureData> listEncData = [];
      if (decryptedData != null) {
        for (final data in decryptedData) {
          final SecureData newData = SecureData(
            address: data["address"],
            privateKey: data["privatekey"],
            keyId: data["keyId"],
            creationDate: data["creationDate"],
            walletName: data["walletName"],
            mnemonic: data["mnemonic"] ?? "No Mnemonic",
          );
          listEncData.add(newData);
        }

        if (listEncData.isNotEmpty) {
          for (final eachData in listEncData) {
            if (eachData.keyId.trim().toLowerCase() ==
                walletKeyId.trim().toLowerCase()) {
              if (eachData.mnemonic != null && eachData.mnemonic is String) {
                _mnemonicController.text =
                    eachData.mnemonic ?? "No data found for Mnemonic";
              }
              if (eachData.privateKey.isNotEmpty) {
                _privateKeyController.text = eachData.privateKey;
              }
            }
          }
        } else {
          if (mounted) {
            showCustomSnackBar(
                context: context,
                message: "No encrypted data found",
                iconColor: Colors.pinkAccent);
          }
        }
      } else {
        if (mounted) {
          showCustomSnackBar(
              context: context,
              message: "No decrypted data found",
              iconColor: Colors.pinkAccent);
        }
      }
    } catch (e) {
      if (mounted) {
        showCustomSnackBar(
            context: context,
            message: "An error occurred data",
            iconColor: Colors.pinkAccent);
      }

      logError(e.toString());
    }
  }

  void showWarn() {
    showDialog(
        context: context,
        builder: (BuildContext ctx) {
          return BackdropFilter(
            filter: ImageFilter.blur(
              sigmaX: 8.0,
              sigmaY: 8.0,
            ),
            child: AlertDialog(
              backgroundColor: primaryColor,
              title: Text(
                "Warning",
                style: GoogleFonts.roboto(color: Colors.orange),
              ),
              content: Text(
                "You are about to view sensitive information, make sure you are not in a public place and that no one is looking at your screen.",
                style: GoogleFonts.roboto(color: Colors.pinkAccent),
              ),
              actions: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    TextButton.icon(
                      icon: Icon(
                        Icons.arrow_back,
                        color: textColor,
                      ),
                      onPressed: () {
                        Navigator.pop(ctx);
                        Navigator.pop(context);
                      },
                      label: Text(
                        "Go back",
                        style: GoogleFonts.roboto(color: textColor),
                      ),
                    ),
                    TextButton.icon(
                      icon: Icon(
                        Icons.remove_red_eye,
                        color: textColor,
                      ),
                      onPressed: () {
                        getDecryptedData();
                        Navigator.pop(ctx);
                      },
                      label: Text(
                        "View",
                        style: GoogleFonts.roboto(color: textColor),
                      ),
                    ),
                  ],
                )
              ],
            ),
          );
        });
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

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return Scaffold(
      backgroundColor: primaryColor,
      appBar: AppBar(
        backgroundColor: primaryColor,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textColor),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Text(
          "Private Data Overview",
          style: GoogleFonts.roboto(color: textColor),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          children: [
            TextField(
              readOnly: true,
              controller: _mnemonicController,
              minLines: 4,
              maxLines: 5,
              style: GoogleFonts.roboto(color: textColor),
              decoration: InputDecoration(
                  label: Text("Mnemonic"),
                  labelStyle: GoogleFonts.roboto(color: textColor),
                  enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(width: 1, color: secondaryColor)),
                  border: OutlineInputBorder(
                      borderSide: BorderSide(width: 1, color: secondaryColor))),
            ),
            SizedBox(
              height: 15,
            ),
            TextField(
              readOnly: true,
              controller: _privateKeyController,
              minLines: 2,
              maxLines: 3,
              style: GoogleFonts.roboto(color: textColor),
              decoration: InputDecoration(
                  label: Text("Private  Key"),
                  labelStyle: GoogleFonts.roboto(color: textColor),
                  enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(width: 1, color: secondaryColor)),
                  border: OutlineInputBorder(
                      borderSide: BorderSide(width: 1, color: secondaryColor))),
            ),
            SizedBox(
              height: 15,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                ConstrainedBox(
                  constraints: BoxConstraints(minWidth: width * 0.35),
                  child: ElevatedButton.icon(
                    onPressed: () {
                      if (_mnemonicController.text.isEmpty) {
                        showCustomSnackBar(
                            context: context,
                            message: "No Mnemonic found",
                            iconColor: Colors.pinkAccent);
                        return;
                      }
                      Clipboard.setData(
                          ClipboardData(text: _mnemonicController.text));
                    },
                    label: Text('Mnemonic'),
                    icon: Icon(
                      Icons.copy,
                      color: primaryColor,
                    ),
                  ),
                ),
                ConstrainedBox(
                  constraints: BoxConstraints(minWidth: width * 0.35),
                  child: ElevatedButton.icon(
                    onPressed: () {
                      if (_privateKeyController.text.isEmpty) {
                        showCustomSnackBar(
                            context: context,
                            message: "No Private Key found",
                            iconColor: Colors.pinkAccent);
                        return;
                      }
                      Clipboard.setData(
                          ClipboardData(text: _privateKeyController.text));
                    },
                    label: Text('PrivateKey'),
                    icon: Icon(
                      Icons.copy,
                      color: primaryColor,
                    ),
                  ),
                )
              ],
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
                          "The private key and Mnemonic are secret and is the only way to access your funds. Never share your private key or Mnemonic with anyone.",
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
          ],
        ),
      ),
    );
  }
}
