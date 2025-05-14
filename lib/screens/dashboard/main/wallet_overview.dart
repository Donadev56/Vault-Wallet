// ignore_for_file: deprecated_member_use

import 'package:decimal/decimal.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:moonwallet/custom/refresh/check_mark.dart';
import 'package:moonwallet/logger/logger.dart';
import 'package:moonwallet/notifiers/providers.dart';
import 'package:moonwallet/screens/dashboard/main/wallet_overview/receive.dart';
import 'package:moonwallet/screens/dashboard/main/wallet_overview/send.dart';
import 'package:moonwallet/service/external_data/crypto_request_manager.dart';
import 'package:moonwallet/service/db/crypto_storage_manager.dart';
import 'package:moonwallet/service/external_data/transaction_manager.dart';
import 'package:moonwallet/service/rpc_service.dart';
import 'package:moonwallet/types/account_related_types.dart';
import 'package:moonwallet/types/transaction.dart';
import 'package:moonwallet/utils/number_formatter.dart';
import 'package:moonwallet/service/external_data/price_manager.dart';
import 'package:moonwallet/types/types.dart';
import 'package:moonwallet/utils/colors.dart';
import 'package:moonwallet/utils/encrypt_service.dart';
import 'package:moonwallet/utils/themes.dart';
import 'package:moonwallet/widgets/actions.dart';
import 'package:moonwallet/widgets/app_bar_title.dart';
import 'package:moonwallet/widgets/screen_widgets/crypto_picture.dart';
import 'package:moonwallet/widgets/view/other_options.dart';
import 'package:moonwallet/widgets/view/show_crypto_candle_data.dart';
import 'package:moonwallet/widgets/func/transactions/history/transactions.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:url_launcher/url_launcher.dart';

class WalletViewScreen extends StatefulHookConsumerWidget {
  final WidgetInitialData initData;
  const WalletViewScreen({super.key, required this.initData});

  @override
  ConsumerState<WalletViewScreen> createState() => _WalletViewScreenState();
}

class _WalletViewScreenState extends ConsumerState<WalletViewScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late InternetConnection internetChecker;
  final formatter = NumberFormatter();
  late PublicAccount currentAccount;

  List<PublicAccount> accounts = [];
  List<Crypto> reorganizedCrypto = [];
  String cryptoId = "";

  bool isScrollingToTheBottom = false;
  final encryptService = EncryptService();
  final priceManager = PriceManager();
  final rpcService = RpcService();

  final cryptoStorageManager = CryptoStorageManager();
  final ScrollController _scrollController = ScrollController();

  late Crypto currentCrypto;

  String tokenBalance = "0";
  String totalBalanceUsd = "0";

  bool isBalanceLoading = true;
  double cryptoPrice = 0;

  AppColors colors = AppColors.defaultTheme;
  Themes themes = Themes();
  String savedThemeName = "";
  Future<void> getSavedTheme() async {
    try {
      final manager = ColorsManager();
      final savedName = await manager.getThemeName();
      if (!mounted) return;

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
    reorganizeCrypto();
    _tabController = TabController(length: 3, vsync: this);
    _scrollController.addListener(_onScroll);
    init();
  }

  @override
  void dispose() {
    super.dispose();
    _scrollController.dispose();
    _tabController.dispose();
  }

  Future<void> init() async {
    if (!mounted) return;

    setState(() {
      currentAccount = widget.initData.account;
      currentCrypto = widget.initData.crypto;
      colors = widget.initData.colors;
      if (widget.initData.initialBalanceUsd != null) {
        totalBalanceUsd = widget.initData.initialBalanceUsd ?? "0";
        isBalanceLoading = false;
      }
      cryptoPrice = widget.initData.cryptoPrice;
      tokenBalance = widget.initData.initialBalanceCrypto;
    });
    final balance = await rpcService.getBalance(currentCrypto, currentAccount);

    setState(() {
      tokenBalance = balance;
      totalBalanceUsd =
          (Decimal.parse(balance) * Decimal.parse(cryptoPrice.toString()))
              .toString();
    });
  }

  void _onScroll() {
    if (_scrollController.position.userScrollDirection ==
        ScrollDirection.forward) {
      log("scroll direction is forward");
      if (!mounted) return;

      setState(() {
        isScrollingToTheBottom = false;
      });
    } else if (_scrollController.position.userScrollDirection ==
        ScrollDirection.reverse) {
      setState(() {
        isScrollingToTheBottom = true;
      });
      log("scroll direction is reverse");
    }
  }

  Future<void> reorganizeCrypto() async {
    final List<Crypto> standardCrypto =
        await CryptoRequestManager().getAllCryptos();
    final savedCrypto =
        await cryptoStorageManager.getSavedCryptos(wallet: currentAccount);
    if (savedCrypto == null || savedCrypto.isEmpty) {
      if (!mounted) return;

      setState(() {
        reorganizedCrypto = standardCrypto;
      });
    } else {
      if (!mounted) return;
      setState(() {
        reorganizedCrypto = savedCrypto;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final appUIConfigAsync = ref.watch(appUIConfigProvider);

    final uiConfig = useState<AppUIConfig>(AppUIConfig.defaultConfig);
    final transactionList = useState<List<Transaction>>([]);
    final isInitialized = useState<bool>(false);
    List<Transaction> getFilteredTransactions(List<Transaction> transactions) {
      return transactions..sort((a, b) => b.timeStamp.compareTo(a.timeStamp));
    }

    Future<void> fetchRecentTransactions() async {
      try {
        final manager =
            TransactionManager(account: currentAccount, token: currentCrypto);
        final transactions = await manager.getTransactions();
        if (transactions.isNotEmpty) {
          transactionList.value = getFilteredTransactions(transactions);
        }
      } catch (e) {
        logError(e.toString());
      } finally {
        isInitialized.value = true;
      }
    }

    useEffect(() {
      fetchRecentTransactions();
      return null;
    }, [currentAccount, currentCrypto]);

    useEffect(() {
      Future<void> fetchSavedTransactions() async {
        try {
          final manager =
              TransactionManager(account: currentAccount, token: currentCrypto);
          final transactions = await manager.getSavedTransactions();
          if (transactions.isNotEmpty) {
            transactionList.value = getFilteredTransactions(transactions);
          }
        } catch (e) {
          logError(e.toString());
        }
      }

      fetchSavedTransactions();

      return null;
    }, [currentCrypto, currentCrypto]);

    useEffect(() {
      appUIConfigAsync.whenData((data) {
        uiConfig.value = data;
      });
      return null;
    }, [appUIConfigAsync]);

    List<Transaction> transactionsList(int i) {
      if (i == 0) {
        return transactionList.value;
      } else if (i == 1) {
        return transactionList.value
            .where((tr) =>
                tr.from.toLowerCase().trim() !=
                currentAccount
                    .addressByToken(currentCrypto)
                    .toLowerCase()
                    .trim())
            .toList();
      } else if (i == 2) {
        return transactionList.value
            .where((tr) =>
                tr.from.toLowerCase().trim() ==
                currentAccount
                    .addressByToken(currentCrypto)
                    .toLowerCase()
                    .trim())
            .toList();
      }

      return [];
    }

    double fontSizeOf(double size) {
      return size * uiConfig.value.styles.fontSizeScaleFactor;
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
          title: AppBarTitle(title: currentCrypto.symbol, colors: colors),
          actions: [
            if (currentCrypto.cgSymbol != null ||
                currentCrypto.cgSymbol?.isEmpty == false)
              IconButton(
                onPressed: () {
                  showCryptoCandleModal(
                      fontSizeOf: fontSizeOf,
                      roundedOf: roundedOf,
                      context: context,
                      colors: colors,
                      currentCrypto: currentCrypto);
                },
                icon: Icon(
                  Icons.show_chart,
                  color: colors.textColor,
                ),
              ),
            IconButton(
              onPressed: () {
                showOtherOptions(
                    fontSizeOf: fontSizeOf,
                    roundedOf: roundedOf,
                    context: context,
                    colors: colors,
                    currentCrypto: currentCrypto);
              },
              icon: Icon(
                Icons.more_vert,
                color: colors.textColor,
              ),
            )
          ],
        ),
        body: GlowingOverscrollIndicator(
            axisDirection: AxisDirection.down,
            color: colors.themeColor,
            child: NestedScrollView(
              headerSliverBuilder:
                  (BuildContext context, bool innerBoxIsScrolled) {
                return [
                  SliverToBoxAdapter(
                    child: Column(
                      children: [
                        Align(
                            alignment: Alignment.center,
                            child: Column(
                              children: [
                                Container(
                                  margin: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(50),
                                  ),
                                  child: CryptoPicture(
                                      crypto: currentCrypto,
                                      size: imageSizeOf(65),
                                      colors: colors),
                                ),
                                SizedBox(
                                  height: 10,
                                ),
                                Skeletonizer(
                                    enabled: isBalanceLoading,
                                    child: SizedBox(
                                        child: Center(
                                            child: Text(
                                      (formatter.formatValue(
                                          str: tokenBalance)),
                                      overflow: TextOverflow.clip,
                                      maxLines: 1,
                                      style: textTheme.bodyMedium?.copyWith(
                                          color: colors.textColor,
                                          fontWeight: FontWeight.bold,
                                          fontSize: fontSizeOf(24)),
                                    )))),
                                SizedBox(
                                  height: 5,
                                ),
                                Skeletonizer(
                                    enabled: isBalanceLoading,
                                    child: Text(
                                      "= \$ ${formatter.formatDecimal(
                                        (totalBalanceUsd),
                                        maxDecimals: 2,
                                      )}",
                                      style: textTheme.bodySmall?.copyWith(
                                          color:
                                              colors.textColor.withOpacity(0.5),
                                          fontSize: fontSizeOf(14)),
                                    )),
                                SizedBox(
                                  height: 15,
                                ),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceAround,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    ActionsWidgets(
                                        radius: roundedOf(10),
                                        fontSize: fontSizeOf(12),
                                        size: (50),
                                        iconSize: iconSizeOf(22),
                                        color: colors.secondaryColor,
                                        actIcon: Icons.arrow_upward,
                                        textColor: colors.textColor,
                                        text: "Send",
                                        onTap: () => Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                                builder: (ctx) =>
                                                    SendTransactionScreen(
                                                      initData: WidgetInitialData(
                                                          cryptoPrice:
                                                              cryptoPrice,
                                                          account:
                                                              currentAccount,
                                                          crypto: currentCrypto,
                                                          colors: colors,
                                                          initialBalanceCrypto:
                                                              tokenBalance,
                                                          initialBalanceUsd:
                                                              totalBalanceUsd),
                                                    )))),
                                    ActionsWidgets(
                                        radius: roundedOf(10),
                                        fontSize: fontSizeOf(12),
                                        size: (50),
                                        iconSize: iconSizeOf(22),
                                        color: colors.secondaryColor,
                                        actIcon: Icons.arrow_downward,
                                        textColor: colors.textColor,
                                        text: "Receive",
                                        onTap: () => Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                                builder: (ctx) => ReceiveScreen(
                                                      initData: WidgetInitialData(
                                                          cryptoPrice: 0,
                                                          account:
                                                              currentAccount,
                                                          crypto: currentCrypto,
                                                          colors: colors,
                                                          initialBalanceCrypto:
                                                              tokenBalance,
                                                          initialBalanceUsd:
                                                              totalBalanceUsd),
                                                    )))),
                                  ],
                                ),
                              ],
                            )),
                      ],
                    ),
                  ),
                  SliverPersistentHeader(
                    key: ValueKey(colors.primaryColor),
                    pinned: true,
                    delegate: _SliverAppBarDelegate(
                      TabBar(
                        dividerColor: Colors.transparent,
                        controller: _tabController,
                        labelColor: colors.themeColor,
                        unselectedLabelColor: colors.textColor,
                        indicatorColor: colors.themeColor,
                        tabs: [
                          Tab(text: 'All'),
                          Tab(
                            text: 'In',
                          ),
                          Tab(
                            text: 'Out',
                          ),
                        ],
                      ),
                      primaryColor: colors.primaryColor,
                    ),
                  ),
                ];
              },
              body: TabBarView(
                controller: _tabController,
                children: List.generate(3, (i) {
                  final isInit = isInitialized.value;
                  log("is Initialized : $isInit");

                  if (transactionList.value.isEmpty && !isInit) {
                    return SizedBox(
                      child: Center(
                        child: SizedBox(
                            width: 40,
                            height: 40,
                            child: LoadingAnimationWidget.discreteCircle(
                                color: colors.themeColor,
                                size:
                                    40) //LoadingAnimationWidget.flickr(leftDotColor: colors.greenColor, rightDotColor: colors.redColor, size: 40),
                            ),
                      ),
                    );
                  }

                  return CheckMarkIndicator(
                      style: CheckMarkStyle(
                          loading: CheckMarkColors(
                              content: colors.primaryColor,
                              background: colors.themeColor),
                          success: CheckMarkColors(
                              content: colors.textColor,
                              background: colors.greenColor),
                          error: CheckMarkColors(
                              content: colors.textColor,
                              background: colors.redColor)),
                      onRefresh: fetchRecentTransactions,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 30),
                        child: ListView.separated(
                            separatorBuilder: (context, index) => Padding(
                                  padding: const EdgeInsets.only(left: 70),
                                  child: Divider(
                                    color: colors.primaryColor,
                                    thickness: 1,
                                  ),
                                ),
                            shrinkWrap: true,
                            itemCount: transactionsList(i).length + 1,
                            itemBuilder: (BuildContext listCtx, index) {
                              if (index == transactionsList(i).length) {
                                return Align(
                                  alignment: Alignment.topCenter,
                                  child: Container(
                                    height: 70,
                                    margin: const EdgeInsets.only(top: 30),
                                    decoration: BoxDecoration(
                                      borderRadius:
                                          BorderRadius.circular(roundedOf(15)),
                                    ),
                                    child: Align(
                                        alignment: Alignment.center,
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              "Cannot find your transaction ? ",
                                              style: textTheme.bodyMedium
                                                  ?.copyWith(
                                                      color: colors.textColor
                                                          .withOpacity(0.7)),
                                            ),
                                            InkWell(
                                              onTap: () async {
                                                if (currentCrypto.isNative) {
                                                  await launchUrl(Uri.parse(
                                                      "${currentCrypto.explorers![0]}/address/${currentAccount.addressByToken(currentCrypto)}"));
                                                } else {
                                                  await launchUrl(Uri.parse(
                                                      "${currentCrypto.network?.explorers![0]}/address/${currentAccount.addressByToken(currentCrypto)}"));
                                                }
                                              },
                                              child: Text(
                                                "Check explorer",
                                                style: textTheme.bodyMedium
                                                    ?.copyWith(
                                                        color:
                                                            colors.themeColor,
                                                        fontSize:
                                                            fontSizeOf(14)),
                                              ),
                                            )
                                          ],
                                        )),
                                  ),
                                );
                              }

                              final transaction = transactionsList(i)[index];

                              final isFrom =
                                  transaction.from.trim().toLowerCase() ==
                                      currentAccount
                                          .addressByToken(currentCrypto)
                                          .trim()
                                          .toLowerCase();
                              return TransactionsListElement(
                                roundedOf: roundedOf,
                                fontSizeOf: fontSizeOf,
                                colors: colors,
                                surfaceTintColor: colors.grayColor,
                                isFrom: isFrom,
                                tr: transaction,
                                textColor: colors.textColor,
                                token: currentCrypto,
                              );
                            }),
                      ));
                }),
              ),
            )));
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
