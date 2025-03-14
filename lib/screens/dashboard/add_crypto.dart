// ignore_for_file: deprecated_member_use, use_build_context_synchronously

import 'dart:convert';
import 'dart:ui';
import 'package:moonwallet/main.dart';
import 'package:moonwallet/service/wallet_saver.dart';
import 'package:moonwallet/utils/colors.dart';
import 'package:moonwallet/utils/crypto.dart';
import 'package:moonwallet/utils/themes.dart';
import 'package:moonwallet/widgets/crypto_picture.dart';
import 'package:moonwallet/widgets/func/show_add_token.dart';
import 'package:ulid/ulid.dart';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:moonwallet/logger/logger.dart';
import 'package:moonwallet/service/crypto_storage_manager.dart';
import 'package:moonwallet/service/token_manager.dart';
import 'package:moonwallet/types/types.dart';
import 'package:moonwallet/utils/prefs.dart';

class AddCryptoView extends StatefulWidget {
  const AddCryptoView({super.key});

  @override
  State<AddCryptoView> createState() => _AddCryptoViewState();
}

class _AddCryptoViewState extends State<AddCryptoView> {
  bool isDarkMode = true;
  Crypto? selectedNetwork;
  List<Crypto> reorganizedCrypto = [];
  SearchingContractInfo? searchingContractInfo;
  final cryptoStorageManager = CryptoStorageManager();
  final tokenManager = TokenManager();
  List<PublicData> accounts = [];
  final web3Manager = WalletSaver();
  final encryptService = EncryptService();

  bool hasSaved = false;
  PublicData? currentAccount;
  final nullAccount = PublicData(
      keyId: "",
      creationDate: 0,
      walletName: "",
      address: "",
      isWatchOnly: false);
  final TextEditingController _searchController = TextEditingController();

  final publicDataManager = PublicDataManager();
  AppColors colors = AppColors(
      primaryColor: Color(0XFF0D0D0D),
      themeColor: Colors.greenAccent,
      greenColor: Colors.greenAccent,
      secondaryColor: Color(0XFF121212),
      grayColor: Color(0XFF353535),
      textColor: Colors.white,
      redColor: Colors.pinkAccent);
  bool saved = false;
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
    getSavedTheme();
    getSavedWallets();
  }

  String generateUUID() {
    return Ulid().toUuid();
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
          await reorganizeCrypto(account: account);

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

  Future<void> reorganizeCrypto({required PublicData account}) async {
    if (currentAccount == null) {
      logError("The current account is null");
      return;
    }
    List<Crypto> newCryptos = [];
    final savedCrypto =
        await cryptoStorageManager.getSavedCryptos(wallet: account);
    if (savedCrypto != null) {
      newCryptos.addAll(savedCrypto);
    }

    newCryptos.sort((a, b) => (a.name).compareTo(b.name));
    log("New cryptos ${newCryptos.length}");

    setState(() {
      reorganizedCrypto = newCryptos;
    });
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return Scaffold(
      backgroundColor: colors.primaryColor,
      appBar: AppBar(
        surfaceTintColor: colors.primaryColor,
        backgroundColor: colors.primaryColor,
        actions: [
          Container(
            margin: const EdgeInsets.all(10),
            height: 35,
            width: 35,
            decoration: BoxDecoration(
                color: colors.grayColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(5)),
            child: IconButton(
              onPressed: () {
                showAddToken(
                    context: context,
                    colors: colors,
                    width: width,
                    reorganizedCrypto: reorganizedCrypto,
                    currentAccount: currentAccount ?? nullAccount,
                    hasSaved: hasSaved);
              },
              icon: Icon(
                LucideIcons.plus,
                color: colors.textColor,
                size: 20,
              ),
            ),
          ),
        ],
        leading: IconButton(
            onPressed: () {
              Navigator.pushNamed(context, Routes.pageManager);
            },
            icon: Icon(
              LucideIcons.chevronLeft,
              color: colors.textColor,
            )),
        title: Text(
          "Manage Coins ",
          style: GoogleFonts.robotoFlex(color: colors.textColor),
        ),
      ),
      body: Column(
        spacing: 15,
        children: [
          SizedBox(
            height: 10,
          ),
          Align(
            alignment: Alignment.center,
            child: SizedBox(
              width: width * 0.92,
              child: TextField(
                onChanged: (v) {
                  setState(() {
                    _searchController.text = v;
                  });
                },
                style: GoogleFonts.roboto(color: colors.textColor),
                cursorColor: colors.themeColor,
                controller: _searchController,
                decoration: InputDecoration(
                    hintText: "Search Crypto",
                    hintStyle: GoogleFonts.robotoFlex(
                        color: colors.textColor.withOpacity(0.4)),
                    contentPadding:
                        const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                    prefixIcon: Icon(
                      Icons.search,
                      color: colors.textColor.withOpacity(0.3),
                    ),
                    filled: true,
                    fillColor: colors.grayColor.withOpacity(0.1),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide:
                            BorderSide(width: 0, color: Colors.transparent)),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide:
                            BorderSide(width: 0, color: Colors.transparent))),
              ),
            ),
          ),
          Expanded(
              child: ListView.builder(
                  itemCount: reorganizedCrypto
                      .where((c) => c.symbol
                          .toLowerCase()
                          .contains(_searchController.text.toLowerCase()))
                      .length,
                  itemBuilder: (ctx, i) {
                    final crypto = reorganizedCrypto
                        .where((c) => c.symbol
                            .toLowerCase()
                            .contains(_searchController.text.toLowerCase()))
                        .toList()[i];

                    return Material(
                      color: Colors.transparent,
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                            vertical: 8, horizontal: 20),
                        onTap: () {},
                        leading: CryptoPicture(
                            crypto: crypto, size: 40, colors: colors),
                        title: Text(
                          crypto.symbol,
                          style: GoogleFonts.roboto(
                              color: colors.textColor,
                              fontSize: 16,
                              fontWeight: FontWeight.bold),
                        ),
                        trailing: Switch(
                            value: crypto.canDisplay,
                            onChanged: (newVal) async {
                              final result =
                                  await cryptoStorageManager.toggleCanDisplay(
                                      wallet: currentAccount ?? nullAccount,
                                      cryptoId: crypto.cryptoId,
                                      value: newVal);
                              if (result) {
                                log("State changed successfully");
                                await reorganizeCrypto(
                                    account: currentAccount ?? nullAccount);
                              } else {
                                log("Error changing state");
                              }
                            }),
                      ),
                    );
                  }))
        ],
      ),
    );
  }
}
