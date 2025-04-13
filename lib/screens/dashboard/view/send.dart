// ignore_for_file: deprecated_member_use

import 'dart:convert';
import 'dart:io';
import 'package:awesome_snackbar_content/awesome_snackbar_content.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_web3_webview/flutter_web3_webview.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:moonwallet/logger/logger.dart';
import 'package:moonwallet/notifiers/providers.dart';
import 'package:moonwallet/screens/dashboard/page_manager.dart';
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
import 'package:moonwallet/widgets/scanner/show_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:qr_code_scanner_plus/qr_code_scanner_plus.dart';

class SendTransactionScreen extends ConsumerStatefulWidget {
  final WidgetInitialData initData;
  const SendTransactionScreen({super.key, required this.initData});

  @override
  ConsumerState<SendTransactionScreen> createState() =>
      _SendTransactionScreenState();
}

class _SendTransactionScreenState extends ConsumerState<SendTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  QRViewController? controller;
  final formatter = NumberFormat("0.##############", "en_US");
  final MobileScannerController _mobileScannerController =
      MobileScannerController();

  double nativeBalance = 0;
  double cryptoPrice = 0;
  double transactionFee = 0;
  double tokenBalance = 0;
  bool isAndroid = false;
  double networkBalance = 0;
  bool isDarkMode = false;
  Color darkNavigatorColor = Color(0XFF0D0D0D);
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

  Crypto crypto = Crypto(
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
  AppColors colors = AppColors.defaultTheme;
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

  Future<void> init() async {
    setState(() {
      currentAccount = widget.initData.account;
      crypto = widget.initData.crypto;
      colors = widget.initData.colors;
      if (widget.initData.initialBalanceCrypto != null) {
        if (crypto.type == CryptoType.token) {
          tokenBalance = widget.initData.initialBalanceCrypto ?? 0;
        } else {
          nativeBalance = widget.initData.initialBalanceCrypto ?? 0;
        }
      }
    });

    getInitialData();
  }

  @override
  void initState() {
    super.initState();
    init();
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
      if (nativeBalance <= double.parse(_amountController.text)) {
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
          rpcUrl: crypto.rpc ?? "https://opbnb-mainnet-rpc.bnbchain.org",
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
            crypto: crypto,
            colors: colors,
            data: transaction,
            mounted: mounted,
            context: context,
            currentAccount: currentAccount,
            currentNetwork: crypto,
            primaryColor: colors.primaryColor,
            textColor: colors.textColor,
            secondaryColor: colors.themeColor,
            actionsColor: colors.grayColor,
            operationType: 1);

        saveLastUsedAddresses(address: to);

        if (tx.isNotEmpty) {
          log("Transaction tx : $tx");
          if (mounted) {
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => PagesManagerView(
                          colors: colors,
                          currentAccount: currentAccount,
                          crypto: crypto,
                          transaction: TransactionDetails(
                              from: from,
                              to: to,
                              value: valueWei.toString(),
                              timeStamp:
                                  (DateTime.now().millisecondsSinceEpoch / 1000)
                                      .toStringAsFixed(0),
                              hash: tx,
                              blockNumber: "..."),
                        )));
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
    }
  }

  Future<void> sendTokenTransaction() async {
    try {
      double amount = double.parse(_amountController.text);
      double roundedAmount = double.parse(amount.toStringAsFixed(8));

      if (roundedAmount > tokenBalance) {
        throw Exception("Insufficient balance");
      }
      if (nativeBalance < transactionFee) {
        throw Exception(
            "Insufficient ${crypto.network?.symbol} balance , add ${(transactionFee - nativeBalance).toStringAsFixed(8)}");
      }
      showLoader();

      final to = _addressController.text;
      final from = currentAccount.address;

      final value = (BigInt.from((roundedAmount * 1e8).round()) *
          BigInt.from(10).pow(18) ~/
          BigInt.from(100000000));
      log("Value before parsing $value");
      final valueWei = value;
      log("valueWei $valueWei");

      final valueHex = (valueWei).toRadixString(16);

      final estimatedGas = await web3InteractManager.estimateGas(
          rpcUrl:
              crypto.network?.rpc ?? "https://opbnb-mainnet-rpc.bnbchain.org",
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
            currentNetwork: crypto,
            primaryColor: colors.primaryColor,
            textColor: colors.textColor,
            secondaryColor: colors.themeColor,
            actionsColor: colors.grayColor,
            operationType: 1);

        saveLastUsedAddresses(address: to);

        if (tx != null && tx.isNotEmpty) {
          log("Transaction tx : $tx");
          if (mounted) {
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => PagesManagerView(
                          colors: colors,
                          currentAccount: currentAccount,
                          crypto: crypto,
                          transaction: TransactionDetails(
                              from: from,
                              to: to,
                              value: value.toString(),
                              timeStamp:
                                  (DateTime.now().millisecondsSinceEpoch / 1000)
                                      .toStringAsFixed(0),
                              hash: tx,
                              blockNumber: "..."),
                        )));
          }
        } else {
          log("Transaction failed");
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
            rpcUrl: crypto.type == CryptoType.token
                ? crypto.network?.rpc ?? ""
                : crypto.rpc ?? "",
            sender: currentAccount.address,
            to: currentAccount.address,
            value: "0x0",
            data: ""),
        //2
        priceManager.getPriceUsingBinanceApi(crypto.binanceSymbol ?? ""),
        // 3
        web3InteractManager.getBalance(currentAccount, crypto),
        // 4
        crypto.type == CryptoType.token
            ? web3InteractManager.getGasPrice(
                crypto.network?.rpc ?? "https://opbnb-mainnet-rpc.bnbchain.org")
            : web3InteractManager.getGasPrice(
                crypto.rpc ?? "https://opbnb-mainnet-rpc.bnbchain.org"),
        // 5
        publicDataManager.getDataFromPrefs(
            key: "${currentAccount.address}/lastUsedAddresses")
      ]);

      final estimatedGas = (results[0] as BigInt?);
      log("estimated gas $estimatedGas");
      final price = results[1];
      final targetTokenBalance = results[2];
      double nativeTargetTokenBalance = 0;
      if (crypto.type == CryptoType.token) {
        nativeTargetTokenBalance = await web3InteractManager.getBalance(
            currentAccount, crypto.network!);
      }

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
        if (crypto.type == CryptoType.token) {
          setState(() {
            nativeBalance = nativeTargetTokenBalance;
            tokenBalance = targetTokenBalance as double;
          });
        } else {
          nativeBalance = (targetTokenBalance as double);
        }

        final BigInt gas = estimatedGas != null
            ? (estimatedGas * BigInt.from(2))
            : BigInt.from(21000);
        final double gasPriceDouble = gasPrice.toDouble();

        transactionFee = ((gas * BigInt.from(gasPriceDouble.toInt())) /
            BigInt.from(10).pow(18));
        log("Fees ${transactionFee.toStringAsFixed(8)}");
      });

      log("Crypto price is $price");
    } catch (e) {
      logError(e.toString());
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
    final textTheme = Theme.of(context).textTheme;
    final asyncAccounts = ref.watch(accountsNotifierProvider);
    asyncAccounts.whenData((data) => setState(() {
          filteredAccounts = data;
          accounts = data;
        }));

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
          style: textTheme.headlineMedium
              ?.copyWith(color: colors.textColor, fontSize: 20),
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
                            crypto: crypto,
                            size: 20,
                            colors: colors,
                            primaryColor: colors.secondaryColor,
                          ),
                          Text(
                            currentAccount.address.isNotEmpty
                                ? "${currentAccount.address.substring(0, 6)}...${currentAccount.address.substring(currentAccount.address.length - 6, currentAccount.address.length)}"
                                : "No Account",
                            style: textTheme.bodyMedium
                                ?.copyWith(color: colors.textColor),
                          )
                        ],
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: () async {
                      selectAnAccount(
                          currentAccount: currentAccount,
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
                            style: textTheme.bodyMedium
                                ?.copyWith(color: colors.textColor),
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
                      crypto: crypto,
                      size: 30,
                      colors: colors,
                      primaryColor: colors.secondaryColor,
                    ),
                    Column(
                      spacing: 10,
                      children: [
                        Text(
                          crypto.symbol,
                          style: textTheme.bodyMedium?.copyWith(
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
                    style:
                        textTheme.bodyMedium?.copyWith(color: colors.textColor),
                  ),
                  Spacer(),
                  Row(
                    spacing: 5,
                    children: [
                      IconButton(
                          onPressed: () {
                            showSelectLastAddr(
                                accounts: accounts,
                                context: context,
                                publicDataManager: publicDataManager,
                                currentAccount: currentAccount,
                                colors: colors,
                                addressController: _addressController,
                                currentNetwork: crypto);
                          },
                          icon: Icon(Icons.contact_page_outlined)),
                      IconButton(
                          onPressed: () {
                            showScanner(
                                context: context,
                                controller: _mobileScannerController,
                                colors: colors,
                                onResult: (result) {
                                  setState(() {
                                    _addressController.text = result;
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
                  style: textTheme.bodyMedium
                      ?.copyWith(color: colors.textColor.withOpacity(0.8)),
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
                    labelStyle:
                        textTheme.bodyMedium?.copyWith(color: colors.textColor),
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
                  style: textTheme.bodyMedium?.copyWith(
                      color: colors.textColor, fontWeight: FontWeight.bold),
                ),
              ),
              TextFormField(
                style: textTheme.bodyMedium
                    ?.copyWith(color: colors.textColor.withOpacity(0.8)),
                validator: (v) {
                  log("Value $v");
                  if (double.parse(v ?? "") >= nativeBalance) {
                    return "Amount exceeds balance";
                  } else if (double.parse(v ?? "") == nativeBalance &&
                      nativeBalance > 0) {
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
                  labelText: "Amount ${crypto.symbol}",
                  suffixIcon: Container(
                    margin: const EdgeInsets.all(5),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: () {
                        setState(() {
                          if (crypto.type == CryptoType.network) {
                            final value = nativeBalance - transactionFee;
                            log("value $value , balance $nativeBalance");
                            _amountController.text = formatter.format(value);
                            _amountUsdController.text =
                                ((nativeBalance) * cryptoPrice).toString();
                          } else {
                            _amountController.text =
                                formatter.format(tokenBalance);
                            _amountUsdController.text =
                                ((tokenBalance) * cryptoPrice).toString();
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
                            style: textTheme.bodyMedium
                                ?.copyWith(color: colors.textColor),
                          ),
                        ),
                      ),
                    ),
                  ),
                  labelStyle: textTheme.bodyMedium
                      ?.copyWith(color: colors.textColor.withOpacity(0.3)),
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
                style: textTheme.bodyMedium
                    ?.copyWith(color: colors.textColor.withOpacity(0.8)),
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
                        style: textTheme.bodyMedium
                            ?.copyWith(color: colors.textColor, fontSize: 15),
                      ),
                    ),
                  ),
                  alignLabelWithHint: false,
                  labelStyle: textTheme.bodyMedium
                      ?.copyWith(color: colors.textColor.withOpacity(0.3)),
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
                  "Balance : ${formatCryptoValue(crypto.type == CryptoType.network ? nativeBalance.toString() : tokenBalance.toString())} ${crypto.symbol}",
                  style: textTheme.bodyMedium
                      ?.copyWith(color: colors.textColor.withOpacity(0.7)),
                ),
              ),
              ConstrainedBox(
                constraints: BoxConstraints(minWidth: width * 0.95),
                child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        elevation: 0,
                        backgroundColor: _amountController.text.isEmpty
                            ? colors.themeColor.withOpacity(0.2)
                            : colors.themeColor),
                    onPressed: () async {
                      if (_amountController.text.isEmpty) return;

                      if (_formKey.currentState!.validate()) {
                        log("Validation success !");
                        if (crypto.type == CryptoType.network) {
                          await sendTransaction();
                        } else {
                          await sendTokenTransaction();
                        }
                      }
                    },
                    child: Text(
                      "Next",
                      style: textTheme.bodyMedium
                          ?.copyWith(color: colors.primaryColor),
                    )),
              )
            ],
          ),
        ),
      ),
    );
  }
}
