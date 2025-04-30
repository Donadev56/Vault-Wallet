// ignore_for_file: deprecated_member_use

import 'dart:ui';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
// ignore: depend_on_referenced_packages

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:moonwallet/custom/candlesticks/lib/candlesticks.dart';
import 'package:moonwallet/custom/refresh/check_mark.dart';
import 'package:moonwallet/logger/logger.dart';
import 'package:moonwallet/notifiers/providers.dart';
import 'package:moonwallet/screens/dashboard/main/wallet_overview/receive.dart';
import 'package:moonwallet/screens/dashboard/main/wallet_overview/send.dart';
import 'package:moonwallet/service/external_data/crypto_request_manager.dart';
import 'package:moonwallet/service/db/crypto_storage_manager.dart';
import 'package:moonwallet/utils/number_formatter.dart';
import 'package:moonwallet/service/external_data/price_manager.dart';
import 'package:moonwallet/service/web3_interactions/evm/transaction_request_manager.dart';
import 'package:moonwallet/service/external_data/transactions.dart';
import 'package:moonwallet/service/db/wallet_db.dart';
import 'package:moonwallet/service/web3_interactions/evm/eth_interaction_manager.dart';
import 'package:moonwallet/types/types.dart';
import 'package:moonwallet/utils/colors.dart';
import 'package:moonwallet/utils/crypto.dart';
import 'package:moonwallet/utils/prefs.dart';
import 'package:moonwallet/utils/themes.dart';
import 'package:moonwallet/widgets/actions.dart';
import 'package:moonwallet/widgets/app_bar_title.dart';
import 'package:moonwallet/widgets/screen_widgets/crypto_picture.dart';
import 'package:moonwallet/widgets/view/other_options.dart';
import 'package:moonwallet/widgets/view/show_crypto_candle_data.dart';
import 'package:moonwallet/widgets/view/transactions.dart';
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
  List<EsTransaction> transactions = [];
  late InternetConnection internetChecker;
  PublicData currentAccount = PublicData(
      createdLocally: false,
      keyId: "",
      creationDate: 0,
      walletName: "",
      address: "",
      isWatchOnly: false);

  List<PublicData> accounts = [];
  List<Crypto> reorganizedCrypto = [];
  String cryptoId = "";

  final web3Manager = WalletDatabase();
  bool isScrollingToTheBottom = false;
  final encryptService = EncryptService();
  final priceManager = PriceManager();
  final web3InteractManager = EthInteractionManager();
  final publicDataManager = PublicDataManager();
  final cryptoStorageManager = CryptoStorageManager();
  final ScrollController _scrollController = ScrollController();

  List<Candle> cryptoData = [];

  Crypto? currentCrypto;

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
      final result = await priceManager.getTokenMarketData(symbol);
      return result?.currentPrice ?? 0;
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
      if ((await internetChecker.internetStatus
          .then((st) => st == InternetStatus.disconnected))) {
        throw ("Not connected to the internet");
      }
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

  String formatUsd(double value) {
    return NumberFormatter().formatUsd(value: value);
  }

  String formatCryptoValue(double value) {
    return NumberFormatter().formatCrypto(value: value);
  }

  Future<void> fetchTransactions() async {
    if (currentCrypto == null) {
      log("Current crypto not found");
      return;
    }
    try {
      if (currentAccount.keyId.isEmpty || currentCrypto!.cryptoId.isEmpty) {
        logError("Function called before init");
        return;
      }
      final storage = TransactionStorage(
          cryptoId: currentCrypto!.cryptoId, accountKey: currentAccount.keyId);
      final savedTransactions = await storage.getTransactions();
      log("Saved transactions:${savedTransactions.length} ");

      if (savedTransactions.isNotEmpty) {
        if (!mounted) return;
        setState(() {
          transactions = savedTransactions;
          isTransactionLoading = false;
        });
      }

      if ((await internetChecker.internetStatus
          .then((st) => st == InternetStatus.disconnected))) {
        throw ("Not connected to the internet");
      }

      final userTransactions = await TransactionRequestManager()
          .getAllTransactions(
              crypto: currentCrypto!, address: currentAccount.address);

      if (userTransactions.isNotEmpty) {
        userTransactions.sort((a, b) => b.timeStamp.compareTo(a.timeStamp));
        if (!mounted) return;

        setState(() {
          transactions = userTransactions;
          isTransactionLoading = false;
        });
        log("User transactions ${userTransactions.firstOrNull?.toJson()}");
        await storage.patchTransactions(userTransactions);
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
      final price = await getPrice(crypto.cgSymbol ?? "");
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
    internetChecker = InternetConnection();
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
    if (currentCrypto == null) {
      log("Current crypto not found");
      return;
    }
    try {
      if (!mounted) return;

      await Future.wait([
        fetchTransactions(),
        getBalanceUsdOfAccount(widget.initData.crypto),
        getTokenBalance(account: currentAccount, crypto: currentCrypto!),
      ]);
    } catch (e) {
      logError(e.toString());
    }
  }

  Future<void> getBalanceUsdOfAccount(Crypto currentCrypto) async {
    try {
      final balance = await getBalanceUsd(currentCrypto);
      if ((await internetChecker.internetStatus
          .then((st) => st == InternetStatus.disconnected))) {
        throw ("Not connected to the internet");
      }
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

    double iconSizeOf(double size) {
      return size * uiConfig.value.styles.iconSizeScaleFactor;
    }

    double imageSizeOf(double size) {
      return size * uiConfig.value.styles.imageSizeScaleFactor;
    }

    double roundedOf(double size) {
      return size * uiConfig.value.styles.radiusScaleFactor;
    }

    if (currentCrypto == null) {
      return Center(
        child: CircularProgressIndicator(
          color: colors.themeColor,
        ),
      );
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
                Icons.arrow_back,
                color: colors.textColor,
              )),
          title: AppBarTitle(title: currentCrypto!.symbol, colors: colors),
          actions: [
            if (currentCrypto!.cgSymbol != null ||
                currentCrypto!.cgSymbol?.isEmpty == false)
              IconButton(
                onPressed: () {
                  showCryptoCandleModal(
                      fontSizeOf: fontSizeOf,
                      roundedOf: roundedOf,
                      context: context,
                      colors: colors,
                      currentCrypto: currentCrypto!);
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
                    currentCrypto: currentCrypto!);
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
                                  crypto: currentCrypto!,
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
                                  (formatCryptoValue(tokenBalance)),
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
                                  "= \$ ${formatUsd((totalBalanceUsd))}",
                                  style: textTheme.bodySmall?.copyWith(
                                      color: colors.textColor.withOpacity(0.5),
                                      fontSize: fontSizeOf(14)),
                                )),
                            SizedBox(
                              height: 15,
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
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
                                                      account: currentAccount,
                                                      crypto: currentCrypto!,
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
                                                      account: currentAccount,
                                                      crypto: currentCrypto!,
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
                          borderRadius: BorderRadius.circular(roundedOf(15)),
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
                                    if (currentCrypto!.isNative) {
                                      await launchUrl(Uri.parse(
                                          "${currentCrypto!.explorers![0]}/address/${currentAccount.address}"));
                                    } else {
                                      await launchUrl(Uri.parse(
                                          "${currentCrypto!.network?.explorers![0]}/address/${currentAccount.address}"));
                                    }
                                  },
                                  child: Text(
                                    "Check explorer",
                                    style: textTheme.bodyMedium?.copyWith(
                                        color: colors.themeColor,
                                        fontSize: fontSizeOf(14)),
                                  ),
                                )
                              ],
                            )),
                      ),
                    )
                  : CheckMarkIndicator(
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
                              roundedOf: roundedOf,
                              fontSizeOf: fontSizeOf,
                              colors: colors,
                              surfaceTintColor: colors.grayColor,
                              isFrom: isFrom,
                              tr: transaction,
                              textColor: colors.textColor,
                              currentCrypto: currentCrypto!,
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
