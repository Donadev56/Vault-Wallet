// ignore_for_file: deprecated_member_use

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:moonwallet/logger/logger.dart';
import 'package:moonwallet/service/price_manager.dart';
import 'package:moonwallet/service/web3.dart';
import 'package:moonwallet/types/types.dart';
import 'package:moonwallet/utils/constant.dart';
import 'package:moonwallet/utils/crypto.dart';
import 'package:moonwallet/utils/prefs.dart';
import 'package:qr_flutter/qr_flutter.dart';

class ReceiveScreen extends StatefulWidget {
  const ReceiveScreen({super.key});

  @override
  State<ReceiveScreen> createState() => _ReceiveScreenState();
}

class _ReceiveScreenState extends State<ReceiveScreen> {
  Color primaryColor = Color(0XFF1B1B1B);
  Color textColor = Color.fromARGB(255, 255, 255, 255);
  Color secondaryColor = Colors.greenAccent;
  Color actionsColor = Color(0XFF353535);
  Color surfaceTintColor = Color(0XFF454545);
  Color warningColor = Colors.orange;
  bool _isInitialized = false;
  bool isDarkMode = false;

  List<PublicData> accounts = [];
  List<PublicData> filteredAccounts = [];
  PublicData currentAccount = PublicData(
      keyId: "",
      creationDate: 0,
      walletName: "",
      address: "",
      isWatchOnly: false);
  final web3Manager = Web3Manager();
  final encryptService = EncryptService();
  final priceManager = PriceManager();
  final publicDataManager = PublicDataManager();
  Network currentNetwork = networks[0];

  @override
  void initState() {
    super.initState();
    getSavedWallets();
    getThemeMode();
  }

  Future<void> getSavedWallets() async {
    try {
      final savedData = await web3Manager.getPublicData();

      final lastAccount = await encryptService.getLastConnectedAddress();

      int count = 0;
      if (savedData != null && lastAccount != null) {
        for (final account in savedData) {
          final newAccount = PublicData.fromJson(account);
          setState(() {
            accounts.add(newAccount);
          });
          count++;
        }
      }

      log("Retrieved $count wallets");

      for (final account in accounts) {
        if (account.address == lastAccount) {
          currentAccount = account;

          log("The current wallet is ${json.encode(account.toJson())}");
          break;
        } else {
          log("Not account found");
          currentAccount = accounts[0];
        }
      }
    } catch (e) {
      logError('Error getting saved wallets: $e');
    }
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
      if (savedMode != null && savedMode == "true") {
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
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      final data = ModalRoute.of(context)?.settings.arguments;
      if (data != null && (data as Map<String, dynamic>)["index"] != null) {
        final index = data["index"];
        currentNetwork = networks[index];
        log("Network sets to ${currentNetwork.binanceSymbol}");
      }
      _isInitialized = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: primaryColor,
      appBar: AppBar(
        backgroundColor: primaryColor,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: textColor,
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Text(
          "Receive",
          style: GoogleFonts.roboto(color: textColor, fontSize: 20),
        ),
      ),
      body: Column(
        children: [
          Container(
            width: width * 0.9,
            height: 60,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10.0),
              color: warningColor.withOpacity(0.15),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(
                  LucideIcons.octagonAlert,
                  color: warningColor,
                ),
                SizedBox(
                  width: 5,
                ),
                Expanded(
                    child: RichText(
                  text: TextSpan(
                      text: "Only send ",
                      style: GoogleFonts.roboto(color: warningColor),
                      children: [
                        TextSpan(
                          text: currentNetwork.name,
                          style: GoogleFonts.roboto(
                              color: warningColor, fontWeight: FontWeight.bold),
                        ),
                        TextSpan(
                          text:
                              " assets to this address , other assets will be lost forever.",
                          style: GoogleFonts.roboto(color: warningColor),
                        )
                      ]),
                  overflow: TextOverflow.clip,
                ))
              ],
            ),
          ),
          SizedBox(
            height: 20,
          ),
          Center(
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(50),
                      child: Image.asset(
                        currentNetwork.icon,
                        width: 25,
                        height: 25,
                      ),
                    ),
                    SizedBox(
                      width: 10,
                    ),
                    Text(
                      currentNetwork.name,
                      style: GoogleFonts.roboto(
                          color: textColor,
                          fontSize: 20,
                          fontWeight: FontWeight.bold),
                    )
                  ],
                ),
                SizedBox(
                  height: 10,
                ),
                ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: 300,
                    ),
                    child: Container(
                        width: width * 0.85,
                        padding: const EdgeInsets.all(10),
                        margin: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          color: Colors.white,
                        ),
                        child: Center(
                            child: ConstrainedBox(
                          constraints:
                              BoxConstraints(maxWidth: 300, maxHeight: 270),
                          child: QrImageView(
                            data: currentAccount.address,
                            version: 3,
                            size: width * 0.8,
                            gapless: false,
                            embeddedImage: AssetImage(currentNetwork.icon),
                            embeddedImageStyle: QrEmbeddedImageStyle(
                              size: Size(40, 40),
                            ),
                          ),
                        ))))
              ],
            ),
          ),
          SizedBox(
            height: 10,
          ),
          Center(
            child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: 300,
                ),
                child: Container(
                    width: width * 0.85,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(30),
                        color: surfaceTintColor.withOpacity(0.2)),
                    child: Center(
                      child: Text(
                        currentAccount.address,
                        style:
                            GoogleFonts.roboto(color: textColor, fontSize: 11),
                      ),
                    ))),
          ),
          SizedBox(
            height: 10,
          ),
          ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: 300,
              ),
              child: Container(
                width: width * 0.85,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Clipboard.setData(
                        ClipboardData(text: currentAccount.address.trim()));
                  },
                  icon: Icon(
                    Icons.copy,
                    color: primaryColor,
                  ),
                  label: Text("Copy the address"),
                ),
              ))
        ],
      ),
    );
  }
}
