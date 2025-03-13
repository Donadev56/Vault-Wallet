// ignore_for_file: deprecated_member_use

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:moonwallet/custom/web3_webview/lib/widgets/custom_modal.dart';
import 'package:moonwallet/service/crypto_storage_manager.dart';
import 'package:moonwallet/service/network.dart';
import 'package:moonwallet/service/wallet_saver.dart';
import 'package:moonwallet/utils/colors.dart';
import 'package:moonwallet/widgets/crypto_picture.dart';
import 'package:moonwallet/widgets/func/show_crypto_modal.dart';
import 'package:moonwallet/widgets/text.dart';
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
  List<Balance> cryptosAndBalance = [];
  bool isLoading = true;

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

  AppColors colors = AppColors(
      primaryColor: Color(0XFF0D0D0D),
      themeColor: Colors.greenAccent,
      greenColor: Colors.greenAccent,
      secondaryColor: Color(0XFF121212),
      grayColor: Color(0XFF353535),
      textColor: Colors.white,
      redColor: Colors.pinkAccent);

  List<PublicData> accounts = [];
  List<PublicData> filteredAccounts = [];
  List<Crypto> reorganizedCrypto = [];
  final formatter = NumberFormat("0.########", "en_US");

  PublicData? currentAccount;

  late TabController _tabController;
  final web3Manager = WalletSaver();
  final encryptService = EncryptService();
  final priceManager = PriceManager();
  final web3InteractManager = Web3InteractionManager();
  final publicDataManager = PublicDataManager();
  final cryptoStorageManager = CryptoStorageManager();
  final connectivityManager = ConnectivityManager();

  final nullAccount = PublicData(
      keyId: "",
      creationDate: 0,
      walletName: "",
      address: "",
      isWatchOnly: false);
  bool isDarkMode = true;
  bool isHidden = false;
  bool isTotalBalanceUpdated = false;

  double totalBalanceUsd = 0;
  double balanceOfAllAccounts = 0;
  String searchQuery = "";

  final List<Map<String, dynamic>> actionsData = [
    {'icon': LucideIcons.moveUpRight, 'page': 'send', 'name': 'Send'},
    {'icon': LucideIcons.moveDownLeft, 'page': 'receive', 'name': 'Receive'},
    {'icon': LucideIcons.plus, 'page': 'add_token', 'name': 'Add crypto'},
    {'icon': LucideIcons.ellipsis, 'page': 'more', 'name': 'More'},
  ];
  final List<Map<String, dynamic>> options = [
    {'icon': LucideIcons.eye, 'name': 'Hide Balance'},
    {'icon': LucideIcons.send, 'name': 'Join Telegram'},
    {'icon': LucideIcons.messageCircle, 'name': 'Join Whatsapp'},
    {'icon': LucideIcons.settings, 'name': 'Settings'},
  ];

  @override
  void initState() {
    getIsHidden();

    getSavedTheme();
    getSavedWallets();
    calculateTotalBalanceOfAllWallets();

    loadData();
    super.initState();

    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> getSavedTheme() async {
    final manager = ColorsManager();
    final savedTheme = await manager.getDefaultTheme();
    setState(() {
      colors = savedTheme;
    });
  }

  Future<void> getIsHidden() async {
    try {
      final savedData =
          await publicDataManager.getDataFromPrefs(key: "isHidden");
      if (savedData != null) {
        if (savedData == "true") {
          setState(() {
            isHidden = true;
          });
        } else {
          setState(() {
            isHidden = false;
          });
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
          getCryptoData(account: account);
          break;
        }
      }
      if (currentAccount == null) {
        log("No account found");
        currentAccount = accounts[0];
        getCryptoData(account: accounts[0]);
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
            colors: colors,
            primaryColor: colors.primaryColor,
            context: context,
            message: "Name cannot be empty",
            iconColor: Colors.pinkAccent);
        Navigator.pop(context);
        return;
      }
      final wallet = accounts[index];
      final PublicData newWallet = PublicData(
          walletColor: wallet.walletColor,
          walletIcon: wallet.walletIcon,
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
              icon: Icons.check,
              colors: colors,
              primaryColor: colors.primaryColor,
              context: context,
              message: "Name edit was successful",
              iconColor: Colors.greenAccent);
        }
      } else {
        if (mounted) {
          showCustomSnackBar(
              icon: Icons.check,
              colors: colors,
              primaryColor: colors.primaryColor,
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

  Future<void> editVisualData(
      {Color? color, required int index, IconData? icon}) async {
    try {
      final wallet = accounts[index];
      final PublicData newWallet = PublicData(
          walletColor: color ?? wallet.walletColor,
          walletIcon: icon ?? wallet.walletIcon,
          isWatchOnly: wallet.isWatchOnly,
          address: wallet.address,
          walletName: wallet.walletName,
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
              icon: Icons.check,
              colors: colors,
              primaryColor: colors.primaryColor,
              context: context,
              message: "Data was successful",
              iconColor: Colors.greenAccent);
        }
      } else {
        if (mounted) {
          showCustomSnackBar(
              icon: Icons.check,
              colors: colors,
              primaryColor: colors.primaryColor,
              context: context,
              message: "Data edit failed",
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
          colors: colors,
          context: context,
          handleSubmit: (password) async {
            final savedPassword = await web3Manager.getSavedPassword();

            if (password.trim() == savedPassword!.trim()) {
              final currentList = accounts;
              if (currentList[index].keyId == currentAccount?.keyId &&
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
                      colors: colors,
                      primaryColor: colors.primaryColor,
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
                      colors: colors,
                      primaryColor: colors.primaryColor,
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
                  colors: colors,
                  primaryColor: colors.primaryColor,
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

  Future<void> calculateTotalBalanceOfAllWallets() async {
    try {
      final savedData = await web3Manager.getPublicData();
      List<PublicData> wallets = [];
      double totalBalance = 0;

      final lastAccount = await encryptService.getLastConnectedAddress();

      if (savedData != null && lastAccount != null) {
        for (final account in savedData) {
          final newAccount = PublicData.fromJson(account);
          setState(() {
            wallets.add(newAccount);
          });
        }
      }

      if (wallets.isNotEmpty) {
        for (final wallet in wallets) {
          final dataName = "cryptoAndBalance/${wallet.address}";

          final savedData =
              await publicDataManager.getDataFromPrefs(key: dataName);
          if (savedData != null) {
            List<dynamic> savedDataString = json.decode(savedData);
            for (final balance in savedDataString) {
              totalBalance += balance["balanceUsd"] ?? 0;
            }
            isTotalBalanceUpdated = true;
          }
        }
      }

      setState(() {
        balanceOfAllAccounts = totalBalance;
      });
    } catch (e) {
      logError('Error getting saved wallets: $e');
    }
  }

  Future<void> silentUpdate() async {
    try {
      final savedData = await web3Manager.getPublicData();
      List<PublicData> wallets = [];

      final lastAccount = await encryptService.getLastConnectedAddress();

      if (savedData != null && lastAccount != null) {
        for (final account in savedData) {
          final newAccount = PublicData.fromJson(account);
          setState(() {
            wallets.add(newAccount);
          });
        }
      }
      if (wallets.isNotEmpty) {
        for (final wallet in wallets) {
          if (!mounted) {
            log("The wallet is not mounted");
            return;
          }
          List<Crypto> cryptosList = [];
          List<Crypto> enabledCryptos = [];
          List<Balance> cryptoBalance = [];
          List<Crypto> availableCryptos = [];
          final dataName = "cryptoAndBalance/${wallet.address}";

          final savedCrypto =
              await cryptoStorageManager.getSavedCryptos(wallet: wallet);

          if (savedCrypto == null) {
            await cryptoStorageManager.saveListCrypto(
                cryptos: cryptos, wallet: wallet);
            cryptosList = cryptos;
          } else {
            cryptosList = savedCrypto;
          }

          if (cryptosList.isNotEmpty) {
            enabledCryptos =
                cryptosList.where((c) => c.canDisplay == true).toList();

            availableCryptos = [];

            final results =
                await Future.wait(enabledCryptos.map((crypto) async {
              final balance =
                  await web3InteractManager.getBalance(wallet, crypto);
              final trend = await priceManager.checkCryptoTrend(
                  crypto.binanceSymbol ?? "${crypto.symbol}USDT");
              final cryptoPrice = await priceManager.getPriceUsingBinanceApi(
                  crypto.binanceSymbol ?? "${crypto.symbol}USDT");
              final balanceUsd = cryptoPrice * balance;

              return Balance(
                crypto: crypto,
                balanceUsd: balanceUsd,
                balanceCrypto: balance,
                cryptoTrendPercent: trend["percent"] ?? 0,
                cryptoPrice: cryptoPrice,
              );
            }));
            cryptoBalance.addAll(results);
            availableCryptos.addAll(enabledCryptos);
            cryptoBalance
                .sort((a, b) => (b.balanceUsd).compareTo(a.balanceUsd));

            final cryptoListString =
                cryptoBalance.map((c) => c.toJson()).toList();

            await publicDataManager.saveDataInPrefs(
                data: json.encode(cryptoListString), key: dataName);
          }
        }
      }
    } catch (e) {
      logError('Error silent update: $e');
    }
  }

  Future<void> showPrivateData(int index) async {
    try {
      final wallet = accounts[index];
      if (wallet.isWatchOnly) {
        Navigator.pop(context);
        showCustomSnackBar(
            colors: colors,
            primaryColor: colors.primaryColor,
            context: context,
            message: "This is a watch-only wallet.",
            iconColor: Colors.pinkAccent);
        return;
      }
      String userPassword = "";
      final result = await showPinModalBottomSheet(
          colors: colors,
          context: context,
          handleSubmit: (password) async {
            final savedPassword = await web3Manager.getSavedPassword();

            if (password.trim() == savedPassword!.trim()) {
              userPassword = password.trim();

              return PinSubmitResult(success: false, repeat: false);
            } else {
              if (mounted) {
                showCustomSnackBar(
                    colors: colors,
                    primaryColor: colors.primaryColor,
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
      } else {
        if (mounted) {
          showCustomSnackBar(
              colors: colors,
              primaryColor: colors.primaryColor,
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
      Navigator.pop(context);

      final wallet = accounts[index];
      setState(() {
        currentAccount = wallet;
        totalBalanceUsd = 0;
      });

      final changeResult = await web3Manager.saveLastAccount(wallet.address);
      if (changeResult) {
        if (mounted) {
          await Future.wait([
            getCryptoData(account: wallet),
            calculateTotalBalanceOfAllWallets(),
          ]);

          /*  showCustomSnackBar(
              context: context,
              icon: Icons.check_circle,
              message: "Wallet changed successfully",
              iconColor: Colors.greenAccent);
          getTotalBalance();
          Navigator.pop(context); */
        }
      } else {
        if (mounted) {
          showCustomSnackBar(
              colors: colors,
              primaryColor: colors.primaryColor,
              context: context,
              message: "Wallet change failed",
              iconColor: Colors.pinkAccent);
        }
      }
    } catch (e) {
      logError(e.toString());
      showCustomSnackBar(
          context: context,
          message: "$e",
          primaryColor: colors.primaryColor,
          colors: colors);
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

  Future<double> getBalanceUsd(
      {required Crypto crypto, required PublicData account}) async {
    try {
      if (crypto.type == CryptoType.token && crypto.contractAddress == null) {
        return 0;
      }
      final symbol = crypto.binanceSymbol ?? "";

      final price = await getPrice(symbol);

      final balanceEth = await web3InteractManager.getBalance(account, crypto);

      publicDataManager.saveDataInPrefs(
          data: balanceEth.toString(),
          key: "${account.address}/lastBalanceEth");

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

  Future<void> getCryptoData({required PublicData account}) async {
    try {
      final dataName = "cryptoAndBalance/${account.address}";
      final List<Crypto> standardCrypto = cryptos;
      List<Crypto> cryptosList = [];
      List<Crypto> enabledCryptos = [];
      List<Balance> cryptoBalance = [];
      List<Crypto> availableCryptos = [];
      double userBalanceUsd = 0;

      final savedData = await publicDataManager.getDataFromPrefs(key: dataName);
      if (savedData != null) {
        List<Balance> balances = [];
        List<dynamic> savedDataString = json.decode(savedData);
        for (final balance in savedDataString) {
          final newBalance = Balance.fromJson(balance);
          balances.add(newBalance);
          userBalanceUsd += newBalance.balanceUsd;
          availableCryptos.add(newBalance.crypto);
          if (balances.isNotEmpty) {
            setState(() {
              reorganizedCrypto = availableCryptos;
              cryptosAndBalance = balances;
              totalBalanceUsd = userBalanceUsd;
              isLoading = false;
            });
          }
        }
      }
      final savedCrypto =
          await cryptoStorageManager.getSavedCryptos(wallet: account);

      if (savedCrypto == null) {
        await cryptoStorageManager.saveListCrypto(
            cryptos: standardCrypto, wallet: account);
        cryptosList = standardCrypto;
      } else {
        cryptosList = savedCrypto;
      }
      if (cryptosList.isNotEmpty) {
        enabledCryptos =
            cryptosList.where((c) => c.canDisplay == true).toList();
        userBalanceUsd = 0;
        availableCryptos = [];

        final results = await Future.wait(enabledCryptos.map((crypto) async {
          final balance = await web3InteractManager.getBalance(account, crypto);
          final trend = await priceManager
              .checkCryptoTrend(crypto.binanceSymbol ?? "${crypto.symbol}USDT");
          final cryptoPrice = await priceManager.getPriceUsingBinanceApi(
              crypto.binanceSymbol ?? "${crypto.symbol}USDT");
          final balanceUsd = cryptoPrice * balance;

          return {
            "cryptoBalance": Balance(
              crypto: crypto,
              balanceUsd: balanceUsd,
              balanceCrypto: balance,
              cryptoTrendPercent: trend["percent"] ?? 0,
              cryptoPrice: cryptoPrice,
            ),
            "availableCrypto": crypto,
            "balanceUsd": balanceUsd
          };
        }));

        cryptoBalance.addAll(results.map((r) => r["cryptoBalance"] as Balance));
        availableCryptos
            .addAll(results.map((r) => r["availableCrypto"] as Crypto));

        userBalanceUsd +=
            results.fold(0.0, (sum, r) => sum + (r["balanceUsd"] as double));

        setState(() {
          cryptosAndBalance = cryptoBalance;
          totalBalanceUsd = userBalanceUsd;
          reorganizedCrypto = availableCryptos;
          isLoading = false;
        });

        cryptoBalance.sort((a, b) => (b.balanceUsd).compareTo(a.balanceUsd));
        setState(() {
          cryptosAndBalance = cryptoBalance;
        });

        final cryptoListString = cryptoBalance.map((c) => c.toJson()).toList();

        await publicDataManager.saveDataInPrefs(
            data: json.encode(cryptoListString), key: dataName);
      }
    } catch (e) {
      logError(e.toString());
    }
  }

  void showReceiveModal() {
    showCryptoModal(
        colors: colors,
        context: context,
        primaryColor: colors.primaryColor,
        textColor: colors.textColor,
        surfaceTintColor: colors.grayColor.withOpacity(0.6),
        reorganizedCrypto: reorganizedCrypto,
        route: Routes.receiveScreen);
  }

  void showSendModal() {
    showCryptoModal(
        colors: colors,
        context: context,
        primaryColor: colors.primaryColor,
        textColor: colors.textColor,
        surfaceTintColor: colors.grayColor.withOpacity(0.6),
        reorganizedCrypto: reorganizedCrypto,
        route: Routes.sendScreen);
  }

  void showOptionsModal() async {
    await showDialogWithBar(
        context: context,
        enableDrag: true,
        builder: (ctx) {
          return ListView.builder(
              shrinkWrap: true,
              itemCount: options.length,
              itemBuilder: (BuildContext lisCryptoCtx, int index) {
                final opt = options[index];
                return Material(
                  color: Colors.transparent,
                  child: ListTile(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    onTap: () {
                      if (index == options.length - 1) {
                        Navigator.pushNamed(context, Routes.settings);
                      } else if (index == 1) {
                        launchUrl(Uri.parse("https://t.me/eternalprotocol"));
                      } else if (index == 2) {
                        launchUrl(Uri.parse(
                            "https://www.whatsapp.com/channel/0029Vb2TpR9HrDZWVEkhWz21"));
                      } else if (index == 0) {
                        toggleHidden();
                      }
                    },
                    leading: Icon(
                      opt["icon"],
                      color: colors.textColor,
                    ),
                    title: Text(
                      opt["name"],
                      style: customTextStyle(
                          color: colors.textColor, fontWeight: FontWeight.bold),
                    ),
                  ),
                );
              });
        },
        colors: colors);
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    // double height = MediaQuery.of(context).size.height;
    if (reorganizedCrypto.isEmpty) {
      return Container(
        decoration: BoxDecoration(color: colors.primaryColor),
        child: Center(
          child: SizedBox(
            height: 30,
            width: 30,
            child: CircularProgressIndicator(
              color: colors.themeColor,
            ),
          ),
        ),
      );
    }
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: colors.primaryColor,
      floatingActionButton: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
            color: colors.grayColor, borderRadius: BorderRadius.circular(10)),
        child: IconButton(
            onPressed: () {
              _refreshIndicatorKey.currentState?.show();
            },
            icon: Icon(
              Icons.refresh,
              color: colors.textColor.withOpacity(0.5),
            )),
      ),
      drawer: MainDrawer(
          isDarkMode: isDarkMode,
          toggleMode: () {},
          showSendModal: showSendModal,
          showReceiveModal: showReceiveModal,
          profileImage: _profileImage,
          backgroundImage: _backgroundImage,
          userName: userName,
          scaffoldKey: _scaffoldKey,
          primaryColor: colors.primaryColor,
          textColor: colors.textColor,
          surfaceTintColor: colors.secondaryColor),
      appBar: CustomAppBar(
          totalBalanceUsd: totalBalanceUsd,
          availableCryptos: reorganizedCrypto,
          isTotalBalanceUpdated: isTotalBalanceUpdated,
          editVisualData: editVisualData,
          colors: colors,
          isHidden: isHidden,
          balanceOfAllAccounts: balanceOfAllAccounts,
          profileImage: _profileImage,
          scaffoldKey: _scaffoldKey,
          showPrivateData: showPrivateData,
          reorderList: reorderList,
          secondaryColor: colors.themeColor,
          changeAccount: changeWallet,
          deleteWallet: deleteWallet,
          editWalletName: editWalletName,
          currentAccount: currentAccount ?? nullAccount,
          accounts: accounts,
          primaryColor: colors.primaryColor,
          textColor: colors.textColor,
          surfaceTintColor: colors.secondaryColor),
      body: RefreshIndicator(
          color: colors.themeColor,
          backgroundColor: colors.textColor.withOpacity(0.8),
          key: _refreshIndicatorKey,
          triggerMode: RefreshIndicatorTriggerMode.anywhere,
          onRefresh: () async {
            await vibrate(duration: 10);
            if (currentAccount != null) {
              await getCryptoData(account: currentAccount ?? accounts[0]);
            }
          },
          child: NotificationListener<ScrollNotification>(
            child: NestedScrollView(
              headerSliverBuilder:
                  (BuildContext context, bool innerBoxIsScrolled) {
                return [
                  SliverToBoxAdapter(
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
                                  style:
                                      customTextStyle(color: colors.textColor),
                                ),
                                IconButton(
                                    onPressed: toggleHidden,
                                    icon: Icon(
                                      isHidden
                                          ? LucideIcons.eyeClosed
                                          : Icons.remove_red_eye_outlined,
                                      color: colors.textColor,
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
                                        color: colors.textColor,
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
                            children:
                                List.generate(actionsData.length, (index) {
                              final action = actionsData[index];
                              return ActionsWidgets(
                                onTap: () {
                                  if (index == 1) {
                                    showReceiveModal();
                                  } else if (index == 0) {
                                    showSendModal();
                                  } else if (index == 3) {
                                    showOptionsModal();
                                  } else if (index == 2) {
                                    Navigator.pushNamed(
                                        context, Routes.addCrypto);
                                  }
                                },
                                text: action["name"],
                                actIcon: action["icon"],
                                textColor: colors.textColor,
                                actionsColor: colors.grayColor.withOpacity(0.3),
                              );
                            })),
                      ),
                    ],
                  )),
                  SliverPersistentHeader(
                    key: ValueKey(colors.primaryColor),
                    pinned: true,
                    delegate: _SliverAppBarDelegate(
                      TabBar(
                        dividerColor: Colors.transparent,
                        controller: _tabController,
                        labelColor: colors.textColor,
                        unselectedLabelColor: colors.grayColor.withOpacity(0.7),
                        indicatorColor: colors.themeColor,
                        tabs: const [
                          Tab(text: 'Crypto'),
                          Tab(text: 'Nfts'),
                        ],
                      ),
                      primaryColor: colors.primaryColor,
                    ),
                  ),
                ];
              },
              body: TabBarView(
                  physics: NeverScrollableScrollPhysics(), // désactive le swipe

                  controller: _tabController,
                  children: [
                    SingleChildScrollView(
                      child: isLoading
                          ? Center(
                              child: Container(
                                height:
                                    MediaQuery.of(context).size.height * 0.3,
                                alignment: Alignment.center,
                                padding: const EdgeInsets.all(10),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  spacing: 10,
                                  children: [
                                    SizedBox(
                                      width: 15,
                                      height: 15,
                                      child: CircularProgressIndicator(
                                        color: colors.themeColor,
                                      ),
                                    ),
                                    Text(
                                      "Initializing ...",
                                      style: customTextStyle(
                                          color: colors.textColor),
                                    )
                                  ],
                                ),
                              ),
                            )
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: List.generate(
                                  cryptosAndBalance.length + 1, (index) {
                                if (index == cryptosAndBalance.length) {
                                  return Padding(
                                    padding: const EdgeInsets.all(10),
                                    child: Align(
                                        alignment: Alignment.center,
                                        child: InkWell(
                                          borderRadius:
                                              BorderRadius.circular(40),
                                          splashColor: Colors.transparent,
                                          onTap: () {
                                            Navigator.pushNamed(
                                                context, Routes.addCrypto);
                                          },
                                          child: Row(
                                            spacing: 15,
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Icon(
                                                LucideIcons.slidersVertical,
                                                color: colors.textColor
                                                    .withOpacity(0.7),
                                              ),
                                              Text(
                                                "Manage cryptos",
                                                style: customTextStyle(
                                                    color: colors.textColor
                                                        .withOpacity(0.7)),
                                              )
                                            ],
                                          ),
                                        )),
                                  );
                                }
                                final crypto = cryptosAndBalance[index];

                                return Material(
                                  color: Colors.transparent,
                                  child: ListTile(
                                    splashColor:
                                        colors.textColor.withOpacity(0.05),
                                    onTap: () {
                                      log("Crypto id ${crypto.crypto.cryptoId}");
                                      Navigator.pushNamed(
                                          context, Routes.walletOverview,
                                          arguments: ({
                                            "id": crypto.crypto.cryptoId
                                          }));
                                    },
                                    leading: CryptoPicture(
                                        crypto: crypto.crypto,
                                        size: 40,
                                        colors: colors),
                                    title: Row(
                                      spacing: 10,
                                      children: [
                                        Text(
                                          crypto.crypto.symbol,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: customTextStyle(
                                            color: colors.textColor,
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        if (crypto.crypto.type ==
                                            CryptoType.token)
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 10, vertical: 2),
                                            decoration: BoxDecoration(
                                                color: colors.grayColor
                                                    .withOpacity(0.9)
                                                    .withOpacity(0.2),
                                                borderRadius:
                                                    BorderRadius.circular(20)),
                                            child: Text(
                                                "${crypto.crypto.network?.name}",
                                                style: customTextStyle(
                                                    color: colors.textColor
                                                        .withOpacity(0.8),
                                                    fontSize: 10)),
                                          )
                                      ],
                                    ),
                                    subtitle: Row(
                                      spacing: 10,
                                      children: [
                                        Text("\$${crypto.cryptoPrice}",
                                            style: customTextStyle(
                                              color: colors.textColor
                                                  .withOpacity(0.6),
                                              fontSize: 16,
                                            )),
                                        if (crypto.cryptoTrendPercent != 0)
                                          Text(
                                            " ${(crypto.cryptoTrendPercent).toStringAsFixed(2)}%",
                                            style: customTextStyle(
                                              color:
                                                  crypto.cryptoTrendPercent > 0
                                                      ? colors.greenColor
                                                      : colors.redColor,
                                              fontSize: 14,
                                            ),
                                          ),
                                      ],
                                    ),
                                    trailing: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: [
                                        ConstrainedBox(
                                          constraints: BoxConstraints(
                                              maxWidth: width * 0.3),
                                          child: Text(
                                              isHidden
                                                  ? "***"
                                                  : "${formatter.format(crypto.balanceCrypto).split('0').length - 1 > 6 ? 0 : formatter.format(crypto.balanceCrypto)}",
                                              overflow: TextOverflow.clip,
                                              maxLines: 1,
                                              style: customTextStyle(
                                                  color: colors.textColor,
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold)),
                                        ),
                                        Text(
                                            isHidden
                                                ? "***"
                                                : "\$ ${crypto.balanceUsd.toStringAsFixed(3)}",
                                            style: customTextStyle(
                                                color: colors.textColor
                                                    .withOpacity(0.6),
                                                fontSize: 14))
                                      ],
                                    ),
                                  ),
                                );
                              }),
                            ),
                    ),
                    Container(
                      color: Colors.transparent,
                      child: Center(
                        child: Text(
                          'Coming soon',
                          style: customTextStyle(color: colors.textColor),
                        ),
                      ),
                    ),
                  ]),
            ),
          )),
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverAppBarDelegate(this._tabBar, {required this.primaryColor});

  final TabBar _tabBar;
  final Color primaryColor;

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: primaryColor,
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}
