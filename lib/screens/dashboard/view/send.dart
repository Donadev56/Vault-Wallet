// ignore_for_file: deprecated_member_use

import 'dart:convert';
import 'dart:io';
import 'dart:ui';
import 'package:awesome_snackbar_content/awesome_snackbar_content.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:flutter_web3_webview/flutter_web3_webview.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:moonwallet/logger/logger.dart';
import 'package:moonwallet/main.dart';
import 'package:moonwallet/service/price_manager.dart';
import 'package:moonwallet/service/vibration.dart';
import 'package:moonwallet/service/wallet_saver.dart';
import 'package:moonwallet/service/web3_interaction.dart';
import 'package:moonwallet/types/types.dart';
import 'package:moonwallet/utils/constant.dart';
import 'package:moonwallet/utils/crypto.dart';
import 'package:moonwallet/utils/prefs.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:qr_code_scanner_plus/qr_code_scanner_plus.dart';

class SendTransactionScreen extends StatefulWidget {
  const SendTransactionScreen({super.key});

  @override
  State<SendTransactionScreen> createState() => _SendTransactionScreenState();
}

class _SendTransactionScreenState extends State<SendTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  QRViewController? controller;
  final formatter = NumberFormat("0.##############", "en_US");
  final MobileScannerController _mobileScannerController = MobileScannerController();

  Color primaryColor = Color(0XFF1B1B1B);
  Color textColor = Color.fromARGB(255, 255, 255, 255);
  Color secondaryColor = Colors.greenAccent;
  Color actionsColor = Color(0XFF353535);
  Color surfaceTintColor = Color(0XFF454545);
  double userBalance = 0;
  double cryptoPrice = 0;
  double transactionFee = 0;
  bool isAndroid = false;
  bool isDarkMode = false;
  Color darkNavigatorColor = Color(0XFF0D0D0D);
  bool _isInitialized = false;
  List<PublicData> accounts = [];
  List<PublicData> filteredAccounts = [];
  List<dynamic> lastEthUsedAddresses = [];
  List<String> lastAddresses = [];
  PublicData currentAccount = PublicData(
      keyId: "",
      creationDate: 0,
      walletName: "",
      address: "",
      isWatchOnly: false);
  final web3Manager = WalletSaver();
  final encryptService = EncryptService();
  final priceManager = PriceManager();
  final publicDataManager = PublicDataManager();
  Crypto currentNetwork = networks[0];
  final web3InteractManager = Web3InteractionManager();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _amountUsdController = TextEditingController();

  @override
  void initState() {
    super.initState();
    getSavedWallets();
    getThemeMode();
    askCamera();
  }

  @override
  void reassemble() {
    super.reassemble();
    if (Platform.isAndroid) {
      controller!.pauseCamera();
    } else if (Platform.isIOS) {
      controller!.resumeCamera();
    }
  }

  @override
  void dispose() {
    _addressController.dispose();
    _amountController.dispose();
    _amountUsdController.dispose();
    super.dispose();
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
 Future<void> askCamera () async {
  try {

      final status = await Permission.camera.status;

      if (!status.isGranted) {
    await Permission.camera.request();
  }

  } catch (e) {
    logError(e.toString());
    
  }
 }


  Future<void> sendTransaction() async {
    try {
      showDialog(
          context: context,
          builder: (BuildContext context) {
            return Center(
              child: Container(
                padding: const EdgeInsets.all(30),
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: secondaryColor, width: 0.5),
                  color: primaryColor,
                ),
                child: SizedBox(
                  width: 50,
                  height: 50,
                  child: CircularProgressIndicator(
                    color: textColor,
                  ),
                ),
              ),
            );
          });
      BigInt numerator = BigInt.from(100); // pour 1.2, 12/10
      BigInt denominator = BigInt.from(10);

      final to = _addressController.text;
      final from = currentAccount.address;
      final gasPrice =
          await web3InteractManager.getGasPrice(currentNetwork.rpc ?? "https://opbnb-mainnet-rpc.bnbchain.org");
      final valueWei =
          ((double.parse(_amountController.text)) * 1e18).toStringAsFixed(0);
      final valueHex = (int.parse(valueWei)).toRadixString(16);
      log("Value : $valueHex and value wei $valueWei");
      final estimatedGas = await web3InteractManager.estimateGas(
          rpcUrl: currentNetwork.rpc ?? "https://opbnb-mainnet-rpc.bnbchain.org",
          sender: currentAccount.address,
          to: _addressController.text,
          value: valueHex,
          data: "");
      log("Gas : ${estimatedGas.toString()}");

      final gas = (estimatedGas * gasPrice * numerator) ~/ denominator;
      final valueToSend = BigInt.parse(valueWei) - gas;
      log("Value to send ${valueToSend.toString()} and gas $gas \n Value wei $valueWei and ${BigInt.parse(valueWei) - valueToSend}");
      final transaction = JsTransactionObject(
        gas: "0x${(estimatedGas.toInt()).toRadixString(16)}",
        value: "0x${(valueToSend.toInt()).toRadixString(16)}",
        from: from,
        to: to,
      );
      if (mounted) {
        Navigator.pop(context);
        final tx = await web3InteractManager.sendEthTransaction(
            data: transaction,
            mounted: mounted,
            context: context,
            currentAccount: currentAccount,
            currentNetwork: currentNetwork,
            primaryColor: primaryColor,
            textColor: textColor,
            secondaryColor: secondaryColor,
            actionsColor: actionsColor,
            operationType: 1);
        saveLastUsedAddresses(address: to);

        if (tx.isNotEmpty) {
          log("Transaction tx : $tx");
          if (mounted) {
            Navigator.pushNamed(context, Routes.main);
          }
        } else {
          log("Transaction failed");
          final snackBar = SnackBar(
            /// need to set following properties for best effect of awesome_snackbar_content
            elevation: 0,
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.transparent,
            content: AwesomeSnackbarContent(
              title: 'Ho Ho!',
              message: 'Transaction failed!',

              /// change contentType to ContentType.success, ContentType.warning or ContentType.help for variants
              contentType: ContentType.failure,
            ),
          );

          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(snackBar);
        }
      }
    } catch (e) {
      logError(e.toString());
      final snackBar = SnackBar(
        /// need to set following properties for best effect of awesome_snackbar_content
        elevation: 0,
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.transparent,
        content: AwesomeSnackbarContent(
          title: 'Ho Ho!',
          message: '${e.toString()}!',

          /// change contentType to ContentType.success, ContentType.warning or ContentType.help for variants
          contentType: ContentType.failure,
        ),
      );

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(snackBar);
    }
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

  Future<void> saveLastUsedAddresses({required String address}) async {
    try {
      final lastUsedAddresses = await publicDataManager.getDataFromPrefs(
          key: "${currentAccount.address}/lastUsedAddresses");
      log("last address $lastUsedAddresses");
      if (lastUsedAddresses == null) {
        List<String> lastAddr = [address];
        await publicDataManager.saveDataInPrefs(
            data: json.encode(lastAddr),
            key: "${currentAccount.address}/lastUsedAddresses");
      } else {
        int index = 0;
        List<dynamic> addresses = json.decode(lastUsedAddresses);
        for (String addr in addresses) {
          if (addr.toLowerCase().trim() == address.toLowerCase().trim()) {
            final element = addresses.removeAt(index);
            addresses.insert(0, element);
            await publicDataManager.saveDataInPrefs(
                data: json.encode(addresses),
                key: "${currentAccount.address}/lastUsedAddresses");
          }
          index++;
        }

        List<dynamic> newList = [...json.decode(lastUsedAddresses)];
        newList.insert(0, address);
        await publicDataManager.saveDataInPrefs(
            data: json.encode(newList),
            key: "${currentAccount.address}/lastUsedAddresses");
      }
    } catch (e) {
      logError(e.toString());
    }
  }

  Future<void> getInitialData() async {
    try {
      final lastBalance = await publicDataManager.getDataFromPrefs(
          key: "${currentAccount.address}/lastBalanceEth");
      if (lastBalance != null) {
        setState(() {
          userBalance = double.parse(lastBalance);
        });
      }
      final price = await priceManager
          .getPriceUsingBinanceApi(currentNetwork.binanceSymbol ?? "");
      final balance = await web3InteractManager.getBalance(
          currentAccount.address, currentNetwork.rpc ?? "https://opbnb-mainnet-rpc.bnbchain.org");
      final gasPrice =
          await web3InteractManager.getGasPrice(currentNetwork.rpc ?? "https://opbnb-mainnet-rpc.bnbchain.org");
      final lastUsedAddresses = await publicDataManager.getDataFromPrefs(
          key: "${currentAccount.address}/lastUsedAddresses");
      log("last address $lastUsedAddresses");
      if (lastUsedAddresses != null) {
        setState(() {
          lastEthUsedAddresses = json.decode(lastUsedAddresses);
        });
      }

      setState(() {
        cryptoPrice = price;
        userBalance = balance;
        transactionFee = ((21000 * gasPrice.toDouble()) / 1e18);
        log("Fees $transactionFee");
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
                          onPressed: () {
                            showModalBottomSheet(
                                context: context,
                                builder: (BuildContext btmCtx) {
                                  return StatefulBuilder(builder:
                                      (BuildContext stateFCtx, setModalState) {
                                    Future<List<dynamic>> getAddress() async {
                                      try {
                                        final lastUsedAddresses =
                                            await publicDataManager
                                                .getDataFromPrefs(
                                                    key:
                                                        "${currentAccount.address}/lastUsedAddresses");
                                        log("last address $lastUsedAddresses");
                                        if (lastUsedAddresses != null) {
                                          return json.decode(lastUsedAddresses);
                                        } else {
                                          return [];
                                        }
                                      } catch (e) {
                                        logError(e.toString());
                                        return [];
                                      }
                                    }

                                    return BackdropFilter(
                                      filter: ImageFilter.blur(
                                          sigmaX: 10, sigmaY: 10),
                                      child: Container(
                                          color: primaryColor,
                                          child: Column(
                                            children: [
                                              Align(
                                                alignment: Alignment.topLeft,
                                                child: Container(
                                                  padding:
                                                      const EdgeInsets.all(15),
                                                  child: Text(
                                                    "Last Addresses :",
                                                    style: GoogleFonts.roboto(
                                                        color: textColor,
                                                        fontWeight:
                                                            FontWeight.bold),
                                                  ),
                                                ),
                                              ),
                                              SingleChildScrollView(
                                                child: SizedBox(
                                                  height: MediaQuery.of(btmCtx)
                                                          .size
                                                          .height *
                                                      0.5,
                                                  child: FutureBuilder(
                                                      future: getAddress(),
                                                      builder:
                                                          (BuildContext ftrCtx,
                                                              AsyncSnapshot
                                                                  result) {
                                                        if (result.hasData) {
                                                          return ListView
                                                              .builder(
                                                                  itemCount:
                                                                      result
                                                                          .data
                                                                          .length,
                                                                  itemBuilder:
                                                                      (BuildContext
                                                                              listCtx,
                                                                          index) {
                                                                    final addr =
                                                                        result.data[
                                                                            index];
                                                                    return Material(
                                                                      color: Colors
                                                                          .transparent,
                                                                      child:
                                                                          ListTile(
                                                                        onTap:
                                                                            () {
                                                                          _addressController.text =
                                                                              addr;
                                                                          Navigator.pop(
                                                                              context);
                                                                        },
                                                                        leading:
                                                                            ClipRRect(
                                                                          borderRadius:
                                                                              BorderRadius.circular(50),
                                                                          child:
                                                                              Image.asset(
                                                                            currentNetwork.icon,
                                                                            width:
                                                                                25,
                                                                            height:
                                                                                25,
                                                                            fit:
                                                                                BoxFit.cover,
                                                                          ),
                                                                        ),
                                                                        title:
                                                                            Text(
                                                                          "${(addr as String).substring(0, 10)}...${(addr).substring(addr.length - 10, addr.length)}",
                                                                          style:
                                                                              GoogleFonts.roboto(color: textColor.withOpacity(0.7)),
                                                                        ),
                                                                        trailing: IconButton(
                                                                            onPressed: () {
                                                                              Clipboard.setData(ClipboardData(text: addr));
                                                                            },
                                                                            icon: Icon(
                                                                              LucideIcons.clipboard,
                                                                              color: textColor,
                                                                            )),
                                                                      ),
                                                                    );
                                                                  });
                                                        } else {
                                                          return Center(
                                                            child: Text(
                                                              "No addresses found",
                                                              style: GoogleFonts
                                                                  .roboto(
                                                                      color:
                                                                          textColor),
                                                            ),
                                                          );
                                                        }
                                                      }),
                                                ),
                                              )
                                            ],
                                          )),
                                    );
                                  });
                                });
                          },
                          icon: Icon(Icons.contact_page_outlined)),
                      IconButton(
                          onPressed: () {
                            showModalBottomSheet(
                                isScrollControlled: true,
                                context: context,
                                builder: (BuildContext scanCtx) {
                                  return StatefulBuilder(builder:
                                      (BuildContext stateFScanCtx,
                                          setModalState) {
                                    return MobileScanner(

                                     
                                      controller: _mobileScannerController,
                                      onDetect: (barcode) {
                                        final String code = barcode.barcodes.firstOrNull!.displayValue ??   "";
                                        log("The code $code");
                                        _addressController.text = code;
                                        Navigator.pop(stateFScanCtx);

                                      },
                                   
                                    );
                                  });
                                });
                          },
                          icon: Icon(LucideIcons.scan))
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
                  if (value.isEmpty) {
                    setState(() {
                      _amountUsdController.text = "";
                    });
                  }
                  final double cryptoAmount = double.parse(value);
                  setState(() {
                    _amountUsdController.text =
                        (cryptoAmount * cryptoPrice).toString();
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
                        setState(() {
                          _amountController.text =
                              formatter.format(userBalance - transactionFee);
                          _amountUsdController.text =
                              ((userBalance) * cryptoPrice).toString();
                        });
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
                  if (value.isEmpty) {
                    setState(() {
                      _amountController.text = "";
                    });
                  }
                  final double usdAmount = double.parse(value);
                  setState(() {
                    _amountController.text =
                        (usdAmount / cryptoPrice).toString();
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
                  "Balance : ${formatter.format(userBalance)} ${currentNetwork.name}",
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
                    onPressed: () async {
                      if (_amountController.text.isEmpty) return;

                      if (_formKey.currentState!.validate()) {
                        log("Validation success !");
                        await sendTransaction();
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
