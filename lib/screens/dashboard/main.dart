// ignore_for_file: deprecated_member_use

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:moonwallet/logger/logger.dart';
import 'package:moonwallet/main.dart';
import 'package:moonwallet/service/price_manager.dart';
import 'package:moonwallet/service/vibration.dart';
import 'package:moonwallet/service/web3.dart';
import 'package:moonwallet/service/web3_interaction.dart';
import 'package:moonwallet/types/types.dart';
import 'package:moonwallet/utils/crypto.dart';
import 'package:moonwallet/utils/prefs.dart';
import 'package:moonwallet/widgets/actions.dart';
import 'package:moonwallet/widgets/appBar.dart';
import 'package:moonwallet/widgets/bottom_pin.dart';
import 'package:moonwallet/widgets/navBar.dart';
import 'package:moonwallet/widgets/snackbar.dart';
import 'package:vibration/vibration.dart';

class MainDashboardScreen extends StatefulWidget {
  const MainDashboardScreen({super.key});

  @override
  State<MainDashboardScreen> createState() => _MainDashboardScreenState();
}

class _MainDashboardScreenState extends State<MainDashboardScreen>
    with SingleTickerProviderStateMixin {
  Color primaryColor = Color(0XFF1B1B1B);
  Color textColor = Color.fromARGB(255, 255, 255, 255);
  Color secondaryColor = Colors.greenAccent;
  Color actionsColor = Color(0XFF353535);
  Color surfaceTintColor = Color(0XFF454545);
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
      GlobalKey<RefreshIndicatorState>();

// Color primaryColor = Color(0xFFE4E4E4);    // Inversion of Color(0xFF1B1B1B)
//Color textColor = Color(0xFF0A0A0A);       // Inversion of Color(0xFFF5F5F5)
// Color secondaryColor = Color(0xFF960F51);  // Inversion of Colors.greenAccent (assumed as Color(0xFF69F0AE))
//Color actionsColor = Color(0xFFCACACA);     // Inversion of Color(0xFF353535)
// Color surfaceTintColor = Color(0xFFBABABA); // Inversion of Color(0xFF454545)

  List<PublicData> accounts = [];
  PublicData currentAccount =
      PublicData(keyId: "", creationDate: 0, walletName: "", address: "");
  late TabController _tabController;
  final web3Manager = Web3Manager();
  final encryptService = EncryptService();
  final priceManager = PriceManager();
  final web3InteractManager = Web3InteractionManager();
  final publicDataManager = PublicDataManager();
  double totalBalanceUsd = 0;

  final List<Map<String, dynamic>> actionsData = [
    {'icon': LucideIcons.moveUpRight, 'page': 'send', 'name': 'Send'},
    {'icon': LucideIcons.moveDownLeft, 'page': 'receive', 'name': 'Receive'},
    {'icon': LucideIcons.scan, 'page': 'scan', 'name': 'Scan'},
    {'icon': LucideIcons.ellipsis, 'page': 'more', 'name': 'More'},
  ];
  final List<Map<String, dynamic>> cryptos = [
    {
      'image': "assets/b1.webp",
      'name': 'OpBNB',
      "price": 580,
      "symbol": 'BNB',
      "binanceSymbol": "BNBUSDT",
      "rpcUrl": "https://opbnb-mainnet-rpc.bnbchain.org"
    },
    {
      'image': "assets/bnb.png",
      'name': 'BNB',
      "price": 580,
      "symbol": 'BNB',
      "binanceSymbol": "BNBUSDT",
      "rpcUrl": "https://bsc-dataseed.binance.org"
    },
    {
      'image': "assets/image.png",
      'name': 'Moon Token',
      "price": 0,
      "symbol": 'MT',
      "binanceSymbol": "",
      "rpcUrl": ""
    },
  ];

  @override
  void initState() {
    getSavedWallets();
    super.initState();

    _tabController = TabController(length: 2, vsync: this);
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
          getTotalBalance();

          log("The current wallet is ${json.encode(account.toJson())}");
          break;
        } else {
          log("Not account found");
          currentAccount = accounts[0];
          getTotalBalance();
        }
      }
    } catch (e) {
      logError('Error getting saved wallets: $e');
    }
  }

  Future<void> editWalletName(String name, int index) async {
    try {
      if (name.isEmpty) {
        showCustomSnackBar(
            context: context,
            message: "Name cannot be empty",
            iconColor: Colors.pinkAccent);
        Navigator.pop(context);
        return;
      }
      final wallet = accounts[index];
      final PublicData newWallet = PublicData(
          address: wallet.address,
          walletName: name,
          creationDate: wallet.creationDate,
          keyId: wallet.keyId);
      setState(() {
        accounts[index] = newWallet;
        currentAccount = newWallet;
      });
      final result = await web3Manager.saveListPublicDataJson(accounts);
      if (result) {
        if (mounted) {
          showCustomSnackBar(
              context: context,
              message: "Name edit was successful",
              iconColor: Colors.greenAccent);
        }
      } else {
        if (mounted) {
          showCustomSnackBar(
              context: context,
              message: "Name edit failed",
              iconColor: Colors.pinkAccent);
          Navigator.pop(context);
        }
      }
    } catch (e) {
      logError(e.toString());
      if (mounted) {
        Navigator.pop(context);
      }
    }
  }

  Future<void> deleteWallet(int index) async {
    try {
      showPinModalBottomSheet(
          context: context,
          handleSubmit: (password) async {
            final savedPassword = await web3Manager.getSavedPassword();

            if (password.trim() == savedPassword!.trim()) {
              final currentList = accounts;
              if (currentList[index].keyId == currentAccount.keyId &&
                  index > 0) {
                setState(() {
                  currentAccount = accounts[0];
                });
              }
              currentList.removeAt(index);
              final result =
                  await web3Manager.saveListPublicDataJson(currentList);
              if (result) {
                if (mounted) {
                  showCustomSnackBar(
                      context: context,
                      message: "Wallet deleted successfully",
                      icon: Icons.check_circle,
                      iconColor: Colors.greenAccent);

                  setState(() {
                    accounts = currentList;
                  });
                  Navigator.pop(context);

                  return PinSubmitResult(success: true, repeat: false);
                }
                return PinSubmitResult(success: false, repeat: false);
              } else {
                if (mounted) {
                  showCustomSnackBar(
                      context: context,
                      message: "Wallet deletion failed",
                      iconColor: Colors.pinkAccent);
                  Navigator.pop(context);
                  return PinSubmitResult(success: false, repeat: false);
                }
                return PinSubmitResult(success: false, repeat: false);
              }
            } else {
              showCustomSnackBar(
                  context: context,
                  message: "Incorrect password",
                  iconColor: Colors.pinkAccent);
              Navigator.pop(context);
              return PinSubmitResult(success: false, repeat: false);
            }
          },
          title: "Enter your password");
    } catch (e) {
      logError(e.toString());
    }
  }

  Future<void> changeWallet(int index) async {
    try {
      final wallet = accounts[index];
      setState(() {
        currentAccount = wallet;
        totalBalanceUsd = 0;
      });
      final changeResult = await web3Manager.saveLastAccount(wallet.address);
      if (changeResult) {
        if (mounted) {
          showCustomSnackBar(
              context: context,
              icon: Icons.check_circle,
              message: "Wallet changed successfully",
              iconColor: Colors.greenAccent);
          getTotalBalance();
          Navigator.pop(context);
        }
      } else {
        if (mounted) {
          showCustomSnackBar(
              context: context,
              message: "Wallet change failed",
              iconColor: Colors.pinkAccent);
          Navigator.pop(context);
        }
      }
    } catch (e) {
      logError(e.toString());
    }
  }

  Future<double> getPrice(String symbol) async {
    try {
      if (symbol.isEmpty) return 0;
      final result = await priceManager.getPriceUsingBinanceApi(symbol);
      return result;
    } catch (e) {
      logError(e.toString());
      return 0;
    }
  }

  Future<void> getTotalBalance() async {
    try {
      String dataName = "lastUserBalance";
      double balance = 0;
      final savedData = await publicDataManager.getDataFromPrefs(
          key: "$dataName/${currentAccount.keyId}");
      log("Saved data $savedData");
      if (savedData != null) {
        setState(() {
          totalBalanceUsd = double.parse(savedData);
        });
      }

      for (final crypto in cryptos) {
        if (crypto["binanceSymbol"] is String &&
                crypto["binanceSymbol"].isEmpty ||
            crypto['rpcUrl'] is String && crypto['rpcUrl'].isEmpty) {
          continue;
        }
        final balanceUsd =
            await getBalanceUsd(crypto['binanceSymbol'], crypto['rpcUrl']);
        balance += balanceUsd;
        log("Balance $balance");
      }
      setState(() {
        totalBalanceUsd = balance;
      });

      publicDataManager.saveDataInPrefs(
          data: balance.toString(), key: "$dataName/${currentAccount.keyId}");
    } catch (e) {
      logError(e.toString());
    }
  }

  Future<double> getBalanceUsd(String symbol, String rpcUrl) async {
    try {
      if (rpcUrl.isEmpty || symbol.isEmpty) {
        return 0;
      }
      final price = await getPrice(symbol);
      final balanceEth =
          await web3InteractManager.getBalance(currentAccount.address, rpcUrl);
      final balanceUsd = balanceEth * price;
      if (balanceUsd > 0) {
        return price * balanceEth;
      }
      return 0;
    } catch (e) {
      logError(e.toString());
      return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    double height = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: primaryColor,
      appBar: CustomAppBar(
          secondaryColor: secondaryColor,
          changeAccount: changeWallet,
          deleteWallet: deleteWallet,
          editWalletName: editWalletName,
          currentAccount: currentAccount,
          accounts: accounts,
          primaryColor: primaryColor,
          textColor: textColor,
          surfaceTintColor: primaryColor),
      bottomNavigationBar: BottomNav(
          onTap: (index) async {
            await vibrate();

            if (index == 1) {
              Navigator.pushNamed(context, Routes.discover);
            }
          },
          currentIndex: 0,
          primaryColor: primaryColor,
          textColor: textColor,
          secondaryColor: secondaryColor),
      body: RefreshIndicator(
        color: primaryColor,
        backgroundColor: textColor,
        key: _refreshIndicatorKey,
        onRefresh: () async {
          await vibrate(duration: 10);
          await getTotalBalance();
        },
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                margin: const EdgeInsets.all(17),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Balance",
                          style: GoogleFonts.roboto(color: textColor),
                        ),
                        SizedBox(
                          width: 10,
                        ),
                        Icon(
                          Icons.remove_red_eye_outlined,
                          color: textColor,
                          size: 22,
                        )
                      ],
                    ),
                    SizedBox(
                      height: 10,
                    ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        RichText(
                          text: TextSpan(
                            text: "\$ ${totalBalanceUsd.toStringAsFixed(2)}",
                            style: GoogleFonts.roboto(
                                color: textColor,
                                fontSize: 30,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                        SizedBox(
                          width: 2,
                        ),
                      ],
                    )
                  ],
                ),
              ),
              Container(
                margin: const EdgeInsets.only(top: 20),
                alignment: Alignment.center,
                child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(actionsData.length, (index) {
                      final action = actionsData[index];
                      return ActionsWidgets(
                        text: action["name"],
                        actIcon: action["icon"],
                        textColor: textColor,
                        actionsColor: actionsColor,
                      );
                    })),
              ),
              SizedBox(
                height: 10,
              ),
              TabBar(
                dividerColor: Colors.transparent,
                controller: _tabController,
                labelColor: textColor,
                unselectedLabelColor: Colors.grey,
                indicatorColor: secondaryColor,
                tabs: [
                  Tab(text: 'Crypto'),
                  Tab(
                    text: 'Nfts',
                  ),
                ],
              ),
              SizedBox(
                height: 20,
              ),
              SizedBox(
                height: height * 0.5,
                width: width,
                child: TabBarView(controller: _tabController, children: [
                  Column(
                    children: List.generate(cryptos.length, (index) {
                      final crypto = cryptos[index];
                      return Material(
                        color: Colors.transparent,
                        child: ListTile(
                          onTap: () {
                            log("Clicked");
                          },
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(50),
                            child: Image.asset(
                              crypto['image'],
                              width: 40,
                              height: 40,
                            ),
                          ),
                          title: Text(
                            crypto['name'],
                            style: GoogleFonts.roboto(
                                color: textColor,
                                fontSize: 16,
                                fontWeight: FontWeight.bold),
                          ),
                          subtitle: FutureBuilder(
                              future: getPrice(crypto["binanceSymbol"] ?? ""),
                              builder: (BuildContext priceCtx,
                                  AsyncSnapshot result) {
                                if (result.hasData) {
                                  return Text("${result.data}",
                                      style: GoogleFonts.roboto(
                                          color: textColor.withOpacity(0.6),
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold));
                                } else {
                                  return Text("...",
                                      style: GoogleFonts.roboto(
                                          color: textColor.withOpacity(0.6),
                                          fontSize: 14));
                                }
                              }),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              SizedBox(
                                width: 5,
                              ),
                              FutureBuilder(
                                  future: web3InteractManager.getBalance(
                                      currentAccount.address,
                                      crypto["rpcUrl"] ?? ""),
                                  builder: (BuildContext balanceCtx,
                                      AsyncSnapshot result) {
                                    if (result.hasData) {
                                      return ConstrainedBox(
                                        constraints: BoxConstraints(
                                            maxWidth: width * 0.3),
                                        child: Text("${result.data}",
                                            overflow: TextOverflow.clip,
                                            maxLines: 1,
                                            
                                            style: GoogleFonts.roboto(
                                                color: textColor,
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold)),
                                      );
                                    } else {
                                      return Text("...",
                                          style: GoogleFonts.roboto(
                                              color: textColor.withOpacity(0.6),
                                              fontSize: 14));
                                    }
                                  }),
                              SizedBox(
                                height: 10,
                              ),
                              FutureBuilder(
                                  future: getBalanceUsd(crypto["binanceSymbol"],
                                      crypto["rpcUrl"]),
                                  builder: (BuildContext balanceCtx,
                                      AsyncSnapshot result) {
                                    if (result.hasData) {
                                      return Text(
                                          "\$ ${result.data.toStringAsFixed(3)}",
                                          style: GoogleFonts.roboto(
                                              color: textColor.withOpacity(0.6),
                                              fontSize: 14));
                                    } else {
                                      return Text("...",
                                          style: GoogleFonts.roboto(
                                              color: textColor.withOpacity(0.6),
                                              fontSize: 14));
                                    }
                                  })
                            ],
                          ),
                        ),
                      );
                    }),
                  ),
                  Container(
                    color: Colors.transparent,
                    child: Center(
                      child: Text(
                        'Coming soon',
                        style: GoogleFonts.roboto(color: textColor),
                      ),
                    ),
                  ),
                ]),
              )
            ],
          ),
        ),
      ),
    );
  }
}
