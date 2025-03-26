// ignore_for_file: deprecated_member_use

import 'dart:convert';
import 'dart:ui';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
// ignore: depend_on_referenced_packages
import 'package:http/http.dart' as http;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:liquid_pull_to_refresh/liquid_pull_to_refresh.dart';
import 'package:moonwallet/custom/candlesticks/lib/candlesticks.dart';
import 'package:moonwallet/logger/logger.dart';
import 'package:moonwallet/main.dart';
import 'package:moonwallet/service/crypto_storage_manager.dart';
import 'package:moonwallet/service/number_formatter.dart';
import 'package:moonwallet/service/price_manager.dart';
import 'package:moonwallet/service/transactions.dart';
import 'package:moonwallet/service/wallet_saver.dart';
import 'package:moonwallet/service/web3_interaction.dart';
import 'package:moonwallet/types/types.dart';
import 'package:moonwallet/utils/colors.dart';
import 'package:moonwallet/utils/constant.dart';
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
  final String cryptoId;
  const WalletViewScreen({super.key, required this.cryptoId});

  @override
  State<WalletViewScreen> createState() => _WalletViewScreenState();
}

class _WalletViewScreenState extends State<WalletViewScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<BscScanTransaction> transactions = [];
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

  double totalBalanceUsd = 0;
  Crypto currentCrypto = cryptos[0];
  double userLastBalance = 0;
  double balance = 0;
  bool isBalanceLoading = true;

  AppColors colors = AppColors(
      primaryColor: Color(0XFF0D0D0D),
      themeColor: Colors.greenAccent,
      greenColor: Colors.greenAccent,
      secondaryColor: Color(0XFF121212),
      grayColor: Color(0XFF353535),
      textColor: Colors.white,
      redColor: Colors.pinkAccent);
  Themes themes = Themes();
  String savedThemeName = "";
  Future<void> getSavedTheme() async {
    try {
      final manager = ColorsManager();
      final savedName = await manager.getThemeName();
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

  Future<void> getSavedWallets() async {
    try {
      final savedData = await web3Manager.getPublicData();

      final lastAccount = await encryptService.getLastConnectedAddress();

      if (savedData != null && lastAccount != null) {
        for (final account in savedData) {
          final newAccount = PublicData.fromJson(account);
          setState(() {
            accounts.add(newAccount);
          });
        }
      }

      for (final account in accounts) {
        if (account.address == lastAccount) {
          currentAccount = account;

          break;
        } else {
          log("Not account found");
          currentAccount = accounts[0];
        }
      }
    } catch (e) {
      logError('Error getting saved wallets: $e');
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

  Future<void> getBalanceOfUser(
      {required PublicData account, required Crypto crypto}) async {
    try {
      final userBalance = await web3InteractManager.getBalance(account, crypto);
      setState(() {
        balance = userBalance;
        isBalanceLoading = false;
        log("Shib balance $balance");
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

  Future<void> getTransactions() async {
    try {
      final transactionStorage = TransactionStorage(
          cryptoId: currentCrypto.cryptoId, accountKey: currentAccount.keyId);
      final trx = await transactionStorage.getTransactions();
      setState(() {
        transactions = trx;
      });
      fetchTransactions();
    } catch (e) {
      logError(e.toString());
    }
  }

  Future<void> fetchTransactions() async {
    try {
      List<BscScanTransaction> allTransactions = [];
      String key = "";
      String baseUrl = "";
      if (currentCrypto.type == CryptoType.token) {
        key = currentCrypto.network?.apiKey ?? "";
        baseUrl = currentCrypto.network?.apiBaseUrl ?? "";
      } else {
        key = currentCrypto.apiKey ?? "";
        baseUrl = currentCrypto.apiBaseUrl ?? "";
      }
      String internalUrl = "";
      String trUrl = "";
      if (currentCrypto.type == CryptoType.token) {
        trUrl =
            "https://$baseUrl?module=account&action=tokentx&contractaddress=${currentCrypto.contractAddress}&address=${currentAccount.address.trim()}&startblock=0&endblock=latest&page=1&offset=200&sort=desc&apikey=$key";
      } else {
        internalUrl =
            "https://$baseUrl?module=account&action=txlistinternal&address=${currentAccount.address.trim()}&startblock=0&endblock=latest&page=1&offset=200&sort=desc&apikey=$key";
        trUrl =
            "https://$baseUrl?module=account&action=txlist&address=${currentAccount.address.trim()}&startblock=0&endblock=latest&page=1&offset=200&sort=desc&apikey=$key";
      }
      List<dynamic> results = [];
      try {
        results = await Future.wait([
          http.get(Uri.parse(trUrl)),
          if (currentCrypto.type == CryptoType.network)
            http.get(Uri.parse(internalUrl))
        ]);
      } catch (e) {
        logError("Error getting transaction: $e");
      }

      final trRequest = results[0];
      if (internalUrl.isNotEmpty && currentCrypto.type != CryptoType.token) {
        final internalTrResult = results[1];
        log("tr request status : ${trRequest.statusCode}");

        if (internalTrResult.statusCode == 200) {
          final List<dynamic> dataJson =
              (json.decode(internalTrResult.body))["result"];
          log((json.decode(internalTrResult.body))["result"]
              .runtimeType
              .toString());
          List<BscScanTransaction> fTransactions = [];
          if (dataJson.isNotEmpty) {
            for (final data in dataJson) {
              final from = data["from"];
              final to = data["to"];
              final value = data["value"];
              final timeStamp = data["timeStamp"];
              final transactionHash = data["hash"];
              final blockNumber = data["blockNumber"];
              fTransactions.add(BscScanTransaction(
                  from: from,
                  to: to,
                  value: value,
                  timeStamp: timeStamp,
                  hash: transactionHash,
                  blockNumber: blockNumber));
            }
            allTransactions.addAll(fTransactions);
          } else {
            logError("No transactions found");

            setState(() {
              transactions = [];
            });
          }
        } else {
          logError("Error getting transactions");
        }
      }
      if (trUrl.isNotEmpty) {
        if (trRequest.statusCode == 200) {
          final List<dynamic> dataJson =
              (json.decode(trRequest.body))["result"];
          log("DataJson $dataJson");

          List<BscScanTransaction> fTransactions = [];

          if (dataJson.isNotEmpty) {
            for (final data in dataJson) {
              final from = data["from"];
              final to = data["to"];
              final value = data["value"];
              final timeStamp = data["timeStamp"];
              final transactionHash = data["hash"];
              final blockNumber = data["blockNumber"];

              fTransactions.add(BscScanTransaction(
                  from: from,
                  to: to,
                  value: value,
                  timeStamp: timeStamp,
                  hash: transactionHash,
                  blockNumber: blockNumber));
            }
            allTransactions.addAll(fTransactions);
          } else {
            logError("No transactions found");
          }
        }
      }

      if (allTransactions.isNotEmpty) {
        //  final ts = TransactionStorage(cryptoId: currentCrypto.cryptoId, accountKey: currentAccount.keyId) ;
        allTransactions.sort((a, b) => b.timeStamp.compareTo(a.timeStamp));
        setState(() {
          transactions = allTransactions;
        });
        /* for (final t in allTransactions) {
          await ts.addTransactions(t);
        }
        final newTransactions = await ts.getTransactions();
        setState(() {
          transactions = newTransactions;
        });*/
      }
    } catch (e) {
      logError('Error getting transactions: $e');
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

  void _onScroll() {
    if (_scrollController.position.userScrollDirection ==
        ScrollDirection.forward) {
      log("scroll direction is forward");
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

  Future<void> init() async {
    try {
      await getSavedWallets();
      final savedCrypto =
          await cryptoStorageManager.getSavedCryptos(wallet: currentAccount);
      if (savedCrypto != null) {
        for (final crypto in savedCrypto) {
          if (crypto.cryptoId == widget.cryptoId) {
            setState(() {
              currentCrypto = crypto;
            });
            await getBalanceOfUser(account: currentAccount, crypto: crypto);
          }
        }
      }

      fetchTransactions();
    } catch (e) {
      logError('Error initializing: $e');
    }
  }

  List<BscScanTransaction> getFilteredTransactions() {
    final List<BscScanTransaction> filteredTransactions = transactions;
    filteredTransactions.sort((a, b) => b.timeStamp.compareTo(a.timeStamp));
    return filteredTransactions;
  }

  Future<void> reorganizeCrypto() async {
    final List<Crypto> standardCrypto = cryptos;
    final savedCrypto =
        await cryptoStorageManager.getSavedCryptos(wallet: currentAccount);
    if (savedCrypto == null || savedCrypto.isEmpty) {
      setState(() {
        reorganizedCrypto = standardCrypto;
      });
    } else {
      setState(() {
        reorganizedCrypto = savedCrypto;
      });
    }
  }

  List<BscScanTransaction> transactionsList(int i) {
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
            style: GoogleFonts.roboto(
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
                                      (formatCryptoValue(balance.toString())),
                                      overflow: TextOverflow.clip,
                                      maxLines: 1,
                                      style: GoogleFonts.roboto(
                                          color: colors.textColor,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 24),
                                    )))),
                            SizedBox(
                              height: 5,
                            ),
                            FutureBuilder(
                                future: getBalanceUsd(currentCrypto),
                                builder:
                                    (BuildContext ctx, AsyncSnapshot result) {
                                  if (result.hasData) {
                                    return Text(
                                      "= \$ ${formatUsd((result.data as double).toString())}",
                                      style: GoogleFonts.roboto(
                                          color:
                                              colors.textColor.withOpacity(0.5),
                                          fontSize: 14),
                                    );
                                  } else {
                                    return Skeletonizer(
                                        enabled: isBalanceLoading,
                                        child: Text(
                                          " = \$0.00 ",
                                          style: GoogleFonts.roboto(
                                              color: colors.textColor
                                                  .withOpacity(0.5),
                                              fontSize: 14),
                                        ));
                                  }
                                }),
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
                                      Navigator.pushNamed(
                                          context, Routes.sendScreen,
                                          arguments: ({
                                            "id": currentCrypto.cryptoId
                                          }));
                                    },
                                    bottomText: "Send",
                                    icon: Icons.arrow_upward),
                                WalletViewButtonAction(
                                    textColor: colors.textColor,
                                    onTap: () {
                                      Navigator.pushNamed(
                                          context, Routes.receiveScreen,
                                          arguments: ({
                                            "id": currentCrypto.cryptoId
                                          }));
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
                                  style: GoogleFonts.roboto(
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
                                    style: GoogleFonts.roboto(
                                        color: colors.themeColor),
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
                        await init();
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
