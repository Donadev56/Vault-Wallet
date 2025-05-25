// ignore_for_file: deprecated_member_use

import 'dart:convert';

import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:moonwallet/custom/web3_webview/lib/utils/loading.dart';
import 'package:moonwallet/logger/logger.dart';
import 'package:moonwallet/notifiers/providers.dart';
import 'package:moonwallet/screens/dashboard/page_manager.dart';
import 'package:moonwallet/service/db/list_address_dynamic_db.dart';
import 'package:moonwallet/service/external_data/transaction_manager.dart';
import 'package:moonwallet/service/rpc_service.dart';
import 'package:moonwallet/types/account_related_types.dart';
import 'package:moonwallet/types/transaction.dart';
import 'package:moonwallet/utils/number_formatter.dart';
import 'package:moonwallet/service/external_data/price_manager.dart';
import 'package:moonwallet/service/vibration.dart';
import 'package:moonwallet/service/db/wallet_db.dart';
import 'package:moonwallet/types/types.dart';
import 'package:moonwallet/utils/colors.dart';
import 'package:moonwallet/utils/encrypt_service.dart';
import 'package:moonwallet/utils/prefs.dart';
import 'package:moonwallet/utils/themes.dart';
import 'package:moonwallet/widgets/app_bar_title.dart';
import 'package:moonwallet/widgets/backup/backup_related.dart';
import 'package:moonwallet/widgets/buttons/elevated.dart';
import 'package:moonwallet/widgets/custom_outlined_filled_textField.dart';
import 'package:moonwallet/widgets/screen_widgets/crypto_picture.dart';
import 'package:moonwallet/widgets/func/account_related/show_select_last_addr.dart';
import 'package:moonwallet/widgets/dialogs/show_custom_snackbar.dart';
import 'package:moonwallet/widgets/scanner/show_scanner.dart';
import 'package:moonwallet/widgets/send_widgets/account_chip.dart';
import 'package:moonwallet/widgets/send_widgets/address_chip.dart';
import 'package:permission_handler/permission_handler.dart';

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
  final MobileScannerController _mobileScannerController =
      MobileScannerController();

  final formatter = NumberFormatter();

  String cryptoPrice = "0";
  String tokenBalance = "0";
  bool isAndroid = false;
  double networkBalance = 0;
  bool isDarkMode = false;
  Color darkNavigatorColor = Color(0XFF0D0D0D);
  List<PublicAccount> accounts = [];
  List<PublicAccount> filteredAccounts = [];
  List<dynamic> lastEthUsedAddresses = [];
  List<String> lastAddresses = [];
  PublicAccount currentAccount = PublicAccount(
      origin: Origin.publicAddress,
      supportedNetworks: [],
      createdLocally: false,
      keyId: "",
      creationDate: 0,
      walletName: "",
      addresses: [],
      isWatchOnly: false);
  final web3Manager = WalletDatabase();
  final encryptService = EncryptService();
  final priceManager = PriceManager();

  Crypto? crypto;

  final rpcService = RpcService();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _amountUsdController = TextEditingController();
  AppColors colors = AppColors.defaultTheme;
  Themes themes = Themes();

  Future<void> getSavedTheme() async {
    try {
      final manager = ColorsManager();
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
      cryptoPrice = widget.initData.cryptoPrice;

      tokenBalance = widget.initData.initialBalanceCrypto;
    });

    getInitialData();
  }

  @override
  void initState() {
    super.initState();
    init();
    getSavedTheme();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      askCamera();
    });
  }

  @override
  void reassemble() {
    super.reassemble();
  }

  @override
  void dispose() {
    _addressController.dispose();
    _amountController.dispose();
    _amountUsdController.dispose();
    super.dispose();
  }

  String address() {
    if (crypto == null) {
      throw "No Coin founded";
    }
    return currentAccount.addressByToken(crypto!);
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
      if (crypto == null) {
        throw "The current crypto cannot be null";
      }
      final to = _addressController.text;
      final from = currentAccount.addressByToken(crypto!);
      final amount = _amountController.text;
      final tx = await rpcService.sentTransaction(
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
          saveLastUsedAddresses(to);
          final targetTransaction =
              await TransactionManager(account: currentAccount, token: crypto!)
                  .addTransactionAfterTransfer(tx ?? "Not Found", amount, to)
                  .withLoading(context, colors, "Updating...");

          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => PagesManagerView(
                        colors: colors,
                        currentAccount: currentAccount,
                        crypto: crypto,
                        transaction: StandardTransaction(
                          token: crypto!,
                          status: targetTransaction?.status,
                          from: from,
                          to: to,
                          uiAmount: amount,
                          timeStamp:
                              (DateTime.now().millisecondsSinceEpoch / 1000)
                                  .toInt(),
                          transactionId: tx ?? "",
                        ),
                      )));
        }
      } else {
        throw Exception("Transaction Failed");
      }
    } catch (e) {
      logError(e.toString());
      notifyError(e.toString(), context);
    }
  }

  Future<void> saveLastUsedAddresses(String newAddress) async {
    try {
      if (crypto == null) {
        throw "No Coin found";
      }
      if (newAddress.isEmpty) {
        throw "Address is empty";
      }
      final db = ListAddressDynamicDb(account: currentAccount, crypto: crypto!);
      final lastUsedAddresses = await db.getData();

      log("last address $lastUsedAddresses");
      if (lastUsedAddresses.isEmpty) {
        final lastAddr = [newAddress];
        await db.saveData(lastAddr);
        return;
      }
      List<String> savedListAddressSet =
          lastUsedAddresses.toSet().toList() as List<String>;
      log("Address  $savedListAddressSet");

      savedListAddressSet = [newAddress, ...savedListAddressSet];
      await db.saveData(savedListAddressSet.toSet().toList());
      log("last addresses $savedListAddressSet");
    } catch (e) {
      logError(e.toString());
    }
  }

  Future<void> getInitialData() async {
    try {
      if (crypto == null) {
        throw Exception("No Coin found");
      }

      final addressKey =
          "${currentAccount.addressByToken(crypto!)}/lastUsedAddresses";
      final lastAddress =
          await PublicDataManager().getDataFromPrefs(key: addressKey);

      setState(() {
        if (lastAddress != null) {
          lastEthUsedAddresses = json.decode(lastAddress);
        }
      });
    } catch (e, st) {
      logError("getInitialData error: $e\n$st");
    }
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
                Icons.chevron_left,
                color: colors.textColor,
              )),
          title: AppBarTitle(title: "Send", colors: colors)),
      body: SizedBox(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: SpaceWithFixedBottom(
              body: Column(
                spacing: 20,
                children: [
                  Row(
                    spacing: 10,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      InkWell(
                        borderRadius: BorderRadius.circular(roundedOf(15)),
                        onTap: () {
                          vibrate();
                          Clipboard.setData(ClipboardData(text: address()));
                        },
                        child: AddressChip(
                            address: address(),
                            colors: colors,
                            icon: CryptoPicture(
                              crypto: crypto!,
                              size: imageSizeOf(20),
                              colors: colors,
                              primaryColor: colors.secondaryColor,
                            ),
                            fontSizeOf: fontSizeOf,
                            roundedOf: roundedOf),
                      ),
                      AccountChip(
                          colors: colors,
                          currentAccount: currentAccount,
                          fontSizeOf: fontSizeOf,
                          roundedOf: roundedOf),
                    ],
                  ),
                  Material(
                    color: colors.secondaryColor,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(roundedOf(10))),
                    child: ListTile(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(roundedOf(10))),
                      visualDensity:
                          VisualDensity(horizontal: -2, vertical: -2),
                      leading: CryptoPicture(
                        crypto: crypto!,
                        size: imageSizeOf(30),
                        colors: colors,
                        primaryColor: colors.secondaryColor,
                      ),
                      title: Text(
                        crypto!.symbol,
                        style: textTheme.bodyMedium?.copyWith(
                            color: colors.textColor,
                            fontSize: fontSizeOf(14),
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      Text(
                        "To",
                        style: textTheme.bodyMedium
                            ?.copyWith(color: colors.textColor),
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
                                    currentAccount: currentAccount,
                                    colors: colors,
                                    addressController: _addressController,
                                    crypto: crypto!);
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
                      textStyle: textTheme.bodyMedium?.copyWith(
                          color: colors.textColor, fontWeight: FontWeight.w500),
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
                      validator: (v) =>
                          rpcService.validateAddress(v ?? "", crypto!),
                      onChanged: (value) {
                        setState(() {
                          filteredAccounts = accounts
                              .where((account) => account
                                  .addressByToken(crypto!)
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
                    textStyle: textTheme.bodyMedium?.copyWith(
                        color: colors.textColor, fontWeight: FontWeight.bold),
                    labelText: "Amount ${crypto!.symbol}",
                    fontSizeOf: fontSizeOf,
                    iconSizeOf: iconSizeOf,
                    roundedOf: roundedOf,
                    validator: (v) {
                      log("Value $v");
                      if (Decimal.parse(v ?? "0") >
                          Decimal.parse(tokenBalance)) {
                        return "Amount exceeds balance";
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
                      final cryptoAmount = Decimal.parse(value);
                      setState(() {
                        _amountUsdController.text = NumberFormatter()
                            .formatDecimal(
                                (cryptoAmount * Decimal.parse(cryptoPrice))
                                    .toString());
                      });
                    },
                    suffixIcon: Container(
                      margin: const EdgeInsets.all(5),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(roundedOf(10)),
                        onTap: () {
                          try {
                            setState(() {
                              _amountController.text = formatter
                                  .formatDecimal(tokenBalance, maxDecimals: 8);

                              _amountUsdController.text =
                                  (Decimal.parse(tokenBalance) *
                                          Decimal.parse(formatter.formatDecimal(
                                              cryptoPrice.toString())))
                                      .toString();

                              log("Amount ${_amountUsdController.text}");
                            });
                          } catch (e) {
                            logError(e.toString());
                          }
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
                    textStyle: textTheme.bodyMedium?.copyWith(
                        color: colors.textColor, fontWeight: FontWeight.bold),
                    labelText: "Amount USD",
                    suffixIcon: SizedBox(
                      width: 35,
                      child: Center(
                        child: Text(
                          "USD",
                          style: textTheme.bodyMedium?.copyWith(
                              color: colors.textColor,
                              fontSize: fontSizeOf(15)),
                        ),
                      ),
                    ),
                    fontSizeOf: fontSizeOf,
                    iconSizeOf: iconSizeOf,
                    roundedOf: roundedOf,
                    colors: colors,
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      try {
                        if (value.isEmpty) {
                          setState(() {
                            _amountController.text = "";
                          });
                          return;
                        }
                        final usdAmount = value;

                        final amountCrypto = (double.parse(usdAmount) /
                                double.parse(cryptoPrice))
                            .toString();

                        setState(() {
                          _amountController.text = NumberFormatter()
                              .formatDecimal(amountCrypto.toString());
                        });
                      } catch (e) {
                        logError(e.toString());
                      }
                    },
                    controller: _amountUsdController,
                  ),
                  Align(
                    alignment: Alignment.topLeft,
                    child: InkWell(
                      child: Text(
                        "Balance : ${formatter.formatValue(str: tokenBalance)} ${crypto!.symbol}",
                        style: textTheme.bodyMedium?.copyWith(
                            color: colors.textColor.withOpacity(0.7),
                            fontSize: fontSizeOf(14)),
                      ),
                    ),
                  ),
                ],
              ),
              bottom: ConstrainedBox(
                constraints: BoxConstraints(minWidth: width * 0.95),
                child: CustomElevatedButton(
                  enabled: _amountController.text.isNotEmpty &&
                      _addressController.text.isNotEmpty,
                  colors: colors,
                  onPressed: () async {
                    if (FocusScope.of(context).hasFocus) {
                      FocusScope.of(context).unfocus();
                    }
                    if (_amountController.text.isEmpty) return;

                    if (_formKey.currentState!.validate()) {
                      log("Validation success !");
                      sendTransaction();
                    }
                  },
                  text: "Next",
                ),
              )),
        ),
      ),
    );
  }
}
