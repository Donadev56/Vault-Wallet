// ignore_for_file: deprecated_member_use

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:currency_formatter/currency_formatter.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:moonwallet/custom/refresh/check_mark.dart';
import 'package:moonwallet/notifiers/price_notifier.dart';
import 'package:moonwallet/notifiers/providers.dart';
import 'package:moonwallet/screens/dashboard/view/receive.dart';
import 'package:moonwallet/screens/dashboard/view/send.dart';
import 'package:moonwallet/screens/dashboard/view/wallet_overview.dart';
import 'package:moonwallet/service/network.dart';
import 'package:moonwallet/service/number_formatter.dart';
import 'package:moonwallet/utils/colors.dart';
import 'package:moonwallet/widgets/appBar/show_custom_drawer.dart';
import 'package:moonwallet/widgets/crypto_picture.dart';
import 'package:moonwallet/widgets/pop_menu_divider.dart';
import 'package:moonwallet/widgets/func/ask_password.dart';
import 'package:moonwallet/widgets/func/show_crypto_modal.dart';
import 'package:moonwallet/widgets/func/show_home_options_dialog.dart';
// ignore: depend_on_referenced_packages
import 'package:path/path.dart' as path;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:moonwallet/logger/logger.dart';
import 'package:moonwallet/main.dart';
import 'package:moonwallet/service/vibration.dart';
import 'package:moonwallet/service/web3_interaction.dart';
import 'package:moonwallet/types/types.dart';
import 'package:moonwallet/utils/constant.dart';
import 'package:moonwallet/utils/prefs.dart';
import 'package:moonwallet/widgets/actions.dart';
import 'package:moonwallet/widgets/appBar.dart';
import 'package:moonwallet/widgets/func/snackbar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:simple_gesture_detector/simple_gesture_detector.dart';
import 'package:http/http.dart';

class MainDashboardScreen extends ConsumerStatefulWidget {
  final AppColors? colors;
  const MainDashboardScreen({super.key, this.colors});

  @override
  ConsumerState<MainDashboardScreen> createState() =>
      _MainDashboardScreenState();
}

class _MainDashboardScreenState extends ConsumerState<MainDashboardScreen>
    with SingleTickerProviderStateMixin {
  List<Asset> initialAssets = [];
  bool isLoading = false;

  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
      GlobalKey<RefreshIndicatorState>();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  File? _profileImage;
  String userName = "Moon User";
  String lastAccount = '';

  AppColors colors = AppColors.defaultTheme;
  List<PublicData> filteredAccounts = [];
  final formatter = NumberFormat("0.########", "en_US");

  final web3InteractManager = Web3InteractionManager();
  final publicDataManager = PublicDataManager();
  final connectivityManager = ConnectivityManager();
  List<Crypto> reorganizedCrypto = [];
  List<Asset> assets = [];

  bool canUseBio = false;
  int currentOrder = 0;
  String searchCryptoQuery = "";

  bool isHidden = false;
  final _cryptoSearchTextController = TextEditingController();
  late dynamic connectionSubscription;

  bool isConnected = false;
  bool wasDisconnected = false;

  double balanceOfAllAccounts = 0;
  double totalBalance = 0;
  String searchQuery = "";

  final List<Map<String, dynamic>> actionsData = [
    {'icon': LucideIcons.moveUpRight, 'page': 'send', 'name': 'Send'},
    {'icon': LucideIcons.moveDownLeft, 'page': 'receive', 'name': 'Receive'},
    {'icon': LucideIcons.plus, 'page': 'add_token', 'name': 'Add crypto'},
    {'icon': LucideIcons.ellipsis, 'page': 'more', 'name': 'More'},
  ];

  // initializer

  @override
  void initState() {
    if (widget.colors != null) {
      setState(() {
        colors = widget.colors!;
      });
    }
    getIsHidden();
    getSavedTheme();

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

      final File profileImageFile = File(profileFilePath);
      if (await profileImageFile.exists()) {
        setState(() {
          _profileImage = profileImageFile;
        });
      }

      return true;
    } catch (e) {
      log("Error loading data: $e");
      return false;
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

  void showOptionsModal() async {
    showHomeOptionsDialog(
        context: context, toggleHidden: toggleHidden, colors: colors);
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

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final accountsProvider = ref.watch(accountsNotifierProvider);
    final accounts = accountsProvider.value;
    final providerNotifier = ref.watch(accountsNotifierProvider.notifier);
    final currentAccount = ref.watch(currentAccountProvider).value;
    final assetsNotifier = ref.watch(assetsNotifierProvider);
    final savedAssetsProvider = ref.watch(getSavedAssetsProvider);
    final savedCryptoAsync = ref.watch(savedCryptosProviderNotifier);
    

    savedAssetsProvider.whenData(
      (data) {
        if (data != null) {
          setState(() {
            initialAssets = data;
            assets = data;
            isLoading = false;
            double balance = 0;
            for (final asset in assets) {
              balance += asset.balanceUsd;
            }
            totalBalance = balance;
          });
        } else {
          setState(() {
            isLoading = true;
          });
        }
      },
    );
    savedCryptoAsync.whenData((data) {
      reorganizedCrypto = data;
    });
    assetsNotifier.whenData((data) {
      if (data.isNotEmpty) {
        setState(() {
          initialAssets = data;
          assets = data;
          isLoading = false;
          double balance = 0;
          for (final asset in assets) {
            balance += asset.balanceUsd;
          }
          totalBalance = balance;
        });
      }
    });

    double width = MediaQuery.of(context).size.width;
    // double height = MediaQuery.of(context).size.height;

    if (reorganizedCrypto.isEmpty || isLoading) {
      return Container(
        decoration: BoxDecoration(color: colors.primaryColor),
        child: Center(
          child: SizedBox(
            height: 30,
            width: 30,
            child: LoadingAnimationWidget.discreteCircle(
                color: colors.themeColor, size: 40),
          ),
        ),
      );
    }

    Future<bool> deleteWallet(String walletId) async {
      try {
        if (accounts == null) {
          logError("No account found ");
          return false;
        }
        if (accounts.isEmpty) {
          throw ("No account found");
        }
        final password = await askPassword(context: context, colors: colors);
        final accountToRemove =
            accounts.where((acc) => acc.keyId == walletId).first;
        if (password.isNotEmpty) {
          // validateThePassword
          final result =
              await providerNotifier.walletSaver.getDecryptedData(password);
          if (result == null) {
            throw ("Invalid password");
          }
          final deleteResult =
              await providerNotifier.deleteWallet(accountToRemove);
          if (deleteResult) {
            notifySuccess("Account deleted successfully");
            Navigator.pop(context);
            return true;
          } else {
            throw ("Failed to delete account");
          }
        } else {
          throw ("Password is required");
        }
      } catch (e) {
        logError(e.toString());
        notifyError(e.toString());
        return false;
      }
    }

    Future<bool> editWallet(
        {required PublicData account,
        Color? color,
        IconData? icon,
        String? name}) async {
      try {
        final result = await providerNotifier.editWallet(
          account: account,
          name: name,
          icon: icon,
          color: color,
        );
        if (result) {
          notifySuccess("Account updated successfully");

          return true;
        } else {
          throw ("Failed to update account");
        }
      } catch (e) {
        logError(e.toString());
        notifyError(e.toString());
        return false;
      }
    }

    void onHorizontalSwipe(SwipeDirection direction) {
      setState(() {
        if (direction == SwipeDirection.right) {
          if (currentAccount == null) {
            return;
          }

          showCustomDrawer(
              editWallet: editWallet,
              deleteWallet: (w) => deleteWallet(w.keyId),
              account: currentAccount,
              isHidden: isHidden,
              updateBioState: updateBioState,
              canUseBio: canUseBio,
              refreshProfile: refreshProfile,
              totalBalanceUsd: totalBalance,
              context: context,
              profileImage: _profileImage,
              colors: colors,
              availableCryptos: reorganizedCrypto);
        }
      });
    }

    Future<void> reorderList(int oldIndex, int newIndex) async {
      try {
        final result = await providerNotifier.reorderList(oldIndex, newIndex);
        if (result) {
          notifySuccess("List reordered successfully");
        } else {
          throw ("Failed to reorder list");
        }
      } catch (e) {
        logError(e.toString());
        if (mounted) {
          Navigator.pop(context);
        }
      }
    }

    Future<void> showPrivateData(int index) async {
      try {
        if (accounts == null || accounts.isEmpty) {
          throw ("No account found");
        }
        final wallet = accounts[index];
        if (wallet.isWatchOnly) {
          Navigator.pop(context);
          throw ("This is a watch-only wallet.");
        }
        String userPassword =
            await askPassword(context: context, colors: colors);

        if (mounted && userPassword.isNotEmpty) {
          Navigator.pushNamed(context, Routes.privateDataScreen,
              arguments: ({
                "keyId": accounts[index].keyId,
                "password": userPassword
              }));
        }
      } catch (e) {
        logError(e.toString());
        if (mounted) {
          notifyError(e.toString());
        }
      }
    }

    Future<void> changeWallet(int index) async {
      try {
        if (accounts == null || accounts.isEmpty) {
          throw ("No account found");
        }
        Navigator.pop(context);

        final wallet = accounts[index];
        await ref
            .read(lastConnectedKeyIdNotifierProvider.notifier)
            .updateKeyId(wallet.keyId);
      } catch (e) {
        logError(e.toString());
        if (mounted) {
          notifyError(e.toString());
        }
      }
    }

    void reorderCrypto(int order) {
      setState(() {
        currentOrder = order;
        switch (order) {
          case 0:
            assets = List.from(initialAssets)
              ..sort((a, b) => b.balanceUsd.compareTo(a.balanceUsd));
            break;
          case 1:
            assets = List.from(initialAssets)
              ..sort((a, b) => a.crypto.symbol.compareTo(b.crypto.symbol));
            break;
          case 2:
            assets = initialAssets
                .where((a) => a.crypto.type == CryptoType.network)
                .toList();
            break;
          case 3:
            assets = initialAssets
                .where((a) => a.crypto.type == CryptoType.token)
                .toList();
            break;
        }
      });
    }

    List<Asset> getFilteredCryptos() {
      return assets
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

    void showReceiveModal() {
      showCryptoModal(
          colors: colors,
          context: context,
          primaryColor: colors.primaryColor,
          textColor: colors.textColor,
          surfaceTintColor: colors.grayColor.withOpacity(0.6),
          reorganizedCrypto: reorganizedCrypto,
          onSelect: (c) => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (ctx) => ReceiveScreen(
                      initData: WidgetInitialData(
                          account: currentAccount!,
                          crypto: c,
                          colors: colors,
                          initialBalanceUsd: assets
                              .where((as) => as.crypto.cryptoId == c.cryptoId)
                              .first
                              .balanceUsd,
                          initialBalanceCrypto: assets
                              .where((as) => as.crypto.cryptoId == c.cryptoId)
                              .first
                              .balanceCrypto)))));
    }

    void showSendModal() {
      showCryptoModal(
          colors: colors,
          context: context,
          primaryColor: colors.primaryColor,
          textColor: colors.textColor,
          surfaceTintColor: colors.grayColor.withOpacity(0.6),
          reorganizedCrypto: reorganizedCrypto,
          onSelect: (c) => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (ctx) => SendTransactionScreen(
                      initData: WidgetInitialData(
                          account: currentAccount!,
                          crypto: c,
                          colors: colors,
                          initialBalanceUsd: assets
                              .where((as) => as.crypto.cryptoId == c.cryptoId)
                              .first
                              .balanceUsd,
                          initialBalanceCrypto: assets
                              .where((as) => as.crypto.cryptoId == c.cryptoId)
                              .first
                              .balanceCrypto)))));
    }

    return Scaffold(
        key: _scaffoldKey,
        backgroundColor: colors.primaryColor,
        appBar: CustomAppBar(
            currentAccount: currentAccount ??
                PublicData(
                    keyId: "",
                    creationDate: 0,
                    walletName: "",
                    address: "",
                    isWatchOnly: true),
            editWallet: editWallet,
            deleteWallet: deleteWallet,
            accounts: accounts ?? [],
            updateBioState: updateBioState,
            canUseBio: canUseBio,
            refreshProfile: refreshProfile,
            totalBalanceUsd: totalBalance,
            availableCryptos: reorganizedCrypto,
            colors: colors,
            isHidden: isHidden,
            balanceOfAllAccounts: balanceOfAllAccounts,
            profileImage: _profileImage,
            scaffoldKey: _scaffoldKey,
            showPrivateData: showPrivateData,
            reorderList: reorderList,
            secondaryColor: colors.themeColor,
            changeAccount: changeWallet,
            primaryColor: colors.primaryColor,
            textColor: colors.textColor,
            surfaceTintColor: colors.secondaryColor),
        body: CheckMarkIndicator(
            style: CheckMarkStyle(
                loading: CheckMarkColors(
                    content: colors.primaryColor,
                    background: colors.themeColor),
                success: CheckMarkColors(
                    content: colors.textColor, background: colors.greenColor),
                error: CheckMarkColors(
                    content: colors.textColor, background: colors.redColor)),
            // showChildOpacityTransition: false,
            // color: colors.themeColor,
            // backgroundColor: colors.primaryColor,
            key: _refreshIndicatorKey,
            onRefresh: () async {
              await vibrate(duration: 10);
              if (currentAccount != null) {
                final result = await ref.refresh(assetsNotifierProvider.future);
                if (result.isNotEmpty) {
                  setState(() {
                    initialAssets = result;
                    assets = result;
                    double balance = 0;
                    for (final asset in assets) {
                      balance += asset.balanceUsd;
                    }
                    totalBalance = balance;
                  });
                }
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
                        key: ValueKey(colors.textColor.value),
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
                                        style: textTheme.bodyMedium
                                            ?.copyWith(color: colors.textColor),
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
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      //   Icon(FeatherIcons.dollarSign, color: colors.textColor, size: textTheme.headlineLarge?.fontSize,),
                                      Text(
                                        !isHidden
                                            ? "\$${formatUsd(totalBalance.toString())}"
                                            : "***",
                                        overflow: TextOverflow.clip,
                                        maxLines: 1,
                                        style: textTheme.headlineLarge
                                            ?.copyWith(
                                                fontSize: 36,
                                                color: colors.textColor),
                                      ),
                                    ],
                                  )
                                ],
                              ),
                            ),
                            Container(
                              alignment: Alignment.center,
                              child: SingleChildScrollView(
                                  physics: BouncingScrollPhysics(),
                                  scrollDirection: Axis.horizontal,
                                  child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: List.generate(
                                          actionsData.length, (index) {
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
                                            size: width <= 330 ? 40 : 50,
                                            iconSize: 20,
                                            color: colors.secondaryColor);
                                      }))),
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
                                    style: textTheme.bodySmall?.copyWith(
                                        fontSize: 13, color: colors.textColor),
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
                            splashRadius: 10,
                            borderRadius: BorderRadius.circular(20),
                            requestFocus: true,
                            menuPadding: const EdgeInsets.all(0),
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
                                          size: 25,
                                          color: colors.textColor
                                              .withOpacity(0.4)),
                                      SizedBox(width: 8),
                                      Text(fixedAppBarOptions[0]["name"],
                                          style: textTheme.bodyMedium),
                                    ]),
                                  ),
                                  PopupMenuItem(
                                    onTap: () {
                                      reorderCrypto(1);
                                    },
                                    child: Row(children: [
                                      Icon(fixedAppBarOptions[1]["icon"],
                                          color: colors.textColor
                                              .withOpacity(0.4)),
                                      SizedBox(width: 8),
                                      Text(fixedAppBarOptions[1]["name"],
                                          style: textTheme.bodyMedium?.copyWith(
                                              color: colors.textColor)),
                                    ]),
                                  ),
                                  CustomPopMenuDivider(colors: colors),
                                  PopupMenuItem(
                                    onTap: () {
                                      Navigator.pushNamed(
                                          context, Routes.addCrypto);
                                    },
                                    child: Row(children: [
                                      Icon(fixedAppBarOptions[4]["icon"],
                                          color: colors.textColor
                                              .withOpacity(0.4)),
                                      SizedBox(width: 8),
                                      Text(fixedAppBarOptions[4]["name"],
                                          style: textTheme.bodyMedium?.copyWith(
                                              color: colors.textColor)),
                                    ]),
                                  ),
                                ])
                      ],
                    ),
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (BuildContext context, int index) {
                          final assetsFilteredList =
                              getFilteredCryptos()[index];
                          final crypto = assetsFilteredList.crypto;
                          final trend = assetsFilteredList.cryptoTrendPercent;
                          final tokenBalance = assetsFilteredList.balanceCrypto;
                          final usdBalance = assetsFilteredList.balanceUsd;
                          final cryptoPrice = assetsFilteredList.cryptoPrice;

                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 5),
                            child: Material(
                                color: Colors.transparent,
                                child: ListTile(
                                  visualDensity: VisualDensity.compact,
                                  splashColor:
                                      colors.textColor.withOpacity(0.05),
                                  onTap: () {
                                    log("Crypto id ${crypto.cryptoId}");
                                    Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => WalletViewScreen(
                                              initData: WidgetInitialData(
                                                  account: currentAccount!,
                                                  crypto: crypto,
                                                  colors: colors,
                                                  initialBalanceUsd: assets
                                                      .where((as) =>
                                                          as.crypto.cryptoId ==
                                                          crypto.cryptoId)
                                                      .first
                                                      .balanceUsd,
                                                  initialBalanceCrypto: assets
                                                      .where((as) =>
                                                          as.crypto.cryptoId ==
                                                          crypto.cryptoId)
                                                      .first
                                                      .balanceCrypto)),
                                        ));
                                  },
                                  leading: CryptoPicture(
                                      crypto: crypto, size: 38, colors: colors),
                                  title: LayoutBuilder(builder: (ctx, c) {
                                    return Row(
                                      spacing: 10,
                                      children: [
                                        ConstrainedBox(
                                          constraints: BoxConstraints(
                                              maxWidth: c.maxWidth * 0.4),
                                          child: Text(
                                              crypto.symbol.toUpperCase(),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: textTheme.bodyMedium
                                                  ?.copyWith(
                                                      fontWeight:
                                                          FontWeight.w400,
                                                      color: colors.textColor)),
                                        ),
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
                                              crypto.type == CryptoType.token
                                                  ? "${crypto.network?.name}"
                                                  : crypto.name,
                                              style: textTheme.bodySmall
                                                  ?.copyWith(
                                                      fontSize: 10,
                                                      color: colors.textColor)),
                                        )
                                      ],
                                    );
                                  }),
                                  subtitle: Row(
                                    spacing: 2,
                                    children: [
                                      Text(formatUsd(cryptoPrice.toString()),
                                          style: textTheme.bodySmall?.copyWith(
                                            color: colors.textColor
                                                .withOpacity(0.6),
                                            fontSize: 16,
                                          )),
                                      if (trend != 0)
                                        Text(
                                          " ${(trend).toStringAsFixed(2)}%",
                                          style: textTheme.bodySmall?.copyWith(
                                            color: trend > 0
                                                ? colors.greenColor
                                                : colors.redColor,
                                            fontSize: 14,
                                          ),
                                        ),
                                    ],
                                  ),
                                  trailing: ConstrainedBox(
                                    constraints:
                                        BoxConstraints(maxWidth: width * 0.37),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceAround,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                            isHidden
                                                ? "***"
                                                : formatCryptoValue(
                                                        tokenBalance.toString())
                                                    .trim(),
                                            overflow: TextOverflow.ellipsis,
                                            maxLines: 1,
                                            style: textTheme.bodyMedium
                                                ?.copyWith(
                                                    fontSize: 15,
                                                    color: colors.textColor,
                                                    fontWeight:
                                                        FontWeight.w400)),
                                        Text(
                                            isHidden
                                                ? "***"
                                                : "\$${formatUsd(usdBalance.toString()).trim()}",
                                            overflow: TextOverflow.ellipsis,
                                            maxLines: 1,
                                            style:
                                                textTheme.bodySmall
                                                    ?.copyWith(
                                                        color: colors.textColor
                                                            .withOpacity(0.6),
                                                        fontSize: 15,
                                                        fontWeight:
                                                            FontWeight.w500))
                                      ],
                                    ),
                                  ),
                                )),
                          );
                        },
                        childCount: getFilteredCryptos().length,
                      ),
                    ),
                  ],
                ))));
  }
}
