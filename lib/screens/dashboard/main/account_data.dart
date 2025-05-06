import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';
import 'package:moment_dart/moment_dart.dart';
import 'package:moonwallet/custom/web3_webview/lib/utils/loading.dart';
import 'package:moonwallet/logger/logger.dart';
import 'package:moonwallet/notifiers/providers.dart';
import 'package:moonwallet/types/account_related_types.dart';
import 'package:moonwallet/utils/number_formatter.dart';
import 'package:moonwallet/service/web3_interactions/evm/transaction_request_manager.dart';
import 'package:moonwallet/service/external_data/transactions.dart';
import 'package:moonwallet/types/types.dart';
import 'package:moonwallet/utils/colors.dart';
import 'package:moonwallet/widgets/app_bar_title.dart';
import 'package:moonwallet/widgets/charts_/line_chart.dart';
import 'package:moonwallet/widgets/screen_widgets/crypto_picture.dart';
import 'package:moonwallet/widgets/view/transactions.dart';

class AccountDataView extends StatefulHookConsumerWidget {
  const AccountDataView({super.key});

  @override
  ConsumerState<AccountDataView> createState() => _AccountDataViewState();
}

class _AccountDataViewState extends ConsumerState<AccountDataView>
    with SingleTickerProviderStateMixin {
  List<Crypto> cryptos = [];
  List<Asset> assets = [];
  PublicAccount? account;
  AppColors colors = AppColors.defaultTheme;
  late TabController _tabController;
  bool isTabInit = false;
  List<EsTransaction> transactions = [];
  List<List<EsTransaction>> allTransactions = [];
  late InternetConnection internetChecker;
  double progress = 0;
  bool isTransactionsLoading = true;
  int selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    getSavedTheme();
  }

  Future<void> getSavedTheme() async {
    final manager = ColorsManager();
    internetChecker = InternetConnection();

    final savedTheme = await manager.getDefaultTheme();
    setState(() {
      colors = savedTheme;
    });
  }

  double calculateTotal(List<EsTransaction> transactions, int action) {
    final decimals = cryptos[_tabController.index].decimals;
    try {
      switch (action) {
        case 0:
          final transactionsReceived = transactions
              .where((trx) =>
                  trx.from.trim().toLowerCase() !=
                  account?.evmAddress.trim().toLowerCase())
              .toList();
          log("Transactions received ${transactionsReceived.length}");
          final result = transactionsReceived.fold(
              BigInt.zero,
              (prev, c) =>
                  ((prev) + ((BigInt.tryParse(c.value)) ?? BigInt.zero)));
          return result / BigInt.from(10).pow(decimals);
        case 1:
          final transactionsReceived = transactions
              .where((trx) =>
                  trx.from.trim().toLowerCase() ==
                  account?.evmAddress.trim().toLowerCase())
              .toList();
          log("Transactions received ${transactionsReceived.length}");
          final result = transactionsReceived.fold(
              BigInt.zero,
              (prev, c) =>
                  ((prev) + (BigInt.tryParse(c.value) ?? BigInt.zero)));
          return result / BigInt.from(10).pow(decimals);

        default:
          return 0;
      }
    } catch (e) {
      logError(e.toString());
      return 0.00;
    }
  }

  Future<void> getAllTransactions(List<Crypto> cryptos) async {
    try {
      final totalActionsCount = cryptos.length;
      int currentNumber = 0;

      List<List<EsTransaction>> allTrx = [];

      for (final c in cryptos) {
        currentNumber++;

        final tr = await getTransactions(c);

        allTrx.add(tr);
        setState(() {
          progress = (currentNumber * 100 / totalActionsCount / 100);
          log(progress.toString());
        });
      }

      setState(() {
        allTransactions = allTrx;
        progress = 0;
        isTransactionsLoading = false;
      });
    } catch (e) {
      logError(e.toString());
    }
  }

  Future<void> fetchTransactions(Crypto crypto) async {
    try {
      if (account == null) {
        return;
      }
      if (account!.keyId.isEmpty || crypto.cryptoId.isEmpty) {
        logError("Function called before init");
        return;
      }
      final storage = TransactionStorage(
          cryptoId: crypto.cryptoId, accountKey: account!.keyId);
      if ((await internetChecker.internetStatus
          .then((st) => st == InternetStatus.disconnected))) {
        return;
      }

      final userTransactions = await TransactionRequestManager()
          .getAllTransactions(crypto: crypto, address: account!.evmAddress);

      if (userTransactions.isNotEmpty) {
        userTransactions.sort((a, b) => b.timeStamp.compareTo(a.timeStamp));
        if (!mounted) return;

        log("User transactions ${userTransactions.firstOrNull?.toJson()}");
        await storage.patchTransactions(userTransactions);
      }
    } catch (e) {
      logError('Error getting transactions: $e');
    }
  }

  Future<List<EsTransaction>> getTransactions(Crypto crypto) async {
    try {
      if (account?.keyId.isEmpty == true || crypto.cryptoId.isEmpty) {
        logError("Function called before init");
        return [];
      }
      final storage = TransactionStorage(
          cryptoId: crypto.cryptoId, accountKey: account?.keyId ?? "");

      final savedTransactions = await storage.getTransactions();
      log("Saved transactions:${savedTransactions.length} ");

      if (savedTransactions.isNotEmpty) {
        return savedTransactions;
      }

      return [];
    } catch (e) {
      logError(e.toString());
      return [];
    }
  }

  List<(DateTime, double)> getTransactionsData(
      List<EsTransaction> transactions, int action) {
    final decimals = cryptos[_tabController.index].decimals;

    try {
      final transactionsToReturn = action == 0
          ? transactions.where((trx) =>
              trx.from.trim().toLowerCase() !=
              account?.evmAddress.trim().toLowerCase())
          : transactions.where((trx) =>
              trx.from.trim().toLowerCase() ==
              account?.evmAddress.trim().toLowerCase());
      return transactionsToReturn.map((item) {
        return (
          DateTime.fromMillisecondsSinceEpoch(
              (int.tryParse(item.timeStamp) ?? 0) * 1000),
          (BigInt.tryParse(item.value) ?? BigInt.zero) /
              BigInt.from(10).pow(decimals)
        );
      }).toList();
    } catch (e) {
      logError(e.toString());
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    final accountAsync = ref.watch(currentAccountProvider);
    final savedCryptoAsync = ref.watch(savedCryptosProviderNotifier);
    final assetsAsync = ref.watch(assetsNotifierProvider);
    final textTheme = TextTheme.of(context);
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

    double roundedOf(double size) {
      return size * uiConfig.value.styles.radiusScaleFactor;
    }

    accountAsync.whenData((data) => setState(() {
          account = data;
        }));
    savedCryptoAsync.whenData((data) {
      if (allTransactions.isEmpty) {
        getAllTransactions(data);
      }

      setState(() {
        cryptos = data.where((d) => d.canDisplay == true).toList();
        _tabController = TabController(length: cryptos.length, vsync: this);
      });
    });
    assetsAsync.whenData((data) => setState(() {
          assets = data;
        }));

    if (cryptos.isEmpty || allTransactions.isEmpty || isTransactionsLoading) {
      return Material(
        color: colors.primaryColor,
        child: Center(
          child: CircularProgressIndicator(
            color: colors.themeColor,
            value: progress,
          ),
        ),
      );
    }
    return Scaffold(
      backgroundColor: colors.primaryColor,
      appBar: AppBar(
        centerTitle: true,
        leading: IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(
              Icons.chevron_left,
              color: colors.textColor.withValues(alpha: 0.7),
            )),
        title: AppBarTitle(title: "Statistics", colors: colors),
        backgroundColor: colors.primaryColor,
        surfaceTintColor: colors.secondaryColor,
        bottom: TabBar(
          tabAlignment: TabAlignment.start,
          onTap: (value) async {
            log("Fetching data for ${cryptos[value].symbol}");
          },
          dividerColor: Colors.transparent,
          unselectedLabelStyle: textTheme.bodyMedium
              ?.copyWith(color: colors.textColor.withValues(alpha: 0.2)),
          physics: BouncingScrollPhysics(),
          labelColor: colors.textColor,
          labelStyle: textTheme.bodyMedium
              ?.copyWith(color: colors.themeColor, fontWeight: FontWeight.bold),
          isScrollable: true,
          controller: _tabController,
          tabs: cryptos.map((e) {
            return Tab(
                icon: Row(
              spacing: 10,
              children: [
                CryptoPicture(crypto: e, size: 30, colors: colors),
                Text(e.symbol)
              ],
            ));
          }).toList(),
        ),
      ),
      body: TabBarView(
          physics: NeverScrollableScrollPhysics(),
          controller: _tabController,
          children: List.generate(cryptos.length, (i) {
            final crypto = cryptos[i];
            final sortedTransactions = [...allTransactions[i]]
              ..sort((a, b) => b.timeStamp.compareTo(a.timeStamp));

            final fromTimestamp =
                int.tryParse(sortedTransactions.lastOrNull?.timeStamp ?? "") ??
                    0;

            final fromDate =
                DateTime.fromMillisecondsSinceEpoch(fromTimestamp * 1000);

            return RefreshIndicator(
              onRefresh: () async {
                final indexToReload = _tabController.index;
                await fetchTransactions(cryptos[indexToReload])
                    .withLoading(context, colors);
                await getAllTransactions(cryptos).withLoading(context, colors);
              },
              child: SingleChildScrollView(
                child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      spacing: 5,
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(0),
                          child: Align(
                            alignment: Alignment.topLeft,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              spacing: 5,
                              children: [
                                Text(
                                  "${account?.walletName}".toUpperCase(),
                                  style: textTheme.headlineMedium?.copyWith(
                                      color: colors.textColor,
                                      fontWeight: FontWeight.bold,
                                      fontSize: fontSizeOf(22)),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  "This is a statistic calculated from blockchain transactions, the amount you've received and sent, and your financial progress. Some data may be missing.",
                                  style: textTheme.bodyMedium?.copyWith(
                                      color: colors.textColor
                                          .withValues(alpha: 0.4),
                                      fontSize: fontSizeOf(12)),
                                )
                              ],
                            ),
                          ),
                        ),
                        SizedBox(
                          height: 10,
                        ),
                        Align(
                          alignment: Alignment.topLeft,
                          child: Text(
                            "From ${fromDate.toMoment().date}",
                            style: textTheme.bodyMedium?.copyWith(
                              color: colors.textColor,
                              fontSize: fontSizeOf(13),
                            ),
                          ),
                        ),
                        SizedBox(
                          height: 10,
                        ),
                        ToggleButtons(
                          borderColor: colors.textColor.withValues(alpha: 0.2),
                          borderWidth: 1,
                          fillColor: selectedIndex == 1
                              ? colors.redColor.withValues(alpha: 0.3)
                              : colors.themeColor.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(8),
                          constraints: const BoxConstraints(
                              minHeight: 40.0, minWidth: 80.0),
                          selectedBorderColor: selectedIndex == 1
                              ? colors.redColor
                              : colors.themeColor,
                          selectedColor: selectedIndex == 1
                              ? colors.redColor
                              : colors.themeColor,
                          onPressed: (index) {
                            setState(() {
                              selectedIndex = index;
                            });
                          },
                          isSelected: [selectedIndex == 0, selectedIndex == 1],
                          children: [
                            Text(
                              "Received",
                              style: textTheme.bodyMedium?.copyWith(
                                  color: colors.textColor,
                                  fontSize: fontSizeOf(14)),
                            ),
                            Text("Sent",
                                style: textTheme.bodyMedium?.copyWith(
                                    color: colors.textColor,
                                    fontSize: fontSizeOf(14)))
                          ],
                        ),
                        SizedBox(
                          height: 10,
                        ),
                        Container(
                          padding: const EdgeInsets.all(0),
                          decoration: BoxDecoration(
                              borderRadius:
                                  BorderRadius.circular(roundedOf(10))),
                          child: AspectRatio(
                            aspectRatio: 1.7,
                            child: CustomLineChart(
                              isCrypto: true,
                              symbol: crypto.symbol,
                              colors: colors,
                              isPositive: selectedIndex == 0,
                              chartData: getTransactionsData(
                                  allTransactions[i], selectedIndex),
                              borderData: FlBorderData(
                                  show: true,
                                  border: Border.all(
                                      width: 1, color: colors.grayColor)),
                            ),
                          ),
                        ),
                        SizedBox(
                          height: 15,
                        ),
                        Padding(
                          padding: const EdgeInsets.all(0),
                          child: Column(
                            spacing: 10,
                            children: [
                              TotalText(
                                  fontSizeOf: fontSizeOf,
                                  colors: colors,
                                  title: "Total Received".toUpperCase(),
                                  amount:
                                      ("+${NumberFormatter().formatCrypto(value: calculateTotal(allTransactions[i], 0))}"),
                                  symbol: crypto.symbol),
                              TotalText(
                                  fontSizeOf: fontSizeOf,
                                  colors: colors,
                                  title: "Total Sent".toUpperCase(),
                                  amount:
                                      ("-${NumberFormatter().formatCrypto(value: calculateTotal(allTransactions[i], 1))}"),
                                  symbol: crypto.symbol)
                            ],
                          ),
                        ),
                        SizedBox(
                          height: 10,
                        ),
                        Divider(
                          color: colors.textColor.withValues(alpha: 0.1),
                        ),
                        Align(
                          alignment: Alignment.topLeft,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Transactions".toUpperCase(),
                                style: textTheme.headlineMedium?.copyWith(
                                    color: colors.textColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: fontSizeOf(18)),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              SizedBox(
                                height: 15,
                              ),
                              AspectRatio(
                                aspectRatio: 0.8,
                                child: ListView.builder(
                                    shrinkWrap: true,
                                    itemCount: allTransactions[i].length,
                                    itemBuilder: (BuildContext listCtx, index) {
                                      final transaction =
                                          allTransactions[i][index];

                                      final isFrom = transaction.from
                                              .trim()
                                              .toLowerCase() ==
                                          account?.evmAddress
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
                                        currentCrypto: crypto,
                                      );
                                    }),
                              )
                            ],
                          ),
                        )
                      ],
                    )),
              ),
            );
          })),
    );
  }

  @override
  void dispose() {
    _tabController
        .dispose(); // Dispose the TabController when the widget is disposed
    super.dispose();
  }
}

class TotalText extends StatelessWidget {
  final String title;
  final String amount;
  final String symbol;
  final AppColors colors;
  final DoubleFactor fontSizeOf;
  const TotalText(
      {super.key,
      required this.colors,
      required this.title,
      required this.amount,
      required this.symbol,
      required this.fontSizeOf});

  @override
  Widget build(BuildContext context) {
    final textTheme = TextTheme.of(context);

    return Card(
      shadowColor: Colors.transparent,
      color: colors.secondaryColor,
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          spacing: 5,
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: textTheme.headlineMedium?.copyWith(
                color: colors.textColor,
                fontSize: fontSizeOf(12),
              ),
            ),
            Row(
              spacing: 5,
              children: [
                Text(
                  amount,
                  style: textTheme.headlineMedium?.copyWith(
                      fontSize: fontSizeOf(22),
                      fontWeight: FontWeight.bold,
                      color: colors.textColor.withValues(alpha: 0.7)),
                ),
                Text(symbol,
                    style: textTheme.headlineMedium?.copyWith(
                        fontSize: fontSizeOf(25),
                        color: colors.textColor.withValues(alpha: 0.4),
                        fontWeight: FontWeight.bold))
              ],
            )
          ],
        ),
      ),
    );
  }
}
