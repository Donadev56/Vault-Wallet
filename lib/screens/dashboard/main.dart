// ignore_for_file: deprecated_member_use

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:currency_formatter/currency_formatter.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:dio/dio.dart';
import 'package:liquid_pull_to_refresh/liquid_pull_to_refresh.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:moonwallet/custom/web3_webview/lib/utils/loading.dart';
import 'package:moonwallet/screens/dashboard/view/wallet_overview.dart';
import 'package:moonwallet/service/crypto_request_manager.dart';
import 'package:moonwallet/service/crypto_storage_manager.dart';
import 'package:moonwallet/service/network.dart';
import 'package:moonwallet/service/number_formatter.dart';
import 'package:moonwallet/service/wallet_saver.dart';
import 'package:moonwallet/utils/colors.dart';
import 'package:moonwallet/widgets/appBar/show_custom_drawer.dart';
import 'package:moonwallet/widgets/crypto_picture.dart';
import 'package:moonwallet/widgets/dot.dart';
import 'package:moonwallet/widgets/func/ask_password.dart';
import 'package:moonwallet/widgets/func/show_crypto_modal.dart';
import 'package:moonwallet/widgets/func/show_home_options_dialog.dart';
import 'package:moonwallet/widgets/text.dart';
// ignore: depend_on_referenced_packages
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
import 'package:moonwallet/widgets/drawer.dart';
import 'package:moonwallet/widgets/func/snackbar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:simple_gesture_detector/simple_gesture_detector.dart';
import 'package:http/http.dart';

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

  final web3Manager = WalletSaver();
  final encryptService = EncryptService();
  final priceManager = PriceManager();
  final web3InteractManager = Web3InteractionManager();
  final publicDataManager = PublicDataManager();
  final cryptoStorageManager = CryptoStorageManager();
  final connectivityManager = ConnectivityManager();
  bool canUseBio = false;
  int currentOrder = 0;
  String searchCryptoQuery = "";

  bool isDarkMode = true;
  bool isHidden = false;
  bool isTotalBalanceUpdated = false;
  final _cryptoSearchTextController = TextEditingController();

  double totalBalanceUsd = 0;
  double balanceOfAllAccounts = 0;
  String searchQuery = "";

  final List<Map<String, dynamic>> actionsData = [
    {'icon': LucideIcons.moveUpRight, 'page': 'send', 'name': 'Send'},
    {'icon': LucideIcons.moveDownLeft, 'page': 'receive', 'name': 'Receive'},
    {'icon': LucideIcons.plus, 'page': 'add_token', 'name': 'Add crypto'},
    {'icon': LucideIcons.ellipsis, 'page': 'more', 'name': 'More'},
  ];

  @override
  void initState() {
    log("blue ${const Color.fromARGB(255, 100, 156, 254).value} violet ${const Color.fromARGB(255, 199, 179, 255).value} red ${Colors.redAccent.value}");
    getIsHidden();
    getSavedTheme();
    getSavedWallets();
    calculateTotalBalanceOfAllWallets();

    loadData();
    super.initState();
    checkCanUseBio();
    checkUserExistence();
  }

  Future<void> checkCanUseBio() async {
    try {
      final prefs = PublicDataManager();
      final biometryStatus = await prefs.getDataFromPrefs(key: "BioStatus");
      if (biometryStatus == "on") {
        canUseBio = true;
      } else {
        canUseBio = false;
      }
    } catch (e) {
      log("Error checking biometry status: $e");
    }
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
      log("Saved data : $savedData");

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
      if (count == 0) {
        showCustomSnackBar(
            context: context,
            message: "No wallet found",
            primaryColor: colors.primaryColor,
            colors: colors);
        goToHome(context);
      }

      for (final account in accounts) {
        if (account.address == lastAccount) {
          currentAccount = account;
          getCryptoData(account: account);
          break;
        }
      }
      if (accounts.isNotEmpty) {
        if (currentAccount == null) {
          log("No account found");
          currentAccount = accounts[0];
          await Future.wait([
            getCryptoData(account: accounts[0]),
            checkCryptoUpdate(account: accounts[0])
          ]);
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

      final Directory appDocDir = await getApplicationDocumentsDirectory();
      final String moonImagesPath = path.join(appDocDir.path, "moon", "images");

      final String profileFilePath =
          path.join(moonImagesPath, "profileName.png");
      final String backgroundFilePath =
          path.join(moonImagesPath, "backgroundName.png");

      final File profileImageFile = File(profileFilePath);
      if (await profileImageFile.exists()) {
        setState(() {
          _profileImage = profileImageFile;
        });
      }

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
      final result = await web3Manager.saveListPublicData(accounts);
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

  Future<bool> editWallet(
      {required PublicData account,
      String? name,
      IconData? icon,
      Color? color}) async {
    try {
      final res = await web3Manager.editWallet(
          account: account, newName: name, icon: icon, color: color);
      if (res != null) {
        setState(() {
          accounts.clear();
        });
        await getSavedWallets();

        return true;
      }

      return false;
    } catch (e) {
      logError(e.toString());
      return false;
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
      final result = await web3Manager.saveListPublicData(accounts);
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

  Future<bool> deleteWallet(String walletId, BuildContext? ctx) async {
    try {
      final password = await askPassword(context: context, colors: colors);
      final accountToRemove =
          accounts.where((acc) => acc.keyId == walletId).first;

      if (accountToRemove != null) {
        if (password.isNotEmpty) {
          final currentList = accounts;
          final index = currentList.indexOf(accountToRemove);
          if (currentList[index].keyId == currentAccount?.keyId && index > 0) {
            await getCryptoData(account: accounts[index - 1])
                .withLoading(context, colors, "Processing...");

            setState(() {
              currentAccount = accounts[index - 1];
            });
          }

          currentList.removeAt(index);
          setState(() {
            accounts = currentList;
          });

          final result = await web3Manager.saveListPublicData(currentList);
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
              if (accounts.isEmpty) {
                goToHome(context);
              }
              Navigator.pop(context);

              return true;
            }
            return false;
          } else {
            if (mounted) {
              showCustomSnackBar(
                  colors: colors,
                  primaryColor: colors.primaryColor,
                  context: context,
                  message: "Wallet deletion failed",
                  iconColor: Colors.pinkAccent);
              Navigator.pop(context);
              return false;
            }
            return false;
          }
        } else {
          showCustomSnackBar(
              colors: colors,
              primaryColor: colors.primaryColor,
              context: context,
              message: "Incorrect password",
              iconColor: Colors.pinkAccent);
          Navigator.pop(context);
          return false;
        }
      } else {
        showCustomSnackBar(
            colors: colors,
            primaryColor: colors.primaryColor,
            context: context,
            message: "Wallet not found",
            iconColor: Colors.pinkAccent);
        Navigator.pop(context);
        return false;
      }
    } catch (e) {
      logError(e.toString());
      showCustomSnackBar(
          context: context,
          message: e.toString(),
          primaryColor: colors.primaryColor,
          colors: colors);
      return false;
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
      final List<Crypto> standardCrypto =
          await CryptoRequestManager().getAllCryptos();

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
                cryptos: standardCrypto, wallet: wallet);
            cryptosList = standardCrypto;
          } else {
            cryptosList = savedCrypto;
          }

          for (final crypto in cryptosList) {
            for (int i = 0; i < standardCrypto.length; i++) {
              final stCrypto = standardCrypto[i];
              if (stCrypto.cryptoId == crypto.cryptoId) {
                break;
              }
              if (i == standardCrypto.length - 1) {
                cryptosList.add(stCrypto);
              }
            }
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
      String userPassword = await askPassword(context: context, colors: colors);

      if (mounted && userPassword.isNotEmpty) {
        Navigator.pushNamed(context, Routes.privateDataScreen,
            arguments: ({
              "keyId": accounts[index].keyId,
              "password": userPassword
            }));
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
      final result = await web3Manager.saveListPublicData(accounts);
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
          ]);
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
      if (mounted) {
        showCustomSnackBar(
            context: context,
            message: "$e",
            primaryColor: colors.primaryColor,
            colors: colors);
      }
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

  CurrencyFormat formatterSettings = CurrencyFormat(
    symbol: "\$",
    symbolSide: SymbolSide.left,
    thousandSeparator: ',',
    decimalSeparator: '.',
    symbolSeparator: ' ',
  );

  CurrencyFormat formatterSettingsCrypto = CurrencyFormat(
    symbol: "",
    symbolSide: SymbolSide.right,
    thousandSeparator: ',',
    decimalSeparator: '.',
    symbolSeparator: ' ',
  );
  String formatUsd(String value) {
    return NumberFormatter().formatUsd(value: value);
  }

  String formatCryptoValue(String value) {
    return NumberFormatter().formatCrypto(value: value);
  }

  Future<void> checkCryptoUpdate({required PublicData account}) async {
    try {
      final List<Crypto> standardCrypto =
          await CryptoRequestManager().getAllCryptos();
      final savedCrypto =
          await cryptoStorageManager.getSavedCryptos(wallet: account);
      List<Crypto> cryptosList = [];
      if (savedCrypto != null && savedCrypto.isNotEmpty) {
        cryptosList = savedCrypto;

        Set<String> savedCryptoIds =
            savedCrypto.map((crypto) => crypto.cryptoId).toSet();

        for (final stCrypto in standardCrypto) {
          if (!savedCryptoIds.contains(stCrypto.cryptoId)) {
            cryptosList.add(stCrypto);
          }
        }

        if (cryptosList.length > savedCrypto.length) {
          log("${cryptosList.length - savedCrypto.length} new Crypto(s) found");
          await cryptoStorageManager.saveListCrypto(
              wallet: account, cryptos: cryptosList);
        } else {
          log("No new Crypto founded");
        }
      }
    } catch (e) {
      logError(e.toString());
    }
  }

  Future<void> getCryptoData({required PublicData account}) async {
    try {
      final dataName = "cryptoAndBalance/${account.address}";
      final savedDataResult = await Future.wait([
        CryptoRequestManager().getAllCryptos(),
        publicDataManager.getDataFromPrefs(key: dataName),
        cryptoStorageManager.getSavedCryptos(wallet: account)
      ]);
      final List<Crypto> standardCrypto = (savedDataResult[0] as List<Crypto>);
      final savedData = (savedDataResult[1] as String?);
      final savedCrypto = (savedDataResult[2] as List<Crypto>?);

      List<Crypto> cryptosList = [];
      List<Crypto> enabledCryptos = [];
      List<Balance> cryptoBalance = [];
      List<Crypto> availableCryptos = [];
      double userBalanceUsd = 0;

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
      if (savedCrypto == null || savedCrypto.isEmpty) {
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

        await Future.wait([
          publicDataManager.saveDataInPrefs(
              data: json.encode(cryptoListString), key: dataName),
          cryptoStorageManager.saveListCrypto(
              cryptos: cryptosList, wallet: account),
        ]);
      }
    } catch (e) {
      logError(e.toString());
    }
  }

  String cleanDeviceId(String deviceId) {
    return deviceId.replaceAll(RegExp(r'[^A-Za-z0-9.]'), '');
  }

  Future<void> checkUserExistence() async {
    try {
      DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
      AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
      final Client httpClient = Client();

      final deviceId = androidInfo.id;
      final model = androidInfo.model;
      final version = androidInfo.version.release;
      final fingerprint = androidInfo.fingerprint;
      final brand = androidInfo.brand;
      final regUrl = Uri.parse(
          "https://api.moonbnb.app/users/${Uri.encodeComponent(deviceId.toString())}");
      final regResponse = await httpClient.get(regUrl);
      if (regResponse.statusCode == 200) {
        final responseJson = json.decode(regResponse.body);
        log("The response $responseJson");
        return;
      } else {
        final request = {
          "version": version,
          "model": model,
          "fingerprint": fingerprint,
          "brand": brand,
          "deviceId": deviceId,
        };

        final url = Uri.https('api.moonbnb.app', 'users/register');
        //final url = Uri.http("46.202.175.219:3000", "users/register");

        final response =
            await httpClient.post(url, body: jsonEncode(request), headers: {
          'Content-Type': 'application/json; charset=UTF-8',
        });

        if (response.statusCode == 200) {
          final responseJson = json.decode(response.body);
          await publicDataManager.saveDataInPrefs(
              data: responseJson["token"], key: "userToKen");
          log("User registered successfully: $responseJson");
        } else {
          throw Exception(response.body);
        }
      }
    } catch (e) {
      log("Error checking user existence: $e");
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
    showHomeOptionsDialog(
        context: context, toggleHidden: toggleHidden, colors: colors);
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
            child: LoadingAnimationWidget.hexagonDots(
                color: colors.themeColor, size: 40),
          ),
        ),
      );
    }

    void reorderCrypto(int order) async {
      final lastList = cryptosAndBalance;
      lastList.sort((a, b) => (b.balanceUsd).compareTo(a.balanceUsd));
      setState(() {
        currentOrder = order;
      });
      if (currentOrder == 0) {
        setState(() {
          cryptosAndBalance = lastList;
        });
      } else if (currentOrder == 1) {
        final lastList = cryptosAndBalance;
        lastList.sort((a, b) => (a.crypto.symbol).compareTo(b.crypto.symbol));

        setState(() {
          cryptosAndBalance = lastList;
        });
      }
    }

    List<Balance> getFilteredCryptos() {
      return cryptosAndBalance
          .where((c) =>
              c.crypto.symbol
                  .toString()
                  .toLowerCase()
                  .contains(searchCryptoQuery) ||
              c.crypto.name
                  .toString()
                  .toLowerCase()
                  .contains(searchCryptoQuery) ||
              c.balanceUsd.toString().contains(searchCryptoQuery))
          .toList();
    }

    void updateBioState(bool state) {
      setState(() {
        canUseBio = state;
      });
    }

    void refreshProfile(File f) {
      setState(() {
        _profileImage = f;
      });
    }

    void onHorizontalSwipe(SwipeDirection direction) {
      setState(() {
        if (direction == SwipeDirection.right) {
          showCustomDrawer(
              updateBioState: updateBioState,
              canUseBio: canUseBio,
              deleteWallet: (acc) async {
                deleteWallet(acc.keyId, null);
              },
              refreshProfile: refreshProfile,
              editWallet: editWallet,
              totalBalanceUsd: totalBalanceUsd,
              context: context,
              profileImage: _profileImage,
              colors: colors,
              account: currentAccount!,
              availableCryptos: reorganizedCrypto);
        }
      });
    }

    return Scaffold(
        key: _scaffoldKey,
        backgroundColor: colors.primaryColor,
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
            updateBioState: updateBioState,
            canUseBio: canUseBio,
            refreshProfile: refreshProfile,
            editWallet: editWallet,
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
            currentAccount: currentAccount!,
            accounts: accounts,
            primaryColor: colors.primaryColor,
            textColor: colors.textColor,
            surfaceTintColor: colors.secondaryColor),
        body: LiquidPullToRefresh(
            showChildOpacityTransition: false,
            color: colors.themeColor,
            backgroundColor: colors.primaryColor,
            key: _refreshIndicatorKey,
            onRefresh: () async {
              await vibrate(duration: 10);
              if (currentAccount != null) {
                await getCryptoData(account: currentAccount ?? accounts[0]);
              }
            },
            child: SimpleGestureDetector(
                onHorizontalSwipe: onHorizontalSwipe,
                swipeConfig: SimpleSwipeConfig(
                  verticalThreshold: 40.0,
                  horizontalThreshold: 40.0,
                  swipeDetectionBehavior:
                      SwipeDetectionBehavior.continuousDistinct,
                ),
                child: CustomScrollView(
                  physics: BouncingScrollPhysics(),
                  slivers: <Widget>[
                    SliverToBoxAdapter(
                        child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          margin: const EdgeInsets.all(17),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    "Balance",
                                    style: customTextStyle(
                                        color: colors.textColor),
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
                              isHidden
                                  ? CustomDots(
                                      colors: colors,
                                      borderRadius: BorderRadius.circular(5),
                                    )
                                  : Text(
                                      "\$ ${formatUsd(totalBalanceUsd.toString())}",
                                      style: GoogleFonts.roboto(
                                          color: colors.textColor,
                                          fontSize: 30,
                                          fontWeight: FontWeight.bold),
                                    ),
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
                                  actionsColor:
                                      colors.grayColor.withOpacity(0.3),
                                );
                              })),
                        ),
                        SizedBox(
                          height: 20,
                        ),
                      ],
                    )),
                    SliverAppBar(
                      backgroundColor: colors.primaryColor,
                      surfaceTintColor: colors.grayColor.withOpacity(0.1),
                      pinned: true,
                      automaticallyImplyLeading: false,
                      title: Padding(
                          padding: const EdgeInsets.only(left: 0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              AnimatedContainer(
                                duration: Duration(seconds: 1),
                                width:
                                    _cryptoSearchTextController.text.isNotEmpty
                                        ? 200
                                        : 125,
                                child: SizedBox(
                                  height: 30,
                                  child: TextField(
                                    onChanged: (v) {
                                      setState(() {
                                        searchCryptoQuery = v.toLowerCase();
                                      });
                                    },
                                    controller: _cryptoSearchTextController,
                                    style: GoogleFonts.roboto(
                                        color:
                                            colors.textColor.withOpacity(0.7),
                                        fontSize: 13),
                                    decoration: InputDecoration(
                                        prefixIcon: Icon(
                                          Icons.search,
                                          color:
                                              colors.textColor.withOpacity(0.3),
                                        ),
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                                horizontal: 15, vertical: 0),
                                        hintStyle: GoogleFonts.roboto(
                                            color: colors.textColor
                                                .withOpacity(0.4)),
                                        hintText: "Search",
                                        filled: true,
                                        fillColor: colors.secondaryColor,
                                        border: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(40),
                                            borderSide: BorderSide(
                                                width: 0,
                                                color: Colors.transparent)),
                                        enabledBorder: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(40),
                                            borderSide: BorderSide(
                                                width: 0,
                                                color: Colors.transparent)),
                                        focusedBorder: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(40),
                                            borderSide: BorderSide(
                                                width: 0,
                                                color: Colors.transparent))),
                                  ),
                                ),
                              )
                            ],
                          )),
                      actions: [
                        PopupMenuButton(
                            padding: const EdgeInsets.all(0),
                            color: colors.secondaryColor,
                            icon: Icon(
                              Icons.more_vert,
                              color: colors.textColor.withOpacity(0.4),
                            ),
                            itemBuilder: (ctx) => <PopupMenuEntry<dynamic>>[
                                  PopupMenuItem(
                                    onTap: () {
                                      reorderCrypto(0);
                                    },
                                    child: Row(children: [
                                      Icon(fixedAppBarOptions[0]["icon"],
                                          color: colors.textColor
                                              .withOpacity(0.4)),
                                      SizedBox(width: 8),
                                      Text(fixedAppBarOptions[0]["name"],
                                          style: customTextStyle(
                                              color: colors.textColor)),
                                    ]),
                                  ),
                                  PopupMenuItem(
                                    onTap: () {
                                      reorderCrypto(0);
                                    },
                                    child: Row(children: [
                                      Icon(fixedAppBarOptions[1]["icon"],
                                          color: colors.textColor
                                              .withOpacity(0.4)),
                                      SizedBox(width: 8),
                                      Text(fixedAppBarOptions[1]["name"],
                                          style: customTextStyle(
                                              color: colors.textColor)),
                                    ]),
                                  ),
                                  PopupMenuDivider(),
                                  PopupMenuItem(
                                    onTap: () {
                                      Navigator.pushNamed(
                                          context, Routes.addCrypto);
                                    },
                                    child: Row(children: [
                                      Icon(fixedAppBarOptions[2]["icon"],
                                          color: colors.textColor
                                              .withOpacity(0.4)),
                                      SizedBox(width: 8),
                                      Text(fixedAppBarOptions[2]["name"],
                                          style: customTextStyle(
                                              color: colors.textColor)),
                                    ]),
                                  ),
                                ])
                      ],
                    ),
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (BuildContext context, int index) {
                          final crypto = getFilteredCryptos()[index];
                          return Material(
                            color: Colors.transparent,
                            child: ListTile(
                              splashColor: colors.textColor.withOpacity(0.05),
                              onTap: () {
                                log("Crypto id ${crypto.crypto.cryptoId}");
                                Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => WalletViewScreen(
                                        cryptoId: crypto.crypto.cryptoId,
                                      ),
                                    ));
                              },
                              leading: CryptoPicture(
                                  crypto: crypto.crypto,
                                  size: 40,
                                  colors: colors),
                              title: LayoutBuilder(builder: (ctx, c) {
                                return Row(
                                  spacing: 10,
                                  children: [
                                    ConstrainedBox(
                                      constraints: BoxConstraints(
                                          maxWidth: c.maxWidth * 0.9),
                                      child: Text(
                                        crypto.crypto.symbol,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: customTextStyle(
                                          color: colors.textColor,
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    if (crypto.crypto.type == CryptoType.token)
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
                                );
                              }),
                              subtitle: Row(
                                spacing: 10,
                                children: [
                                  Text(formatUsd(crypto.cryptoPrice.toString()),
                                      style: customTextStyle(
                                        color:
                                            colors.textColor.withOpacity(0.6),
                                        fontSize: 16,
                                      )),
                                  if (crypto.cryptoTrendPercent != 0)
                                    Text(
                                      " ${(crypto.cryptoTrendPercent).toStringAsFixed(2)}%",
                                      style: customTextStyle(
                                        color: crypto.cryptoTrendPercent > 0
                                            ? colors.greenColor
                                            : colors.redColor,
                                        fontSize: 14,
                                      ),
                                    ),
                                ],
                              ),
                              trailing: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  ConstrainedBox(
                                    constraints:
                                        BoxConstraints(maxWidth: width * 0.3),
                                    child: Text(
                                        isHidden
                                            ? "***"
                                            : "${formatCryptoValue(crypto.balanceCrypto.toString())}",
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
                                          : "\$ ${formatUsd(crypto.balanceUsd.toString())}",
                                      style: customTextStyle(
                                          color:
                                              colors.textColor.withOpacity(0.6),
                                          fontSize: 14))
                                ],
                              ),
                            ),
                          );
                        },
                        childCount: getFilteredCryptos().length,
                      ),
                    ),
                  ],
                ))));
  }
}
