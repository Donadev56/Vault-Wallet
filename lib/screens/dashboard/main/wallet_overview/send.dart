// ignore_for_file: deprecated_member_use

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:moonwallet/logger/logger.dart';
import 'package:moonwallet/notifiers/providers.dart';
import 'package:moonwallet/screens/dashboard/page_manager.dart';
import 'package:moonwallet/service/db/crypto_storage_manager.dart';
import 'package:moonwallet/service/web3_interactions/evm/web3_client.dart';
import 'package:moonwallet/utils/number_formatter.dart';
import 'package:moonwallet/service/external_data/price_manager.dart';
import 'package:moonwallet/service/web3_interactions/evm/token_manager.dart';
import 'package:moonwallet/service/vibration.dart';
import 'package:moonwallet/service/db/wallet_db.dart';
import 'package:moonwallet/service/web3_interactions/evm/eth_interaction_manager.dart';
import 'package:moonwallet/types/types.dart';
import 'package:moonwallet/utils/colors.dart';
import 'package:moonwallet/utils/crypto.dart';
import 'package:moonwallet/utils/prefs.dart';
import 'package:moonwallet/utils/themes.dart';
import 'package:moonwallet/widgets/app_bar_title.dart';
import 'package:moonwallet/widgets/custom_outlined_filled_textField.dart';
import 'package:moonwallet/widgets/screen_widgets/crypto_picture.dart';
import 'package:moonwallet/widgets/func/account_related/show_select_account.dart';
import 'package:moonwallet/widgets/func/account_related/show_select_last_addr.dart';
import 'package:moonwallet/widgets/func/snackbar.dart';
import 'package:moonwallet/widgets/scanner/show_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:qr_code_scanner_plus/qr_code_scanner_plus.dart';
import 'package:web3dart/web3dart.dart';

class SendTransactionScreen extends StatefulHookConsumerWidget {
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
      createdLocally: false,
      keyId: "",
      creationDate: 0,
      walletName: "",
      address: "",
      isWatchOnly: false);
  final web3Manager = WalletDatabase();
  final encryptService = EncryptService();
  final priceManager = PriceManager();
  final publicDataManager = PublicDataManager();

  Crypto? crypto;

  final ethInteractionManager = EthInteractionManager();
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
        if (crypto == null) {
          throw "No Token Found";
        }
        if (!crypto!.isNative) {
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

  notifySuccess(String message) => showCustomSnackBar(
      context: context,
      message: message,
      colors: colors,
      type: MessageType.success);
  notifyError(String message) => showCustomSnackBar(
      context: context,
      message: message,
      colors: colors,
      type: MessageType.error);

  Future<TransactionReceipt?> getReceipt(String? tx) async {
    try {
      if (crypto == null) {
        throw ("Token not found");
      }
      final web3Client = DynamicWeb3Client(
          rpcUrl: (!crypto!.isNative == true
                  ? crypto?.network?.rpcUrls?.firstOrNull
                  : crypto?.rpcUrls?.firstOrNull) ??
              "");
      final receipt = await web3Client.getReceipt(tx ?? "");
      return receipt;
    } catch (e) {
      logError(e.toString());
      return null;
    }
  }

  Future<void> sendTransaction() async {
    try {
      if (crypto == null) {
        throw "The current coin cannot be null";
      }
      final to = _addressController.text;
      final from = currentAccount.address;
      final amount = _amountController.text;
      final tx = await ethInteractionManager.buildAndSendNativeTransaction(
          BasicTransactionData(
              addressTo: to,
              amount: amount,
              account: currentAccount,
              crypto: crypto!),
          colors,
          context);

      if (tx?.isNotEmpty == true) {
        log("Transaction tx : $tx");
        if (mounted) {
          saveLastUsedAddresses(address: to);
          final receipt = await getReceipt(tx);

          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => PagesManagerView(
                        colors: colors,
                        currentAccount: currentAccount,
                        crypto: crypto,
                        transaction: TransactionDetails(
                            status: receipt?.status == null
                                ? "Pending"
                                : receipt?.status == true
                                    ? "Success"
                                    : "Failed",
                            from: from,
                            to: to,
                            value: amount.toString(),
                            timeStamp:
                                (DateTime.now().millisecondsSinceEpoch / 1000)
                                    .toStringAsFixed(0),
                            hash: tx ?? "",
                            blockNumber:
                                receipt?.blockNumber.toString() ?? "..."),
                      )));
        }
      } else {
        log("Transaction failed");
      }
    } catch (e) {
      logError(e.toString());
      notifyError(e.toString());
    }
  }

  Future<void> sendTokenTransaction() async {
    try {
      final  amount = _amountController.text;
      final to = _addressController.text;

      final tx = await ethInteractionManager.buildAndSendStandardToken(
          BasicTransactionData(
              addressTo: to,
              amount: amount,
              account: currentAccount,
              crypto: crypto!),
          colors,
          context);

      saveLastUsedAddresses(address: to);

      if (tx != null && tx.isNotEmpty) {
        log("Transaction tx : $tx");
        final receipt = await getReceipt(tx);

        if (mounted) {
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => PagesManagerView(
                        colors: colors,
                        currentAccount: currentAccount,
                        crypto: crypto,
                        transaction: TransactionDetails(
                            status: receipt?.status == null
                                ? "Pending"
                                : receipt?.status == true
                                    ? "Success"
                                    : "Failed",
                            from: currentAccount.address,
                            to: to,
                            value: amount.toString(),
                            timeStamp:
                                (DateTime.now().millisecondsSinceEpoch / 1000)
                                    .toStringAsFixed(0),
                            hash: tx,
                            blockNumber:
                                receipt?.blockNumber.toString() ?? "..."),
                      )));
        } else {
          log("Transaction failed");
        }
      }
    } catch (e) {
      logError(e.toString());
      notifyError(e.toString());
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
      if (crypto == null) {
        throw "No Coin founded";
      }
      final results = await Future.wait([
        //1
        ethInteractionManager.simulateTransaction(crypto!, currentAccount),
        //2
        priceManager.getTokenMarketData(crypto!.cgSymbol ?? ""),
        // 3
        ethInteractionManager.getBalance(currentAccount, crypto!),
        // 4
        !crypto!.isNative
            ? ethInteractionManager.getGasPrice(
                crypto!.network?.rpcUrls?.first ??
                    "https://opbnb-mainnet-rpc.bnbchain.org")
            : ethInteractionManager.getGasPrice(crypto?.rpcUrls!.first ??
                "https://opbnb-mainnet-rpc.bnbchain.org"),
        // 5
        publicDataManager.getDataFromPrefs(
            key: "${currentAccount.address}/lastUsedAddresses")
      ]);

      final estimatedGas = (results[0] as BigInt?);

      log("estimated gas $estimatedGas");
      final price = (results[1] as CryptoMarketData).currentPrice;
      final targetTokenBalance = results[2];
      double nativeTargetTokenBalance = 0;
      if (!crypto!.isNative) {
        nativeTargetTokenBalance = await ethInteractionManager.getBalance(
            currentAccount, crypto!.network!);
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
        cryptoPrice = price;
        if (!crypto!.isNative) {
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
            BigInt.from(10).pow(crypto!.decimals));
        log("Fees ${transactionFee.toStringAsFixed(8)}");
      });

      log("Crypto price is $price");
    } catch (e) {
      logError(e.toString());
    }
  }

  String formatUsd(double value) {
    return NumberFormatter().formatUsd(value: value);
  }

  String formatCryptoValue(double value) {
    return NumberFormatter().formatCrypto(value: value);
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final textTheme = Theme.of(context).textTheme;
    final asyncAccounts = ref.watch(accountsNotifierProvider);
    final appUIConfigAsync = ref.watch(appUIConfigProvider);

    final uiConfig = useState<AppUIConfig>(AppUIConfig.defaultConfig);

    useEffect(() {
      appUIConfigAsync.whenData((data) {
        uiConfig.value = data;
      });
      return null;
    }, [appUIConfigAsync]);

    double fontSizeOf(double size) {
      return size * uiConfig.value.styles.fontSizeScaleFactor;
    }

    double imageSizeOf(double size) {
      return size * uiConfig.value.styles.imageSizeScaleFactor;
    }
 double iconSizeOf(double size) {
      return size * uiConfig.value.styles.iconSizeScaleFactor;
    }
    double roundedOf(double size) {
      return size * uiConfig.value.styles.radiusScaleFactor;
    }

    if (crypto == null) {
      return Material(
        color: colors.primaryColor,
        child: Center(
          child: CircularProgressIndicator(
            color: colors.themeColor,
          ),
        ),
      );
    }
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
          title: AppBarTitle(title: "Send", colors: colors)),
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
                    borderRadius: BorderRadius.circular(roundedOf(15)),
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
                        borderRadius: BorderRadius.circular(roundedOf(15)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        spacing: 10,
                        children: [
                          CryptoPicture(
                            crypto: crypto!,
                            size: imageSizeOf(20),
                            colors: colors,
                            primaryColor: colors.secondaryColor,
                          ),
                          Text(
                            currentAccount.address.isNotEmpty
                                ? "${currentAccount.address.substring(0, 6)}...${currentAccount.address.substring(currentAccount.address.length - 6, currentAccount.address.length)}"
                                : "No Account",
                            style: textTheme.bodyMedium?.copyWith(
                                color: colors.textColor,
                                fontSize: fontSizeOf(14)),
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
                          borderRadius: BorderRadius.circular(roundedOf(15)),
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
                  borderRadius: BorderRadius.circular(roundedOf(15)),
                ),
                child: Row(
                  spacing: 10,
                  children: [
                    CryptoPicture(
                      crypto: crypto!,
                      size: imageSizeOf(30),
                      colors: colors,
                      primaryColor: colors.secondaryColor,
                    ),
                    Column(
                      spacing: 10,
                      children: [
                        Text(
                          crypto!.symbol,
                          style: textTheme.bodyMedium?.copyWith(
                              color: colors.textColor,
                              fontSize: fontSizeOf(14),
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
                                currentNetwork: crypto!);
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

                child: CustomOutlinedFilledTextFormField(
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

                     fontSizeOf: fontSizeOf,
                iconSizeOf: iconSizeOf,
                roundedOf: roundedOf,
                colors: colors,
             
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
                
                ),
              ),
              Align(
                alignment: Alignment.topLeft,
                child: Text(
                  "Amount",
                  style: textTheme.bodyMedium?.copyWith(
                      fontSize: fontSizeOf(14),
                      color: colors.textColor,
                      fontWeight: FontWeight.bold),
                ),
              ),
              CustomOutlinedFilledTextFormField(
                          labelText: "Amount ${crypto!.symbol}",


                fontSizeOf: fontSizeOf,
                iconSizeOf: iconSizeOf,
                roundedOf: roundedOf,
                validator: (v) {
                  log("Value $v");
                  if (double.parse(v ?? "0") >= nativeBalance) {
                    return "Amount exceeds balance";
                  } else if (double.parse(v ?? "0") == nativeBalance &&
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
                    _amountUsdController.text = NumberFormatter()
                        .formatDecimal((cryptoAmount * cryptoPrice).toString());
                  });
                },

                  suffixIcon: Container(
                    margin: const EdgeInsets.all(5),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(roundedOf(10)),
                      onTap: () {
                        setState(() {
                          if (crypto!.isNative) {
                            final value = nativeBalance - transactionFee;
                            log("value $value , balance $nativeBalance");
                            _amountController.text = NumberFormatter()
                                .formatDecimal(value.toStringAsFixed(8),
                                    maxDecimals: 8);
                            _amountUsdController.text =
                                ((nativeBalance) * cryptoPrice).toString();
                          } else {
                            _amountController.text = NumberFormatter()
                                .formatDecimal(tokenBalance.toStringAsFixed(8),
                                    maxDecimals: 8);
                            _amountUsdController.text =
                                ((tokenBalance) * cryptoPrice).toString();
                          }
                        });
                      },
                      child: Container(
                        width: 50,
                        height: 5,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(roundedOf(10)),
                        ),
                        child: Center(
                          child: Text(
                            "Max",
                            style: textTheme.bodyMedium?.copyWith(
                                color: colors.textColor,
                                fontSize: fontSizeOf(14)),
                          ),
                        ),
                      ),
                    ),
                  ),
                controller: _amountController,
               
               colors: colors,
              ),
              CustomOutlinedFilledTextFormField(
                                  labelText: "Amount USD",
  suffixIcon: SizedBox(
                    width: 35,
                    child: Center(
                      child: Text(
                        "USD",
                        style: textTheme.bodyMedium?.copyWith(
                            color: colors.textColor, fontSize: fontSizeOf(15)),
                      ),
                    ),
                  ),
                  fontSizeOf: fontSizeOf,
                iconSizeOf: iconSizeOf,
                roundedOf: roundedOf,
                colors: colors,
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  if (value.isEmpty) {
                    setState(() {
                      _amountController.text = "";
                    });
                  }
                  final double usdAmount = double.parse(value);
                  setState(() {
                    _amountController.text = NumberFormatter()
                        .formatDecimal((usdAmount / cryptoPrice).toString());
                  });
                },
                controller: _amountUsdController,
           
              ),
              Align(
                alignment: Alignment.topLeft,
                child: Text(
                  "Balance : ${formatCryptoValue(crypto!.isNative ? nativeBalance : tokenBalance)} ${crypto!.symbol}",
                  style: textTheme.bodyMedium?.copyWith(
                      color: colors.textColor.withOpacity(0.7),
                      fontSize: fontSizeOf(14)),
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
                        if (crypto!.isNative) {
                          await sendTransaction();
                        } else {
                          await sendTokenTransaction();
                        }
                      }
                    },
                    child: Text(
                      "Next",
                      style: textTheme.bodyMedium?.copyWith(
                          color: colors.primaryColor, fontSize: fontSizeOf(14)),
                    )),
              )
            ],
          ),
        ),
      ),
    );
  }
}
