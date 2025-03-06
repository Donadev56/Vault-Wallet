// ignore_for_file: deprecated_member_use

import 'dart:convert';
import 'dart:io';
import 'package:moonwallet/service/wallet_saver.dart';
import 'package:path/path.dart' as path;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:moonwallet/logger/logger.dart';
import 'package:moonwallet/main.dart';
import 'package:moonwallet/service/price_manager.dart';
import 'package:moonwallet/service/vibration.dart';
import 'package:moonwallet/service/web3_interaction.dart';
import 'package:moonwallet/types/types.dart';
import 'package:moonwallet/utils/constant.dart';
import 'package:moonwallet/utils/crypto.dart';
import 'package:moonwallet/utils/prefs.dart';
import 'package:moonwallet/widgets/actions.dart';
import 'package:moonwallet/widgets/appBar.dart';
import 'package:moonwallet/widgets/bottom_pin_copy.dart';
import 'package:moonwallet/widgets/drawer.dart';
import 'package:moonwallet/widgets/navBar.dart';
import 'package:moonwallet/widgets/snackbar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';

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
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  File? _profileImage;
  File? _backgroundImage;
  String userName = "Moon User";
// Color primaryColor = Color(0xFFE4E4E4);    // Inversion of Color(0xFF1B1B1B)
//Color textColor = Color(0xFF0A0A0A);       // Inversion of Color(0xFFF5F5F5)
// Color secondaryColor = Color(0xFF960F51);  // Inversion of Colors.greenAccent (assumed as Color(0xFF69F0AE))
//Color actionsColor = Color(0xFFCACACA);     // Inversion of Color(0xFF353535)
// Color surfaceTintColor = Color(0xFFBABABA); // Inversion of Color(0xFF454545)

  List<PublicData> accounts = [];
  List<PublicData> filteredAccounts = [];
  final formatter = NumberFormat("0.########", "en_US");

  PublicData currentAccount = PublicData(
      keyId: "",
      creationDate: 0,
      walletName: "",
      address: "",
      isWatchOnly: false);
  late TabController _tabController;
  final web3Manager = WalletSaver();
  final encryptService = EncryptService();
  final priceManager = PriceManager();
  final web3InteractManager = Web3InteractionManager();
  final publicDataManager = PublicDataManager();
  bool isDarkMode = true;
  bool isHidden = false;

  double totalBalanceUsd = 0;
  String searchQuery = "";

  final List<Map<String, dynamic>> actionsData = [
    {'icon': LucideIcons.moveUpRight, 'page': 'send', 'name': 'Send'},
    {'icon': LucideIcons.moveDownLeft, 'page': 'receive', 'name': 'Receive'},
    {'icon': LucideIcons.scan, 'page': 'scan', 'name': 'Scan'},
    {'icon': LucideIcons.ellipsis, 'page': 'more', 'name': 'More'},
  ];
  final List<Map<String, dynamic>> options = [
    {'icon': LucideIcons.eye, 'name': 'Hide Balance'},
    {'icon': LucideIcons.send, 'name': 'Join Telegram'},
    {'icon': LucideIcons.messageCircle, 'name': 'Join Whatsapp'},
    {'icon': LucideIcons.settings, 'name': 'Settings'},
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
    getIsHidden();

    getThemeMode();

    getSavedWallets();
    loadData();
    super.initState();

    _tabController = TabController(length: 2, vsync: this);
  }

  Future<void> getIsHidden() async {
    try {
      final savedData =
          await publicDataManager.getDataFromPrefs(key: "isHidden");
      if (savedData != null) {
        if (savedData == "true") {
          isHidden = true;
        } else {
          isHidden = false;
        }
      }
    } catch (e) {
      log("Error getting isHidden: $e");
    }
  }

  Future<void> toggleHidden() async {
    setState(() {
      isHidden = !isHidden;
    });
    await publicDataManager.saveDataInPrefs(data: "$isHidden", key: "isHidden");
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

  Future<bool> loadData() async {
    try {
      final PublicDataManager prefs = PublicDataManager();

      final String? storedName = await prefs.getDataFromPrefs(key: "userName");
      log(storedName.toString());
      if (storedName != null) {
        setState(() {
          userName = storedName;
        });
      }

      // Retrieve the app's documents directory.
      final Directory appDocDir = await getApplicationDocumentsDirectory();
      final String moonImagesPath = path.join(appDocDir.path, "moon", "images");

      // Define file paths for the profile and background images.
      final String profileFilePath =
          path.join(moonImagesPath, "profileName.png");
      final String backgroundFilePath =
          path.join(moonImagesPath, "backgroundName.png");

      // Check if the profile image exists and update the state.
      final File profileImageFile = File(profileFilePath);
      if (await profileImageFile.exists()) {
        setState(() {
          _profileImage = profileImageFile;
        });
      }

      // Check if the background image exists and update the state.
      final File backgroundImageFile = File(backgroundFilePath);
      if (await backgroundImageFile.exists()) {
        setState(() {
          _backgroundImage = backgroundImageFile;
        });
      }

      return true;
    } catch (e) {
      log("Error loading data: $e");
      return false;
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
          isWatchOnly: wallet.isWatchOnly,
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

  Future<void> showPrivateData(int index) async {
    try {
      final wallet = accounts[index];
      if (wallet.isWatchOnly) {
        Navigator.pop(context);
        showCustomSnackBar(
            context: context,
            message: "This is a watch-only wallet.",
            iconColor: Colors.pinkAccent);
        return;
      }
      String userPassword = "";
      final result = await showPinModalBottomSheet(
          context: context,
          handleSubmit: (password) async {
            final savedPassword = await web3Manager.getSavedPassword();

            if (password.trim() == savedPassword!.trim()) {
              userPassword = password.trim();

              return PinSubmitResult(success: false, repeat: false);
            } else {
              if (mounted) {
                showCustomSnackBar(
                    context: context,
                    message: "Incorrect password",
                    iconColor: Colors.pinkAccent);
                Navigator.pop(context);
              }
              return PinSubmitResult(success: false, repeat: false);
            }
          },
          title: "Enter your password");
      if (result) {
        if (mounted) {
          Navigator.pushNamed(context, Routes.privateDataScreen,
              arguments: ({
                "keyId": accounts[index].keyId,
                "password": userPassword
              }));
        }
      }
    } catch (e) {
      logError(e.toString());
    }
  }

  Future<void> reorderList(int oldIndex, int newIndex) async {
    try {
      log(" old index : $oldIndex new index : $newIndex");
      if (oldIndex < newIndex) {
        newIndex -= 1;
      }
      final removedAccount = accounts.removeAt(oldIndex);
      setState(() {
        accounts.insert(newIndex, removedAccount);
      });
      final result = await web3Manager.saveListPublicDataJson(accounts);
      if (result) {
        log("Reordered successfully");
      } else {
        if (mounted) {
          showCustomSnackBar(
              context: context,
              message: "List reorder failed",
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
      publicDataManager.saveDataInPrefs(
          data: balanceEth.toString(),
          key: "${currentAccount.address}/lastBalanceEth");
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

  void showReceiveModal() {
    showModalBottomSheet(
        context: context,
        builder: (BuildContext btmCtx) {
          return Container(
            width: MediaQuery.of(context).size.width,
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
                color: primaryColor,
                borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(15),
                    topRight: Radius.circular(10))),
            child: Column(
              children: [
                TextField(
                  maxLines: 1,
                  minLines: 1,
                  scrollPadding: const EdgeInsets.all(10),
                  decoration: InputDecoration(
                    label: Text("Search crypto"),
                    labelStyle:
                        GoogleFonts.roboto(color: textColor.withOpacity(0.7)),
                    filled: true,
                    fillColor: surfaceTintColor.withOpacity(0.5),
                    prefixIcon: Icon(
                      Icons.search,
                      color: textColor,
                    ),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide:
                            BorderSide(width: 0, color: Colors.transparent)),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide:
                            BorderSide(width: 0, color: Colors.transparent)),
                  ),
                ),
                SizedBox(
                  height: 10,
                ),
                SingleChildScrollView(
                    child: SizedBox(
                  height: MediaQuery.of(btmCtx).size.height * 0.4,
                  child: ListView.builder(
                      itemCount: networks.length,
                      itemBuilder: (BuildContext lisCryptoCtx, int index) {
                        final net = networks[index];
                        return Material(
                          color: Colors.transparent,
                          child: ListTile(
                            onTap: () {
                              Navigator.pushNamed(context, Routes.receiveScreen,
                                  arguments: ({"index": index}));
                            },
                            leading: ClipRRect(
                              borderRadius: BorderRadius.circular(50),
                              child: Image.asset(
                                net.icon,
                                width: 35,
                                height: 35,
                                fit: BoxFit.cover,
                              ),
                            ),
                            title: Text(
                              net.name,
                              style: GoogleFonts.roboto(
                                  color: textColor,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                        );
                      }),
                )),
              ],
            ),
          );
        });
  }

  void showSendModal() {
    showModalBottomSheet(
        context: context,
        builder: (BuildContext btmCtx) {
          return Container(
            width: MediaQuery.of(context).size.width,
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
                color: primaryColor,
                borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(15),
                    topRight: Radius.circular(10))),
            child: Column(
              children: [
                TextField(
                  maxLines: 1,
                  minLines: 1,
                  scrollPadding: const EdgeInsets.all(10),
                  decoration: InputDecoration(
                    label: Text("Search crypto"),
                    labelStyle:
                        GoogleFonts.roboto(color: textColor.withOpacity(0.7)),
                    filled: true,
                    fillColor: surfaceTintColor.withOpacity(0.5),
                    prefixIcon: Icon(
                      Icons.search,
                      color: textColor,
                    ),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide:
                            BorderSide(width: 0, color: Colors.transparent)),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide:
                            BorderSide(width: 0, color: Colors.transparent)),
                  ),
                ),
                SizedBox(
                  height: 10,
                ),
                SingleChildScrollView(
                    child: SizedBox(
                  height: MediaQuery.of(btmCtx).size.height * 0.4,
                  child: ListView.builder(
                      itemCount: networks.length,
                      itemBuilder: (BuildContext lisCryptoCtx, int index) {
                        final net = networks[index];
                        return Material(
                          color: Colors.transparent,
                          child: ListTile(
                            onTap: () {
                              Navigator.pushNamed(context, Routes.sendScreen,
                                  arguments: ({"index": index}));
                            },
                            leading: ClipRRect(
                              borderRadius: BorderRadius.circular(50),
                              child: Image.asset(
                                net.icon,
                                width: 35,
                                height: 35,
                                fit: BoxFit.cover,
                              ),
                            ),
                            title: Text(
                              net.name,
                              style: GoogleFonts.roboto(
                                  color: textColor,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                        );
                      }),
                )),
              ],
            ),
          );
        });
  }

  void showOptionsModal() {
    showModalBottomSheet(
        isScrollControlled: true,
        context: context,
        builder: (BuildContext btmCtx) {
          return Container(
            height: MediaQuery.of(context).size.height * 0.32,
            width: MediaQuery.of(context).size.width,
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
                color: primaryColor,
                borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(15),
                    topRight: Radius.circular(10))),
            child: Column(
              children: [
                SizedBox(
                  height: MediaQuery.of(btmCtx).size.height * 0.26,
                  child: ListView.builder(
                      itemCount: options.length,
                      itemBuilder: (BuildContext lisCryptoCtx, int index) {
                        final opt = options[index];
                        return Material(
                          color: Colors.transparent,
                          child: ListTile(
                            onTap: () {
                              if (index == options.length - 1) {
                                Navigator.pushNamed(context, Routes.settings);
                              } else if (index == 1) {
                                launchUrl(
                                    Uri.parse("https://t.me/eternalprotocol"));
                              } else if (index == 2) {
                                launchUrl(Uri.parse(
                                    "https://www.whatsapp.com/channel/0029Vb2TpR9HrDZWVEkhWz21"));
                              } else if (index == 0) {
                                toggleHidden();
                              }
                            },
                            leading: Icon(
                              opt["icon"],
                              color: textColor,
                            ),
                            title: Text(
                              opt["name"],
                              style: GoogleFonts.roboto(
                                  color: textColor,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                        );
                      }),
                ),
              ],
            ),
          );
        });
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    double height = MediaQuery.of(context).size.height;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: primaryColor,
      drawer: MainDrawer(
          isDarkMode: isDarkMode,
          toggleMode: toggleMode,
          showSendModal: showSendModal,
          showReceiveModal: showReceiveModal,
          profileImage: _profileImage,
          backgroundImage: _backgroundImage,
          userName: userName,
          scaffoldKey: _scaffoldKey,
          primaryColor: primaryColor,
          textColor: textColor,
          surfaceTintColor: surfaceTintColor),
      appBar: CustomAppBar(
          profileImage: _profileImage,
          scaffoldKey: _scaffoldKey,
          showPrivateData: showPrivateData,
          reorderList: reorderList,
          secondaryColor: secondaryColor,
          changeAccount: changeWallet,
          deleteWallet: deleteWallet,
          editWalletName: editWalletName,
          currentAccount: currentAccount,
          accounts: accounts,
          primaryColor: primaryColor,
          textColor: textColor,
          surfaceTintColor: surfaceTintColor),
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
        backgroundColor: textColor.withOpacity(0.8),
        key: _refreshIndicatorKey,
        onRefresh: () async {
          await loadData();

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
                        IconButton(
                            onPressed: toggleHidden,
                            icon: Icon(
                              isHidden
                                  ? LucideIcons.eyeClosed
                                  : Icons.remove_red_eye_outlined,
                              color: textColor,
                              size: 22,
                            ))
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
                            text: isHidden
                                ? "***"
                                : "\$ ${totalBalanceUsd.toStringAsFixed(2)}",
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
                        onTap: () {
                          if (index == 1) {
                            showReceiveModal();
                          } else if (index == 0) {
                            showSendModal();
                          } else if (index == 3) {
                            showOptionsModal();
                          } else if (index == 2) {}
                        },
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
                            Navigator.pushNamed(context, Routes.walletOverview,
                                arguments: ({"index": index}));
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
                                        child: Text(
                                            isHidden
                                                ? "***"
                                                : "${formatter.format(result.data).split('0').length - 1 > 6 ? 0 : formatter.format(result.data)}",
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
                              FutureBuilder(
                                  future: getBalanceUsd(crypto["binanceSymbol"],
                                      crypto["rpcUrl"]),
                                  builder: (BuildContext balanceCtx,
                                      AsyncSnapshot result) {
                                    if (result.hasData) {
                                      return Text(
                                          isHidden
                                              ? "***"
                                              : "\$ ${result.data.toStringAsFixed(3)}",
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
