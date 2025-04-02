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
import 'package:moonwallet/service/crypto_storage_manager.dart';
import 'package:moonwallet/service/number_formatter.dart';
import 'package:moonwallet/service/price_manager.dart';
import 'package:moonwallet/service/token_manager.dart';
import 'package:moonwallet/service/vibration.dart';
import 'package:moonwallet/service/wallet_saver.dart';
import 'package:moonwallet/service/web3_interaction.dart';
import 'package:moonwallet/types/types.dart';
import 'package:moonwallet/utils/colors.dart';
import 'package:moonwallet/utils/crypto.dart';
import 'package:moonwallet/utils/prefs.dart';
import 'package:moonwallet/utils/themes.dart';
import 'package:moonwallet/widgets/crypto_picture.dart';
import 'package:moonwallet/widgets/func/show_select_account.dart';
import 'package:moonwallet/widgets/func/show_select_last_addr.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:qr_code_scanner_plus/qr_code_scanner_plus.dart';

class SendTransactionScreen extends StatefulWidget {
  final AppColors? colors;
  const SendTransactionScreen({super.key, this.colors});

  @override
  State<SendTransactionScreen> createState() => _SendTransactionScreenState();
}

class _SendTransactionScreenState extends State<SendTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  QRViewController? controller;
  final formatter = NumberFormat("0.##############", "en_US");
  final MobileScannerController _mobileScannerController =
      MobileScannerController();

  double userBalance = 0;
  double cryptoPrice = 0;
  double transactionFee = 0;
  double nativeTokenBalance = 0;
  bool isAndroid = false;
  double networkBalance = 0;
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
  Crypto currentNetwork = Crypto(
      name: "",
      color: Colors.transparent,
      type: CryptoType.network,
      valueUsd: 0,
      cryptoId: "",
      canDisplay: false,
      symbol: "");
  final web3InteractManager = Web3InteractionManager();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _amountUsdController = TextEditingController();
  final cryptoStorageManager = CryptoStorageManager();
  final tokenManager = TokenManager();
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
    super.initState();
    if (widget.colors != null) {
      setState(() {
        colors = widget.colors!;
      });
    }
    getSavedTheme();
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

  void showLoader() {
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return Center(
            child: Container(
              padding: const EdgeInsets.all(30),
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: colors.primaryColor,
              ),
              child: SizedBox(
                width: 65,
                height: 65,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: colors.themeColor,
                ),
              ),
            ),
          );
        });
  }

  Future<void> askCamera() async {
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
      if (userBalance <= double.parse(_amountController.text)) {
        throw Exception("Insufficient balance");
      }

      showLoader();
      final to = _addressController.text;
      final from = currentAccount.address;

      final valueWei =
          (BigInt.from(double.parse(_amountController.text) * 1e8) *
                  BigInt.from(10).pow(18)) ~/
              BigInt.from(100000000);
      final valueHex = valueWei.toRadixString(16);
      log("Value : $valueHex and value wei $valueWei");

      final estimatedGas = await web3InteractManager.estimateGas(
          rpcUrl:
              currentNetwork.rpc ?? "https://opbnb-mainnet-rpc.bnbchain.org",
          sender: currentAccount.address,
          to: _addressController.text,
          value: valueHex,
          data: "");
      log("Gas : ${estimatedGas.toString()}");
      if (estimatedGas == null) {
        throw Exception("Gas estimation error");
      }

      final transaction = JsTransactionObject(
        gas: "0x${(estimatedGas).toRadixString(16)}",
        value: valueHex,
        from: from,
        to: to,
      );
      if (mounted) {
        Navigator.pop(context);
        final tx = await web3InteractManager.sendEthTransaction(
            crypto: currentNetwork,
            colors: colors,
            data: transaction,
            mounted: mounted,
            context: context,
            currentAccount: currentAccount,
            currentNetwork: currentNetwork,
            primaryColor: colors.primaryColor,
            textColor: colors.textColor,
            secondaryColor: colors.themeColor,
            actionsColor: colors.grayColor,
            operationType: 1);
        saveLastUsedAddresses(address: to);

        if (tx.isNotEmpty) {
          log("Transaction tx : $tx");
          if (mounted) {
            Navigator.pushNamed(context, Routes.pageManager);
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

  Future<void> sendTokenTransaction() async {
    try {
      double amount = double.parse(_amountController.text);
      double roundedAmount = double.parse(amount.toStringAsFixed(8));

      if (roundedAmount > userBalance) {
        throw Exception("Insufficient balance");
      }
      if (nativeTokenBalance < transactionFee) {
        throw Exception(
            "Insufficient ${currentNetwork.network?.symbol} balance , add ${(transactionFee - nativeTokenBalance).toStringAsFixed(8)}");
      }

      showLoader();

      final to = _addressController.text;
      final from = currentAccount.address;

      // final gasPrice = await web3InteractManager.getGasPrice(
      //  currentNetwork.network?.rpc ?? "https://opbnb-mainnet-rpc.bnbchain.org");

      final value = (BigInt.from((roundedAmount * 1e8).round()) *
          BigInt.from(10).pow(18) ~/
          BigInt.from(100000000));
      log("Value before parsing $value");
      final valueWei = value;
      log("valueWei $valueWei");

      final valueHex = (valueWei).toRadixString(16);

      final estimatedGas = await web3InteractManager.estimateGas(
          rpcUrl: currentNetwork.network?.rpc ??
              "https://opbnb-mainnet-rpc.bnbchain.org",
          sender: currentAccount.address,
          to: _addressController.text,
          value: "0x0",
          data: "");

      log("Gas : ${estimatedGas.toString()}");

      //  final gas = (estimatedGas * gasPrice * numerator) ~/ denominator;
      if (estimatedGas == null) {
        throw Exception("Gas estimation error");
      }
      final transaction = JsTransactionObject(
        gas: "0x${((estimatedGas * BigInt.from(2))).toRadixString(16)}",
        value: valueHex,
        from: from,
        to: to,
      );
      if (mounted) {
        Navigator.pop(context);

        final tx = await tokenManager.transferToken(
            colors: colors,
            data: transaction,
            mounted: mounted,
            context: context,
            currentAccount: currentAccount,
            currentNetwork: currentNetwork,
            primaryColor: colors.primaryColor,
            textColor: colors.textColor,
            secondaryColor: colors.themeColor,
            actionsColor: colors.grayColor,
            operationType: 1);

        saveLastUsedAddresses(address: to);

        if (tx != null && tx.isNotEmpty) {
          log("Transaction tx : $tx");
          if (mounted) {
            Navigator.pushNamed(context, Routes.pageManager);
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
      final results = await Future.wait([
        //1
        web3InteractManager.estimateGas(
            rpcUrl: currentNetwork.type == CryptoType.token
                ? currentNetwork.network?.rpc ?? ""
                : currentNetwork.rpc ?? "",
            sender: currentAccount.address,
            to: currentAccount.address,
            value: "0x0",
            data: ""),
        //2
        priceManager
            .getPriceUsingBinanceApi(currentNetwork.binanceSymbol ?? ""),
        // 3
        web3InteractManager.getBalance(currentAccount, currentNetwork),
        // 4
        currentNetwork.type == CryptoType.token
            ? web3InteractManager.getGasPrice(currentNetwork.network?.rpc ??
                "https://opbnb-mainnet-rpc.bnbchain.org")
            : web3InteractManager.getGasPrice(
                currentNetwork.rpc ?? "https://opbnb-mainnet-rpc.bnbchain.org"),
        // 5
        publicDataManager.getDataFromPrefs(
            key: "${currentAccount.address}/lastUsedAddresses")
      ]);
      final estimatedGas = (results[0] as BigInt?);
      log("estimated gas $estimatedGas");
      final price = results[1];
      final balance = results[2];

      BigInt gasPrice = (results[3] as BigInt?) ?? BigInt.from(1000000);

      log("gas $gasPrice");

      final lastUsedAddresses = results[4];
      log("last address $lastUsedAddresses");
      if (lastUsedAddresses != null) {
        setState(() {
          lastEthUsedAddresses = json.decode((lastUsedAddresses as String));
        });
      }

      setState(() {
        cryptoPrice = (price as double);
        userBalance = (balance as double);
        final BigInt gas = estimatedGas != null
            ? (estimatedGas * BigInt.from(2))
            : BigInt.from(21000);
        final double gasPriceDouble = gasPrice.toDouble();

        transactionFee = ((gas * BigInt.from(gasPriceDouble.toInt())) /
            BigInt.from(10).pow(18));
        log("Fees ${transactionFee.toStringAsFixed(8)}");
      });
      if (currentNetwork.type == CryptoType.token) {
        final networkBalance = await web3InteractManager.getBalance(
            currentAccount, currentNetwork.network ?? currentNetwork);
        setState(() {
          nativeTokenBalance = networkBalance;
        });
      }

      log("Crypto price is $price");
    } catch (e) {
      logError(e.toString());
    }
  }

  @override
  void didChangeDependencies() async {
    super.didChangeDependencies();
    if (!_isInitialized) {
      final data = ModalRoute.of(context)?.settings.arguments;
      if (data != null && (data as Map<String, dynamic>)["id"] != null) {
        final id = data["id"];
        await getSavedWallets();
        final savedCrypto =
            await cryptoStorageManager.getSavedCryptos(wallet: currentAccount);
        if (savedCrypto != null) {
          for (final crypto in savedCrypto) {
            if (crypto.cryptoId == id) {
              setState(() {
                currentNetwork = crypto;
              });
            }
          }
          await getInitialData();
        }

        log("Network sets to ${currentNetwork.binanceSymbol}");
      }
      _isInitialized = true;
    }
  }

  String formatUsd(String value) {
    return NumberFormatter().formatUsd(value: value);
  }

  String formatCryptoValue(String value) {
    return NumberFormatter().formatCrypto(value: value);
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: colors.primaryColor,
      appBar: AppBar(
        surfaceTintColor: colors.primaryColor,
        backgroundColor: colors.primaryColor,
        leading: IconButton(
            onPressed: () {
              Navigator.pop(context);
            },
            icon: Icon(
              Icons.arrow_back,
              color: colors.textColor,
            )),
        title: Text(
          'Send',
          style: GoogleFonts.roboto(color: colors.textColor),
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
                        color: colors.secondaryColor,
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        spacing: 10,
                        children: [
                          CryptoPicture(
                            crypto: currentNetwork,
                            size: 20,
                            colors: colors,
                            primaryColor: colors.secondaryColor,
                          ),
                          Text(
                            currentAccount.address.isNotEmpty
                                ? "${currentAccount.address.substring(0, 6)}...${currentAccount.address.substring(currentAccount.address.length - 6, currentAccount.address.length)}"
                                : "No Account",
                            style: GoogleFonts.roboto(color: colors.textColor),
                          )
                        ],
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: () async {
                      selectAnAccount(
                          colors: colors,
                          context: context,
                          accounts: accounts.toSet().toList(),
                          onTap: (wl) async {
                            setState(() {
                              currentAccount = wl;
                            });
                            await getInitialData();
                          });
                    },
                    child: Container(
                        width: width * 0.35,
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: colors.secondaryColor,
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Center(
                          child: Text(
                            currentAccount.walletName,
                            style: GoogleFonts.roboto(color: colors.textColor),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        )),
                  )
                ],
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colors.secondaryColor,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Row(
                  spacing: 10,
                  children: [
                    CryptoPicture(
                      crypto: currentNetwork,
                      size: 30,
                      colors: colors,
                      primaryColor: colors.secondaryColor,
                    ),
                    Column(
                      spacing: 10,
                      children: [
                        Text(
                          currentNetwork.symbol,
                          style: GoogleFonts.roboto(
                              color: colors.textColor,
                              fontWeight: FontWeight.bold),
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
                    style: GoogleFonts.roboto(color: colors.textColor),
                  ),
                  Spacer(),
                  Row(
                    spacing: 5,
                    children: [
                      IconButton(
                          onPressed: () {
                            showSelectLastAddr(
                                context: context,
                                publicDataManager: publicDataManager,
                                currentAccount: currentAccount,
                                colors: colors,
                                addressController: _addressController,
                                currentNetwork: currentNetwork);
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
                                        final String code = barcode.barcodes
                                                .firstOrNull!.displayValue ??
                                            "";
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
                  style: GoogleFonts.roboto(
                      color: colors.textColor.withOpacity(0.8)),
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
                    fillColor: colors.grayColor.withOpacity(0.4),
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
                        color: colors.textColor,
                      ),
                    ),
                    labelStyle: GoogleFonts.roboto(color: colors.textColor),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(5),
                      borderSide: BorderSide(color: colors.themeColor),
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
                      color: colors.textColor, fontWeight: FontWeight.bold),
                ),
              ),
              TextFormField(
                style: GoogleFonts.roboto(
                    color: colors.textColor.withOpacity(0.8)),
                validator: (v) {
                  log("Value $v");
                  if (double.parse(v ?? "") >= userBalance) {
                    return "Amount exceeds balance";
                  } else if (double.parse(v ?? "") == userBalance &&
                      userBalance > 0) {
                    return "Transaction fee must be deducted";
                  } else {
                    return null;
                  }
                },
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
                  fillColor: colors.grayColor.withOpacity(0.4),
                  labelText: "Amount ${currentNetwork.symbol}",
                  suffixIcon: Container(
                    margin: const EdgeInsets.all(5),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: () {
                        setState(() {
                          if (currentNetwork.type == CryptoType.network) {
                            final value = userBalance - transactionFee;
                            log("value $value , balance $userBalance");
                            _amountController.text = formatter.format(value);
                            _amountUsdController.text =
                                ((userBalance) * cryptoPrice).toString();
                          } else {
                            _amountController.text =
                                formatter.format(userBalance);
                            _amountUsdController.text =
                                ((userBalance) * cryptoPrice).toString();
                          }
                        });
                      },
                      child: Container(
                        width: 50,
                        height: 5,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Center(
                          child: Text(
                            "Max",
                            style: GoogleFonts.roboto(color: colors.textColor),
                          ),
                        ),
                      ),
                    ),
                  ),
                  labelStyle: GoogleFonts.roboto(
                      color: colors.textColor.withOpacity(0.3)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(5),
                    borderSide: BorderSide(color: colors.themeColor),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(5),
                    borderSide: BorderSide(color: Colors.transparent),
                  ),
                ),
              ),
              TextField(
                style: GoogleFonts.roboto(
                    color: colors.textColor.withOpacity(0.8)),
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
                  fillColor: colors.grayColor.withOpacity(0.4),
                  labelText: "Amount USD",
                  suffixIcon: SizedBox(
                    width: 35,
                    child: Center(
                      child: Text(
                        "USD",
                        style: GoogleFonts.roboto(
                            color: colors.textColor, fontSize: 15),
                      ),
                    ),
                  ),
                  alignLabelWithHint: false,
                  labelStyle: GoogleFonts.roboto(
                      color: colors.textColor.withOpacity(0.3)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(5),
                    borderSide: BorderSide(color: colors.themeColor),
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
                  "Balance : ${formatCryptoValue(userBalance.toString())} ${currentNetwork.symbol}",
                  style: GoogleFonts.roboto(
                      color: colors.textColor.withOpacity(0.7)),
                ),
              ),
              ConstrainedBox(
                constraints: BoxConstraints(minWidth: width * 0.95),
                child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: _amountController.text.isEmpty
                            ? colors.textColor.withOpacity(0.2)
                            : colors.textColor),
                    onPressed: () async {
                      if (_amountController.text.isEmpty) return;

                      if (_formKey.currentState!.validate()) {
                        log("Validation success !");
                        if (currentNetwork.type == CryptoType.network) {
                          await sendTransaction();
                        } else {
                          await sendTokenTransaction();
                        }
                      }
                    },
                    child: Text(
                      "Next",
                      style: GoogleFonts.roboto(color: colors.primaryColor),
                    )),
              )
            ],
          ),
        ),
      ),
    );
  }
}
