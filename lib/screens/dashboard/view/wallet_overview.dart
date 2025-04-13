// ignore_for_file: deprecated_member_use

import 'dart:ui';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
// ignore: depend_on_referenced_packages

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:liquid_pull_to_refresh/liquid_pull_to_refresh.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:moonwallet/custom/candlesticks/lib/candlesticks.dart';
import 'package:moonwallet/logger/logger.dart';
import 'package:moonwallet/screens/dashboard/view/recieve.dart';
import 'package:moonwallet/screens/dashboard/view/send.dart';
import 'package:moonwallet/service/crypto_request_manager.dart';
import 'package:moonwallet/service/crypto_storage_manager.dart';
import 'package:moonwallet/service/number_formatter.dart';
import 'package:moonwallet/service/price_manager.dart';
import 'package:moonwallet/service/transaction_request_manager.dart';
import 'package:moonwallet/service/transactions.dart';
import 'package:moonwallet/service/wallet_saver.dart';
import 'package:moonwallet/service/web3_interaction.dart';
import 'package:moonwallet/types/types.dart';
import 'package:moonwallet/utils/colors.dart';
import 'package:moonwallet/utils/crypto.dart';
import 'package:moonwallet/utils/prefs.dart';
import 'package:moonwallet/utils/themes.dart';
import 'package:moonwallet/widgets/crypto_picture.dart';
import 'package:moonwallet/widgets/view/other_options.dart';
import 'package:moonwallet/widgets/view/show_crypto_candle_data.dart';
import 'package:moonwallet/widgets/view/transactions.dart';
import 'package:moonwallet/widgets/view/view_button_action.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:url_launcher/url_launcher.dart';

class WalletViewScreen extends StatefulWidget {
  final WidgetInitialData initData;
  const WalletViewScreen({super.key, required this.initData});

  @override
  State<WalletViewScreen> createState() => _WalletViewScreenState();
}

class _WalletViewScreenState extends State<WalletViewScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<EsTransaction> transactions = [];
  PublicData currentAccount = PublicData(
      keyId: "",
      creationDate: 0,
      walletName: "",
      address: "",
      isWatchOnly: false);

  List<PublicData> accounts = [];
  List<Crypto> reorganizedCrypto = [];
  String cryptoId = "";

  final web3Manager = WalletSaver();
  bool isScrollingToTheBottom = false;
  final encryptService = EncryptService();
  final priceManager = PriceManager();
  final web3InteractManager = Web3InteractionManager();
  final publicDataManager = PublicDataManager();
  final formatter = NumberFormat("0.##############", "en_US");
  bool isDarkMode = false;
  final cryptoStorageManager = CryptoStorageManager();
  final ScrollController _scrollController = ScrollController();

  List<Candle> cryptoData = [];

  Crypto currentCrypto = Crypto(
      name: "",
      color: Colors.transparent,
      type: CryptoType.network,
      valueUsd: 0,
      cryptoId: "",
      canDisplay: false,
      symbol: "");

  double userLastBalance = 0;

  double tokenBalance = 0;
  double totalBalanceUsd = 0;

  bool isBalanceLoading = true;
  bool isTransactionLoading = true;

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

  Future<void> getTokenBalance(
      {required PublicData account, required Crypto crypto}) async {
    try {
      final userBalance = await web3InteractManager.getBalance(account, crypto);
      if (!mounted) return;

      setState(() {
        tokenBalance = userBalance;
        isBalanceLoading = false;
        log("balance $tokenBalance");
      });
    } catch (e) {
      logError(e.toString());
      isBalanceLoading = false;
    }
  }

  String formatUsd(String value) {
    return NumberFormatter().formatUsd(value: value);
  }

  String formatCryptoValue(String value) {
    return NumberFormatter().formatCrypto(value: value);
  }

  Future<void> fetchTransactions() async {
    try {
      if (currentAccount.keyId.isEmpty || currentCrypto.cryptoId.isEmpty) {
        logError("Function called before init");
        return;
      }
      final storage = TransactionStorage(
          cryptoId: currentCrypto.cryptoId, accountKey: currentAccount.keyId);
      final savedTransactions = await storage.getTransactions();
      log("Saved transactions:${savedTransactions.length} ");

      if (savedTransactions.isNotEmpty) {
        if (!mounted) return;
        setState(() {
          transactions = savedTransactions;
          isTransactionLoading = false;
        });
      }

      final userTransactions = await TransactionRequestManager()
          .getAllTransactions(
              crypto: currentCrypto, address: currentAccount.address);

      if (userTransactions.isNotEmpty) {
        userTransactions.sort((a, b) => b.timeStamp.compareTo(a.timeStamp));
        if (!mounted) return;

        setState(() {
          transactions = userTransactions;
          isTransactionLoading = false;
        });

        await storage.saveTransactions(transactions);
      }
    } catch (e) {
      logError('Error getting transactions: $e');
      isTransactionLoading = false;
    } finally {
      setState(() {
        isTransactionLoading = false;
      });
    }
  }

  Future<double> getBalanceUsd(Crypto crypto) async {
    try {
      final price = await getPrice(crypto.binanceSymbol ?? "");
      final balanceEth =
          await web3InteractManager.getBalance(currentAccount, crypto);
      log("Balance eth $balanceEth");
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
        totalBalanceUsd = widget.initData.initialBalanceUsd ?? 0;
        isBalanceLoading = false;
      }
      if (widget.initData.initialBalanceCrypto != null) {
        tokenBalance = widget.initData.initialBalanceCrypto ?? 0;
      }
    });

    refresh();
  }

  Future<void> refresh() async {
    try {
      if (!mounted) return;
      await Future.wait([
        fetchTransactions(),
        getBalanceUsdOfAccount(widget.initData.crypto),
        getTokenBalance(account: currentAccount, crypto: currentCrypto),
      ]);
    } catch (e) {
      logError(e.toString());
    }
  }

  Future<void> getBalanceUsdOfAccount(Crypto currentCrypto) async {
    try {
      final balance = await getBalanceUsd(currentCrypto);
      if (!mounted) return;
      setState(() {
        totalBalanceUsd = balance;
      });
    } catch (e) {
      logError(e.toString());
    }
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

  List<EsTransaction> getFilteredTransactions() {
    final List<EsTransaction> filteredTransactions = transactions;
    filteredTransactions.sort((a, b) => b.timeStamp.compareTo(a.timeStamp));
    return filteredTransactions;
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

  List<EsTransaction> transactionsList(int i) {
    if (i == 0) {
      return getFilteredTransactions();
    } else if (i == 1) {
      return getFilteredTransactions()
          .where((tr) =>
              tr.from.toLowerCase().trim() !=
              currentAccount.address.toLowerCase().trim())
          .toList();
    } else if (i == 2) {
      return getFilteredTransactions()
          .where((tr) =>
              tr.from.toLowerCase().trim() ==
              currentAccount.address.toLowerCase().trim())
          .toList();
    }

    return [];
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    final textTheme = Theme.of(context).textTheme;
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
          title: Text(
            currentCrypto.symbol,
            style: textTheme.bodyMedium?.copyWith(
                color: colors.textColor,
                fontWeight: FontWeight.bold,
                fontSize: 22),
          ),
          actions: [
            IconButton(
              onPressed: () {
                showCryptoCandleModal(
                    context: context,
                    colors: colors,
                    currentCrypto: currentCrypto);
              },
              icon: Icon(
                Icons.candlestick_chart_rounded,
                color: colors.textColor,
              ),
            ),
            IconButton(
              onPressed: () {
                showOtherOptions(
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
        body: NestedScrollView(
          headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
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
                                  size: 65,
                                  colors: colors),
                            ),
                            SizedBox(
                              height: 10,
                            ),
                            Skeletonizer(
                                enabled: isBalanceLoading,
                                child: SizedBox(
                                    width: width * 0.5,
                                    child: Center(
                                        child: Text(
                                      (formatCryptoValue(
                                          tokenBalance.toString())),
                                      overflow: TextOverflow.clip,
                                      maxLines: 1,
                                      style: textTheme.bodyMedium?.copyWith(
                                          color: colors.textColor,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 24),
                                    )))),
                            SizedBox(
                              height: 5,
                            ),
                            Skeletonizer(
                                enabled: isBalanceLoading,
                                child: Text(
                                  "= \$ ${formatUsd((totalBalanceUsd).toString())}",
                                  style: textTheme.bodySmall?.copyWith(
                                      color: colors.textColor.withOpacity(0.5),
                                      fontSize: 14),
                                )),
                            SizedBox(
                              height: 15,
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                WalletViewButtonAction(
                                    textColor: colors.textColor,
                                    onTap: () {
                                      Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                              builder: (ctx) =>
                                                  SendTransactionScreen(
                                                    initData: WidgetInitialData(
                                                        account: currentAccount,
                                                        crypto: currentCrypto,
                                                        colors: colors,
                                                        initialBalanceCrypto:
                                                            tokenBalance,
                                                        initialBalanceUsd:
                                                            totalBalanceUsd),
                                                  )));
                                    },
                                    bottomText: "Send",
                                    icon: Icons.arrow_upward),
                                WalletViewButtonAction(
                                    textColor: colors.textColor,
                                    onTap: () {
                                      Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                              builder: (ctx) => ReceiveScreen(
                                                    initData: WidgetInitialData(
                                                        account: currentAccount,
                                                        crypto: currentCrypto,
                                                        colors: colors,
                                                        initialBalanceCrypto:
                                                            tokenBalance,
                                                        initialBalanceUsd:
                                                            totalBalanceUsd),
                                                  )));
                                    },
                                    bottomText: "Receive",
                                    icon: Icons.arrow_downward),
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
                    labelColor: colors.textColor,
                    unselectedLabelColor: colors.grayColor,
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
              if (isTransactionLoading) {
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

              return getFilteredTransactions().isEmpty
                  ? Align(
                      alignment: Alignment.topCenter,
                      child: Container(
                        height: 70,
                        margin: const EdgeInsets.only(top: 30),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Align(
                            alignment: Alignment.center,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  "Cannot find your transaction ? ",
                                  style: textTheme.bodyMedium?.copyWith(
                                      color: colors.textColor.withOpacity(0.7)),
                                ),
                                InkWell(
                                  onTap: () async {
                                    if (currentCrypto.type ==
                                        CryptoType.network) {
                                      await launchUrl(Uri.parse(
                                          "${currentCrypto.explorer}/address/${currentAccount.address}"));
                                    } else {
                                      await launchUrl(Uri.parse(
                                          "${currentCrypto.network?.explorer}/address/${currentAccount.address}"));
                                    }
                                  },
                                  child: Text(
                                    "Check explorer",
                                    style: textTheme.bodyMedium
                                        ?.copyWith(color: colors.themeColor),
                                  ),
                                )
                              ],
                            )),
                      ),
                    )
                  : LiquidPullToRefresh(
                      showChildOpacityTransition: false,
                      color: colors.themeColor,
                      backgroundColor: colors.textColor.withOpacity(0.8),
                      onRefresh: () async {
                        await refresh();
                      },
                      child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: transactionsList(i).length,
                          itemBuilder: (BuildContext listCtx, index) {
                            final transaction = transactionsList(i)[index];

                            final isFrom =
                                transaction.from.trim().toLowerCase() ==
                                    currentAccount.address.trim().toLowerCase();
                            return TransactionsListElement(
                              colors: colors,
                              surfaceTintColor: colors.grayColor,
                              isFrom: isFrom,
                              tr: transaction,
                              textColor: colors.textColor,
                              secondaryColor: colors.themeColor,
                              darkColor: colors.primaryColor,
                              primaryColor: colors.primaryColor,
                              currentNetwork: currentCrypto,
                            );
                          }));
            }),
          ),
        ));
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
