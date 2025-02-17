// ignore_for_file: deprecated_member_use

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:flutter_web3_webview/flutter_web3_webview.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:moonwallet/logger/logger.dart';
import 'package:moonwallet/service/price_manager.dart';
import 'package:moonwallet/service/vibration.dart';
import 'package:moonwallet/service/web3.dart';
import 'package:moonwallet/service/web3_interaction.dart';
import 'package:moonwallet/types/types.dart';
import 'package:moonwallet/utils/constant.dart';
import 'package:moonwallet/utils/crypto.dart';
import 'package:moonwallet/utils/prefs.dart';
import 'package:moonwallet/widgets/askUserforconf.dart';
import 'package:moonwallet/widgets/bottom_pin_copy.dart';
import 'package:web3dart/web3dart.dart';

class SendTransactionScreen extends StatefulWidget {
  const SendTransactionScreen({super.key});

  @override
  State<SendTransactionScreen> createState() => _SendTransactionScreenState();
}

class _SendTransactionScreenState extends State<SendTransactionScreen> {
  final _formKey = GlobalKey<FormState>();

  Color primaryColor = Color(0XFF1B1B1B);
  Color textColor = Color.fromARGB(255, 255, 255, 255);
  Color secondaryColor = Colors.greenAccent;
  Color actionsColor = Color(0XFF353535);
  Color surfaceTintColor = Color(0XFF454545);
  double userBalance = 0;
  double cryptoPrice = 0;
  Color darkNavigatorColor = Color(0XFF0D0D0D);
  bool _isInitialized = false;
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
  final web3InteractManager = Web3InteractionManager();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _amountUsdController = TextEditingController();

  @override
  void initState() {
    super.initState();
    getSavedWallets();
  }

  @override
  void dispose() {
    _addressController.dispose();
    _amountController.dispose();
    _amountUsdController.dispose();
    super.dispose();
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
      getInitialData();
    } catch (e) {
      logError('Error getting saved wallets: $e');
    }
  }

  Future<void> getInitialData() async {
    try {
      final price = await priceManager
          .getPriceUsingBinanceApi(currentNetwork.binanceSymbol);
      final balance = await web3InteractManager.getBalance(
          currentAccount.address, currentNetwork.rpc);
      setState(() {
        cryptoPrice = price;
        userBalance = balance;
      });
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
    return Scaffold(
      backgroundColor: primaryColor,
      appBar: AppBar(
        surfaceTintColor: primaryColor,
        backgroundColor: primaryColor,
        leading: IconButton(
            onPressed: () {
              Navigator.pop(context);
            },
            icon: Icon(
              Icons.arrow_back,
              color: textColor,
            )),
        title: Text(
          'Send',
          style: GoogleFonts.roboto(color: textColor),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Column(
            spacing: 20,
            children: [
              Row(
                spacing: 10,
                children: [
                  InkWell(
                    borderRadius: BorderRadius.circular(15),
                    onTap: () {
                      vibrate();
                      Clipboard.setData(
                          ClipboardData(text: currentAccount.address));
                    },
                    child: Container(
                      width: width * 0.53,
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: surfaceTintColor.withOpacity(0.4),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Row(
                        spacing: 10,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(50),
                            child: Image.asset(
                              currentNetwork.icon,
                              width: 20,
                              height: 20,
                              fit: BoxFit.cover,
                            ),
                          ),
                          Text(
                            currentAccount.address.isNotEmpty
                                ? "${currentAccount.address.substring(0, 6)}...${currentAccount.address.substring(currentAccount.address.length - 6, currentAccount.address.length)}"
                                : "No Account",
                            style: GoogleFonts.roboto(color: textColor),
                          )
                        ],
                      ),
                    ),
                  ),
                  Container(
                      width: width * 0.35,
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: surfaceTintColor.withOpacity(0.4),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Center(
                        child: Text(
                          currentAccount.walletName,
                          style: GoogleFonts.roboto(color: textColor),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ))
                ],
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: surfaceTintColor.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Row(
                  spacing: 10,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.asset(
                        currentNetwork.icon,
                        width: 40,
                        height: 40,
                        fit: BoxFit.cover,
                      ),
                    ),
                    Column(
                      spacing: 10,
                      children: [
                        Text(
                          currentNetwork.name,
                          style: GoogleFonts.roboto(
                              color: textColor, fontWeight: FontWeight.bold),
                        )
                      ],
                    )
                  ],
                ),
              ),
              Row(
                children: [
                  Text(
                    "To",
                    style: GoogleFonts.roboto(color: textColor),
                  ),
                  Spacer(),
                  Row(
                    spacing: 5,
                    children: [
                      IconButton(
                          onPressed: () {},
                          icon: Icon(Icons.contact_page_outlined)),
                      IconButton(onPressed: () {}, icon: Icon(LucideIcons.scan))
                    ],
                  )
                ],
              ),
              Form(
                key: _formKey,
                child: TextFormField(
                  validator: (value) {
                    if (value != null) {
                      if (value.length == 42 &&
                          value.toLowerCase().startsWith("0x")) {
                        return null;
                      } else {
                        return "Invalid Address";
                      }
                    } else {
                      return "Address is required";
                    }
                  },
                  onChanged: (value) {
                    setState(() {
                      filteredAccounts = accounts
                          .where((account) => account.address
                              .toLowerCase()
                              .contains(value.toLowerCase()))
                          .toList();
                    });
                  },
                  controller: _addressController,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    filled: true,
                    fillColor: surfaceTintColor.withOpacity(0.4),
                    labelText: "Enter Address",
                    suffixIcon: IconButton(
                      onPressed: () async {
                        final data = await Clipboard.getData("text/plain");
                        final address = data?.text ?? "";
                        setState(() {
                          _addressController.text = address;
                        });
                      },
                      icon: Icon(
                        FeatherIcons.clipboard,
                        color: textColor,
                      ),
                    ),
                    labelStyle: GoogleFonts.roboto(color: textColor),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(5),
                      borderSide: BorderSide(color: secondaryColor),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(5),
                      borderSide: BorderSide(color: Colors.transparent),
                    ),
                  ),
                ),
              ),
              Align(
                alignment: Alignment.topLeft,
                child: Text(
                  "Amount",
                  style: GoogleFonts.roboto(
                      color: textColor, fontWeight: FontWeight.bold),
                ),
              ),
              TextField(
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  setState(() {
                    filteredAccounts = accounts
                        .where((account) => account.address
                            .toLowerCase()
                            .contains(value.toLowerCase()))
                        .toList();
                  });
                },
                controller: _amountController,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  filled: true,
                  fillColor: surfaceTintColor.withOpacity(0.4),
                  labelText: "Amount ${currentNetwork.name}",
                  suffixIcon: Container(
                    margin: const EdgeInsets.all(5),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: () {
                        _amountController.text = (userBalance).toString();
                        _amountUsdController.text =
                            ((userBalance) * cryptoPrice).toString();
                      },
                      child: Container(
                        width: 50,
                        height: 5,
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                                width: 1, color: textColor.withOpacity(0.3))),
                        child: Center(
                          child: Text(
                            "Max",
                            style: GoogleFonts.roboto(color: textColor),
                          ),
                        ),
                      ),
                    ),
                  ),
                  labelStyle:
                      GoogleFonts.roboto(color: textColor.withOpacity(0.3)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(5),
                    borderSide: BorderSide(color: secondaryColor),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(5),
                    borderSide: BorderSide(color: Colors.transparent),
                  ),
                ),
              ),
              TextField(
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  setState(() {
                    filteredAccounts = accounts
                        .where((account) => account.address
                            .toLowerCase()
                            .contains(value.toLowerCase()))
                        .toList();
                  });
                },
                controller: _amountUsdController,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  filled: true,
                  fillColor: surfaceTintColor.withOpacity(0.4),
                  labelText: "Amount USD",
                  suffixIcon: SizedBox(
                    width: 35,
                    child: Center(
                      child: Text(
                        "USD",
                        style:
                            GoogleFonts.roboto(color: textColor, fontSize: 15),
                      ),
                    ),
                  ),
                  alignLabelWithHint: false,
                  labelStyle:
                      GoogleFonts.roboto(color: textColor.withOpacity(0.3)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(5),
                    borderSide: BorderSide(color: secondaryColor),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(5),
                    borderSide: BorderSide(color: Colors.transparent),
                  ),
                ),
              ),
              Align(
                alignment: Alignment.topLeft,
                child: Text(
                  "Balance : $userBalance ${currentNetwork.name}",
                  style: GoogleFonts.roboto(color: textColor.withOpacity(0.7)),
                ),
              ),
              ConstrainedBox(
                constraints: BoxConstraints(minWidth: width * 0.95),
                child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: _amountController.text.isEmpty
                            ? textColor.withOpacity(0.2)
                            : textColor),
                    onPressed: () {
                      if (_amountController.text.isEmpty) return;

                      if (_formKey.currentState!.validate()) {
                        log("Validation success !");
                      }
                    },
                    child: Text(
                      "Next",
                      style: GoogleFonts.roboto(color: primaryColor),
                    )),
              )
            ],
          ),
        ),
      ),
    );
  }
}
