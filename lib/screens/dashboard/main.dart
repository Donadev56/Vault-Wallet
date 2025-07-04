// ignore_for_file: deprecated_member_use

import 'dart:async';
import 'dart:io';
import 'package:decimal/decimal.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:moonwallet/custom/refresh/check_mark.dart';
import 'package:moonwallet/notifiers/providers.dart';
import 'package:moonwallet/screens/auth/home.dart';
import 'package:moonwallet/screens/dashboard/add_crypto.dart';
import 'package:moonwallet/screens/dashboard/main/wallet_overview/receive.dart';
import 'package:moonwallet/screens/dashboard/main/wallet_overview/send.dart';
import 'package:moonwallet/screens/dashboard/wallet_actions/private/private_key_screen.dart';
import 'package:moonwallet/types/account_related_types.dart';
import 'package:moonwallet/utils/number_formatter.dart';
import 'package:moonwallet/utils/colors.dart';
import 'package:moonwallet/widgets/appBar/show_custom_drawer.dart';
import 'package:moonwallet/widgets/backup/backup_warning_widget.dart';
import 'package:moonwallet/widgets/screen_widgets/coin_custom_listTitle.dart';
import 'package:moonwallet/widgets/pop_menu_divider.dart';
import 'package:moonwallet/widgets/func/security/ask_password.dart';
import 'package:moonwallet/widgets/func/show_crypto_modal.dart';
import 'package:moonwallet/widgets/func/show_home_options_dialog.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:moonwallet/logger/logger.dart';
import 'package:moonwallet/service/vibration.dart';
import 'package:moonwallet/types/types.dart';
import 'package:moonwallet/utils/constant.dart';
import 'package:moonwallet/widgets/actions.dart';
import 'package:moonwallet/widgets/appBar.dart';
import 'package:moonwallet/widgets/dialogs/show_custom_snackbar.dart';
import 'package:moonwallet/widgets/screen_widgets/pined_sliver_app_bar.dart';
import 'package:page_transition/page_transition.dart';
import 'package:simple_gesture_detector/simple_gesture_detector.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:skeletonizer/skeletonizer.dart';

class MainDashboardScreen extends StatefulHookConsumerWidget {
  final AppColors? colors;
  const MainDashboardScreen({super.key, this.colors});

  @override
  ConsumerState<MainDashboardScreen> createState() =>
      _MainDashboardScreenState();
}

class _MainDashboardScreenState extends ConsumerState<MainDashboardScreen>
    with SingleTickerProviderStateMixin {
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
      GlobalKey<RefreshIndicatorState>();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  AppColors colors = AppColors.defaultTheme;
  List<Crypto> reorganizedCrypto = [];
  int currentOrder = 0;
  String searchCryptoQuery = "";

  final _cryptoSearchTextController = TextEditingController();
  late dynamic connectionSubscription;

  // initializer

  @override
  void initState() {
    if (widget.colors != null) {
      setState(() {
        colors = widget.colors!;
      });
    }
    getSavedTheme();
    super.initState();
  }

  Future<void> getSavedTheme() async {
    final manager = ColorsManager();
    final savedTheme = await manager.getDefaultTheme();
    setState(() {
      colors = savedTheme;
    });
  }

  String formatUsd(double value) {
    return NumberFormatter().formatUsd(value: value);
  }

  String formatCryptoValue(double value) {
    return NumberFormatter().formatCrypto(value: value);
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final accountsProvider = ref.watch(accountsNotifierProvider);
    final providerNotifier = ref.watch(accountsNotifierProvider.notifier);
    final currentAccount = ref.watch(currentAccountProvider).value;
    final assetsNotifier = ref.watch(assetsNotifierProvider);
    final savedAssetsProvider = ref.watch(getSavedAssetsProvider);
    final savedCryptoAsync = ref.watch(savedCryptosProviderNotifier);
    final profileImageAsync = ref.watch(profileImageProviderNotifier);
    final appUIConfigAsync = ref.watch(appUIConfigProvider);
    final appUIConfigNotifierProvider = ref.watch(appUIConfigProvider.notifier);
    final secureConfigAsync = ref.watch(appSecureConfigProvider);
    final secureConfigNotifier = ref.watch(appSecureConfigProvider.notifier);
    final pageIndexNotifierProvider =
        ref.watch(currentPageIndexNotifierProvider.notifier);
    // final assetsState = ref.watch(assetsLoadStateProvider);
    final profileImageProvider =
        ref.watch(profileImageProviderNotifier.notifier);

    final assets = useState<List<Asset>>([]);
    final initialAssets = useState<List<Asset>>([]);
    final accounts = useState<List<PublicAccount>>([]);
    final totalBalance = useState<String>("0");
    final profileImage = useState<File?>(null);
    final uiConfig = useState<AppUIConfig>(AppUIConfig.defaultConfig);
    final secureConfig = useState<AppSecureConfig>(AppSecureConfig());
    final isInitialized = useState<bool>(false);

    useEffect(() {
      secureConfigAsync.whenData((config) {
        secureConfig.value = config;
      });
      return null;
    }, [secureConfigAsync]);

    useEffect(() {
      appUIConfigAsync.whenData((data) {
        uiConfig.value = data;
      });
      return null;
    }, [appUIConfigAsync]);

    useEffect(() {
      profileImageAsync.whenData((data) {
        profileImage.value = data;
      });
      return null;
    }, [profileImageAsync]);

    void updateTotalBalance(List<Asset> assets) {
      Decimal balance = Decimal.zero;
      for (final asset in assets) {
        balance += asset.balanceUsd.toDecimal();
      }
      totalBalance.value = balance.toString();
    }

    useEffect(() {
      savedAssetsProvider.whenData(
        (data) {
          if (data != null && data.isNotEmpty) {
            initialAssets.value = [...data];
            assets.value = [...data];
            updateTotalBalance(assets.value);
          }
          isInitialized.value = true;
        },
      );
      return null;
    }, [savedAssetsProvider]);

    useEffect(() {
      assetsNotifier.whenData((data) {
        if (data.isNotEmpty) {
          initialAssets.value = [...data];
          assets.value = [...data];
        }
        updateTotalBalance(assets.value);
        isInitialized.value = true;
      });

      return null;
    }, [assetsNotifier]);

    useEffect(() {
      accountsProvider.whenData((data) {
        if (data.isEmpty) {
          Navigator.push(
              context, MaterialPageRoute(builder: (ctx) => HomeScreen()));
        }
        accounts.value = data;
      });
      return null;
    }, [accountsProvider]);

    savedCryptoAsync.whenData((data) {
      reorganizedCrypto = data.where((e) => e.canDisplay).toList();
    });

    double fontSizeOf(double size) {
      return size * uiConfig.value.styles.fontSizeScaleFactor;
    }

    double listTitleVerticalOf(double size) {
      return size * uiConfig.value.styles.listTitleVisualDensityVerticalFactor;
    }

    double listTitleHorizontalOf(double size) {
      return size *
          uiConfig.value.styles.listTitleVisualDensityHorizontalFactor;
    }

    double iconSizeOf(double size) {
      return size * uiConfig.value.styles.iconSizeScaleFactor;
    }

    double imageSizeOf(double size) {
      return size * uiConfig.value.styles.imageSizeScaleFactor;
    }

    double roundedOf(double size) {
      return size * uiConfig.value.styles.radiusScaleFactor;
    }

    Future<bool> toggleCanUseBio(bool state) async {
      try {
        return await secureConfigNotifier.toggleCanUseBio(
            state, context, colors);
      } catch (e) {
        logError(e.toString());
        return false;
      }
    }

    Future<bool> toggleHidden() async {
      try {
        return await appUIConfigNotifierProvider.updateAppUIConfig(
            isCryptoHidden: !uiConfig.value.isCryptoHidden);
      } catch (e) {
        logError(e.toString());
        return false;
      }
    }

    void showOptionsModal() async {
      showHomeOptionsDialog(
          isHidden: uiConfig.value.isCryptoHidden,
          roundedOf: roundedOf,
          iconSizeOf: iconSizeOf,
          fontSizeOf: fontSizeOf,
          context: context,
          toggleHidden: toggleHidden,
          colors: colors);
    }

    double width = MediaQuery.of(context).size.width;

    Future<bool> deleteWallet(String walletId) async {
      try {
        if (accounts.value.isEmpty) {
          logError("No account found ");
          return false;
        }
        if (accounts.value.isEmpty) {
          throw ("No account found");
        }
        final accountToRemove =
            accounts.value.where((acc) => acc.keyId == walletId).firstOrNull;
        if (accountToRemove == null) {
          throw "Account not found";
        }
        final deleteResult = await providerNotifier.deleteWallet(
            accountToRemove, colors, context);
        if (deleteResult) {
          notifySuccess("Account deleted successfully", context);
          return true;
        } else {
          throw ("Failed to delete account");
        }
      } catch (e) {
        logError(e.toString());
        notifyError(e.toString(), context);
        return false;
      }
    }

    Future<bool> editWallet(
        {required PublicAccount account,
        Color? color,
        IconData? icon,
        String? name}) async {
      try {
        if (accounts.value.isEmpty) {
          throw ("No account found ");
        }
        final result = await providerNotifier.editWallet(
          account: account,
          name: name,
          icon: icon,
          color: color,
        );
        if (result) {
          notifySuccess("Account updated successfully", context);

          return true;
        } else {
          throw ("Failed to update account");
        }
      } catch (e) {
        logError(e.toString());
        notifyError(e.toString(), context);
        return false;
      }
    }

    Future<bool> changeProfileImage(File image) async {
      try {
        return await profileImageProvider.saveImage(image);
      } catch (e) {
        logError(e.toString());
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
              iconSizeOf: iconSizeOf,
              imageSizeOf: imageSizeOf,
              listTitleHorizontalOf: listTitleHorizontalOf,
              listTitleVerticalOf: listTitleHorizontalOf,
              fontSizeOf: fontSizeOf,
              roundedOf: roundedOf,
              changeProfileImage: changeProfileImage,
              editWallet: editWallet,
              deleteWallet: (w) => deleteWallet(w.keyId),
              account: currentAccount,
              isHidden: uiConfig.value.isCryptoHidden,
              toggleCanUseBio: toggleCanUseBio,
              canUseBio: secureConfig.value.useBioMetric,
              totalBalanceUsd: totalBalance.value,
              context: context,
              profileImage: profileImage.value,
              colors: colors,
              availableCryptos: reorganizedCrypto);
        }
      });
    }

    Future<void> reorderList(int oldIndex, int newIndex) async {
      try {
        final result = await providerNotifier.reorderList(oldIndex, newIndex);
        if (result) {
          notifySuccess("List reordered successfully", context);
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
        if (accounts.value.isEmpty) {
          throw ("No account found");
        }
        final wallet = accounts.value[index];
        if (wallet.isWatchOnly) {
          Navigator.pop(context);
          throw ("This is a watch-only wallet.");
        }
        String userPassword =
            await askUserPassword(context: context, colors: colors) ?? "";

        if (mounted && userPassword.isNotEmpty) {
          Navigator.push(
              context,
              PageTransition(
                  type: PageTransitionType.fade,
                  child: PrivateKeyScreen(
                    account: currentAccount!,
                    password: userPassword,
                    colors: colors,
                  )));
        }
      } catch (e) {
        logError(e.toString());
        if (mounted) {
          notifyError(e.toString(), context);
        }
      }
    }

    Future<void> changeWallet(int index) async {
      try {
        if (accounts.value.isEmpty) {
          throw ("No account found");
        }
        Navigator.pop(context);

        final wallet = accounts.value[index];
        await ref
            .read(lastConnectedKeyIdNotifierProvider.notifier)
            .updateKeyId(wallet.keyId);
      } catch (e) {
        logError(e.toString());
        if (mounted) {
          notifyError(e.toString(), context);
        }
      }
    }

    void reorderCrypto(int order) {
      setState(() {
        currentOrder = order;
        switch (order) {
          case 0:
            assets.value = List.from(initialAssets.value)
              ..sort((a, b) => b.balanceUsd.compareTo(a.balanceUsd));
            break;
          case 1:
            assets.value = List.from(initialAssets.value)
              ..sort((a, b) => a.crypto.symbol.compareTo(b.crypto.symbol));
            break;
          case 2:
            assets.value =
                initialAssets.value.where((a) => a.crypto.isNative).toList();
            break;
          case 3:
            assets.value =
                initialAssets.value.where((a) => !a.crypto.isNative).toList();
            break;
        }
      });
    }

    List<Asset> getFilteredCryptos() {
      return assets.value
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
          iconSizeOf: iconSizeOf,
          imageSizeOf: imageSizeOf,
          listTitleHorizontalOf: listTitleHorizontalOf,
          listTitleVerticalOf: listTitleHorizontalOf,
          fontSizeOf: fontSizeOf,
          roundedOf: roundedOf,
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
                          initialBalanceUsd: assets.value
                              .where((as) => as.crypto.cryptoId == c.cryptoId)
                              .first
                              .balanceUsd,
                          cryptoPrice: assets.value
                              .where((as) => as.crypto.cryptoId == c.cryptoId)
                              .first
                              .cryptoPrice,
                          initialBalanceCrypto: assets.value
                              .where((as) => as.crypto.cryptoId == c.cryptoId)
                              .first
                              .balanceCrypto)))));
    }

    void showSendModal() {
      showCryptoModal(
          iconSizeOf: iconSizeOf,
          imageSizeOf: imageSizeOf,
          listTitleHorizontalOf: listTitleHorizontalOf,
          listTitleVerticalOf: listTitleHorizontalOf,
          fontSizeOf: fontSizeOf,
          roundedOf: roundedOf,
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
                          initialBalanceUsd: assets.value
                              .where((as) => as.crypto.cryptoId == c.cryptoId)
                              .first
                              .balanceUsd,
                          cryptoPrice: assets.value
                              .where((as) => as.crypto.cryptoId == c.cryptoId)
                              .first
                              .cryptoPrice,
                          initialBalanceCrypto: assets.value
                              .where((as) => as.crypto.cryptoId == c.cryptoId)
                              .first
                              .balanceCrypto)))));
    }

    if (currentAccount == null) {
      return Material(
          color: colors.primaryColor,
          child: Center(
            child: SizedBox(
              height: 70,
              width: 70,
              child: CircularProgressIndicator(
                color: colors.themeColor,
              ),
            ),
          ));
    }
    return Scaffold(
        key: _scaffoldKey,
        backgroundColor: colors.primaryColor,
        appBar: CustomAppBar(
            roundedOf: roundedOf,
            fontSizeOf: fontSizeOf,
            iconSizeOf: iconSizeOf,
            imageSizeOf: imageSizeOf,
            listTitleHorizontalOf: listTitleHorizontalOf,
            listTitleVerticalOf: listTitleVerticalOf,
            changeProfileImage: changeProfileImage,
            currentAccount: currentAccount,
            editWallet: editWallet,
            deleteWallet: deleteWallet,
            accounts: accounts.value,
            toggleCanUseBio: toggleCanUseBio,
            canUseBio: secureConfig.value.useBioMetric,
            totalBalanceUsd: totalBalance.value,
            availableCryptos: reorganizedCrypto,
            colors: colors,
            isHidden: uiConfig.value.isCryptoHidden,
            balanceOfAllAccounts: 0,
            profileImage: profileImage.value,
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
              final result = await ref.refresh(assetsNotifierProvider.future);
              if (result.isNotEmpty) {
                initialAssets.value = result;
                assets.value = result;
                updateTotalBalance(assets.value);
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
                child: GlowingOverscrollIndicator(
                    axisDirection: AxisDirection.down,
                    color: colors.themeColor,
                    child: CustomScrollView(
                      slivers: <Widget>[
                        if (!currentAccount.isBackup &&
                            currentAccount.createdLocally)
                          BackupWarningWidget(
                            colors: colors,
                            onTap: () => showPrivateData(accounts.value
                                .indexWhere((e) =>
                                    e.keyId.trim().toLowerCase() ==
                                    currentAccount.keyId.trim().toLowerCase())),
                          ),
                        SliverToBoxAdapter(
                            key: ValueKey(colors.textColor.value),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  margin: const EdgeInsets.all(17),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        children: [
                                          Text(
                                            "Balance",
                                            style: textTheme.bodySmall
                                                ?.copyWith(
                                                    color: colors.textColor),
                                          ),
                                          IconButton(
                                              onPressed: toggleHidden,
                                              icon: Icon(
                                                uiConfig.value.isCryptoHidden
                                                    ? LucideIcons.eyeClosed
                                                    : Icons
                                                        .remove_red_eye_outlined,
                                                color: colors.textColor,
                                                size: iconSizeOf(20),
                                              ))
                                        ],
                                      ),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        children: [
                                          //   Icon(FeatherIcons.dollarSign, color: colors.textColor, size: textTheme.headlineLarge?.fontSize,),
                                          Skeletonizer(
                                            enabled: !isInitialized.value,
                                            containersColor:
                                                colors.secondaryColor,
                                            child: Text(
                                              !uiConfig.value.isCryptoHidden
                                                  ? "\$${NumberFormatter().formatValue(maxDecimals: 2, str: totalBalance.value)}"
                                                  : "***",
                                              overflow: TextOverflow.clip,
                                              maxLines: 1,
                                              style: textTheme.headlineLarge
                                                  ?.copyWith(
                                                      fontSize:
                                                          fontSizeOf(29.52),
                                                      color: colors.textColor),
                                            ),
                                          )
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
                                                onTap: () async {
                                                  if (index == 1) {
                                                    showReceiveModal();
                                                  } else if (index == 0) {
                                                    showSendModal();
                                                  } else if (index == 3) {
                                                    showOptionsModal();
                                                  } else if (index == 2) {
                                                    await pageIndexNotifierProvider
                                                        .savePageIndex(1);
                                                  }
                                                },
                                                text: action["name"],
                                                actIcon: action["icon"],
                                                textColor: colors.textColor,
                                                radius: roundedOf(10),
                                                fontSize: fontSizeOf(12),
                                                size: width <= 330
                                                    ? iconSizeOf(40)
                                                    : iconSizeOf(50),
                                                iconSize: iconSizeOf(20),
                                                color: colors.secondaryColor);
                                          }))),
                                ),
                                SizedBox(
                                  height: 20,
                                ),
                              ],
                            )),
                        PinedSliverAppBar(
                            onSearch: (v) {
                              setState(() {
                                searchCryptoQuery = v.toLowerCase();
                              });
                            },
                            colors: colors,
                            cryptoSearchTextController:
                                _cryptoSearchTextController,
                            fontSizeOf: fontSizeOf,
                            roundedOf: roundedOf,
                            moreButtonOptions:
                                List<PopupMenuEntry<dynamic>>.generate(
                                    fixedAppBarOptions.length + 1, (i) {
                              if (i == 2) {
                                return CustomPopMenuDivider(colors: colors);
                              }
                              final option =
                                  fixedAppBarOptions[i == 3 ? i - 1 : i];
                              return PopupMenuItem(
                                onTap: () {
                                  if (i == 0) {
                                    reorderCrypto(0);
                                  } else if (i == 1) {
                                    reorderCrypto(1);
                                  } else if (i == 3) {
                                    Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (context) =>
                                                AddCryptoView()));
                                  }
                                },
                                child: Row(children: [
                                  Icon(option["icon"],
                                      size: iconSizeOf(25),
                                      color: colors.textColor),
                                  SizedBox(width: 8),
                                  Text(option["name"],
                                      style: textTheme.bodyMedium?.copyWith(
                                          color: colors.textColor,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w400)),
                                ]),
                              );
                            })),
                        !isInitialized.value
                            ? SliverToBoxAdapter(
                                child: Container(
                                height: 300,
                                decoration:
                                    BoxDecoration(color: colors.primaryColor),
                                child: Center(
                                  child: SizedBox(
                                    height: 30,
                                    width: 30,
                                    child:
                                        LoadingAnimationWidget.discreteCircle(
                                            color: colors.themeColor, size: 40),
                                  ),
                                ),
                              ))
                            : SliverList(
                                delegate: SliverChildBuilderDelegate(
                                  (BuildContext context, int index) {
                                    if (index == getFilteredCryptos().length) {
                                      return Align(
                                        alignment: Alignment.center,
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 20),
                                          child: InkWell(
                                              onTap: () {
                                                Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                        builder: (_) =>
                                                            AddCryptoView()));
                                              },
                                              child: Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        vertical: 10),
                                                child: Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .center,
                                                    spacing: 10,
                                                    children: [
                                                      Icon(
                                                        LucideIcons.bolt,
                                                        color: colors.textColor
                                                            .withValues(
                                                                alpha: 0.8),
                                                        size: 20,
                                                      ),
                                                      Text(
                                                        "Manage Coins",
                                                        style: textTheme
                                                            .bodyMedium
                                                            ?.copyWith(
                                                                fontSize:
                                                                    fontSizeOf(
                                                                        14),
                                                                color: colors
                                                                    .textColor
                                                                    .withValues(
                                                                        alpha:
                                                                            0.8)),
                                                      )
                                                    ]),
                                              )),
                                        ),
                                      );
                                    }

                                    final assetsFilteredList =
                                        getFilteredCryptos()[index];
                                    final crypto = assetsFilteredList.crypto;
                                    final trend =
                                        assetsFilteredList.cryptoTrendPercent;
                                    final tokenBalance =
                                        assetsFilteredList.balanceCrypto;
                                    final usdBalance =
                                        assetsFilteredList.balanceUsd;

                                    final cryptoPrice =
                                        assetsFilteredList.cryptoPrice;

                                    return CoinCustomListTitle(
                                        roundedOf: roundedOf,
                                        fontSizeOf: fontSizeOf,
                                        iconSizeOf: iconSizeOf,
                                        imageSizeOf: imageSizeOf,
                                        listTitleHorizontalOf:
                                            listTitleHorizontalOf,
                                        listTitleVerticalOf:
                                            listTitleVerticalOf,
                                        trend: trend,
                                        cryptoPrice: cryptoPrice,
                                        colors: colors,
                                        crypto: crypto,
                                        currentAccount: currentAccount,
                                        isCryptoHidden:
                                            uiConfig.value.isCryptoHidden,
                                        tokenBalance: tokenBalance,
                                        usdBalance: usdBalance);
                                  },
                                  childCount: getFilteredCryptos().length + 1,
                                ),
                              ),
                      ],
                    )))));
  }
}
