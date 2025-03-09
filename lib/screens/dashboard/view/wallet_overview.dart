// ignore_for_file: deprecated_member_use

import 'dart:convert';
import 'dart:ui';
import 'package:candlesticks/candlesticks.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
// ignore: depend_on_referenced_packages
import 'package:http/http.dart' as http;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:moonwallet/logger/logger.dart';
import 'package:moonwallet/main.dart';
import 'package:moonwallet/service/crypto_storage_manager.dart';
import 'package:moonwallet/service/price_manager.dart';
import 'package:moonwallet/service/wallet_saver.dart';
import 'package:moonwallet/service/web3_interaction.dart';
import 'package:moonwallet/types/types.dart';
import 'package:moonwallet/utils/colors.dart';
import 'package:moonwallet/utils/constant.dart';
import 'package:moonwallet/utils/crypto.dart';
import 'package:moonwallet/utils/prefs.dart';
import 'package:moonwallet/utils/themes.dart';
import 'package:moonwallet/widgets/view/transactions.dart';
import 'package:moonwallet/widgets/view/view_button_action.dart';
import 'package:url_launcher/url_launcher.dart';

class WalletViewScreen extends StatefulWidget {
  const WalletViewScreen({super.key});

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
  final encryptService = EncryptService();
  final priceManager = PriceManager();
  final web3InteractManager = Web3InteractionManager();
  final publicDataManager = PublicDataManager();
  final formatter = NumberFormat("0.##############", "en_US");
  bool isDarkMode = false;
  final cryptoStorageManager = CryptoStorageManager();

  List<Candle> cryptoData = [];
  int currentIndex = 0;
  final intervals = [
    '1m',
    '15m',
    '30m',
    '1h',
    '12h',
    '1d',
    '1w',
    '1M',
  ];
  double totalBalanceUsd = 0;
  bool _isInitialized = false;
  Crypto currentCrypto = cryptos[0];
  double userLastBalance = 0;

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

  Future<void> getCryptoData({int index = 0}) async {
    try {
      log("getting crypto data");
      final result = await priceManager.getChartPriceDataUsingBinanceApi(
          currentCrypto.binanceSymbol ?? "${currentCrypto.symbol}USDT",
          intervals[index]);
      if (result.isNotEmpty) {
        setState(() {
          cryptoData = result;
        });
      } else {
        logError("Crypto data is not available");
      }
    } catch (e) {
      logError(e.toString());
    }
  }

  Future<List<Candle>> getCandleData(
      {int index = 0, required Crypto crypto}) async {
    try {
      log("getting crypto data");
      final result = await priceManager.getChartPriceDataUsingBinanceApi(
          crypto.binanceSymbol ?? "${crypto.symbol}USDT", intervals[index]);
      if (result.isNotEmpty) {
        return result;
      } else {
        logError("Crypto data is not available");
        return [];
      }
    } catch (e) {
      logError(e.toString());
      return [];
    }
  }

  Future<void> getTransactions() async {
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
            "https://$baseUrl/api?module=account&action=tokentx&contractaddress=${currentCrypto.contractAddress}&address=${currentAccount.address.trim()}&startblock=0&endblock=latest&page=1&offset=200&sort=desc&apikey=$key";
      } else {
        internalUrl =
            "https://$baseUrl/api?module=account&action=txlistinternal&address=${currentAccount.address.trim()}&startblock=0&endblock=latest&page=1&offset=200&sort=desc&apikey=$key";
        trUrl =
            "https://$baseUrl/api?module=account&action=txlist&address=${currentAccount.address.trim()}&startblock=0&endblock=latest&page=1&offset=200&sort=desc&apikey=$key";
      }
      final results =  await Future.wait([
      http.get(Uri.parse(trUrl)),
      if (currentCrypto.type == CryptoType.network)  http.get(Uri.parse(internalUrl) ) 
        
      ]);
      final trRequest = results[0];
      if (internalUrl.isNotEmpty && currentCrypto.type != CryptoType.token) {
        final internalTrResult =   results[1];
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
          logError("Error getting internal transactions");
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
            setState(() {
              transactions = [];
            });
          }
        }
      }

      if (allTransactions.isNotEmpty) {
        allTransactions.sort((a, b) => b.timeStamp.compareTo(a.timeStamp));
        if (mounted) {
          setState(() {
            transactions = allTransactions;
          });
        }

        final List<dynamic> allTransactionsJson = [];
        for (final data in allTransactions) {
          allTransactionsJson.add(data.toJson());
        }
        publicDataManager.saveDataInPrefs(
            data: json.encode(allTransactionsJson),
            key: "${currentAccount.address}/lastTransactions");
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
  }

  @override
  void dispose() {
    super.dispose();

    _tabController.dispose();
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

  @override
  void didChangeDependencies() async {
    super.didChangeDependencies();
    if (!_isInitialized) {
      final data = ModalRoute.of(context)?.settings.arguments;
      if (data != null && (data as Map<String, dynamic>)["id"] != null) {
        final id = data["id"];
        await getSavedWallets();
        final savedCrypto =
            await cryptoStorageManager.getSavedCryptos(wallet: currentAccount);
        if (savedCrypto != null) {
          for (final crypto in savedCrypto) {
            if (crypto.cryptoId == id) {
              setState(() {
                currentCrypto = crypto;
              });
            }
          }
        }

        await getTransactions();

        log("Network sets to ${currentCrypto.binanceSymbol}");
      }
      _isInitialized = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    double height = MediaQuery.of(context).size.height;
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
              showModalBottomSheet(
                isScrollControlled: false,
                context: context,
                builder: (BuildContext chartCtx) {
                  return StatefulBuilder(
                    builder: (BuildContext context, StateSetter setModalState) {
                      return BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        child: Container(
                            decoration: BoxDecoration(
                              color: Color(0XFF1A1B20),
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(15),
                                topRight: Radius.circular(15),
                              ),
                            ),
                            child: Column(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(10),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      FutureBuilder(
                                        future: priceManager.checkCryptoTrend(
                                            currentCrypto.binanceSymbol ??
                                                "https://opbnb-mainnet-rpc.bnbchain.org"),
                                        builder: (BuildContext trendCtx,
                                            AsyncSnapshot result) {
                                          if (result.hasData) {
                                            final isPositive =
                                                result.data["percent"] > 0;
                                            return Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  "\$ ${result.data["price"]}",
                                                  style: GoogleFonts.roboto(
                                                    color: isPositive
                                                        ? colors.greenColor
                                                        : colors.redColor,
                                                    fontSize: 22,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                Text(
                                                  " ${(result.data["percent"] as double).toStringAsFixed(5)}%",
                                                  style: GoogleFonts.roboto(
                                                    color: isPositive
                                                        ? colors.greenColor
                                                        : colors.redColor,
                                                    fontSize: 14,
                                                  ),
                                                ),
                                              ],
                                            );
                                          } else if (result.hasError) {
                                            return Text("Error fetching data");
                                          } else {
                                            return Text("Loading...");
                                          }
                                        },
                                      ),
                                      IconButton(
                                        onPressed: () {
                                          Navigator.pop(context);
                                        },
                                        icon: Icon(FeatherIcons.xCircle,
                                            color: Colors.pinkAccent),
                                      )
                                    ],
                                  ),
                                ),
                                FutureBuilder(
                                    future: getCandleData(
                                        crypto: currentCrypto,
                                        index: currentIndex),
                                    builder: (ctx, result) {
                                      if (result.hasData) {
                                        return SizedBox(
                                          height: height * 0.3,
                                          child: Candlesticks(
                                            candles: result.data ?? [],
                                          ),
                                        );
                                      } else if (result.hasError) {
                                        return SizedBox(
                                          height: height * 0.3,
                                          child: Text(
                                            "Error fetching data",
                                            style: GoogleFonts.roboto(
                                                color: Colors.pinkAccent),
                                          ),
                                        );
                                      } else {
                                        return SizedBox(
                                            height: height * 0.3,
                                            child: Text("Loading..."));
                                      }
                                    })
                                /* Center(
                                        child: SizedBox(
                                            height: height * 0.3,
                                            child: Text("Loading...")))  */
                                ,
                                SizedBox(height: 15),
                                Wrap(
                                  children:
                                      List.generate(intervals.length, (index) {
                                    return Padding(
                                      padding: const EdgeInsets.all(5),
                                      child: Material(
                                        color: Colors.transparent,
                                        child: InkWell(
                                          borderRadius:
                                              BorderRadius.circular(15),
                                          onTap: () async {
                                            setModalState(() {
                                              currentIndex = index;
                                              log("currentIndex: $currentIndex ");
                                            });
                                          },
                                          child: Container(
                                            width: 35,
                                            height: 35,
                                            padding: const EdgeInsets.all(5),
                                            decoration: BoxDecoration(
                                              color: currentIndex == index
                                                  ? colors.themeColor
                                                      .withOpacity(0.3)
                                                  : colors.themeColor,
                                              borderRadius:
                                                  BorderRadius.circular(15),
                                            ),
                                            child: Center(
                                              child: Text(
                                                intervals[index],
                                                style: GoogleFonts.roboto(
                                                    color: colors.textColor,
                                                    fontSize: 10),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  }),
                                ),
                              ],
                            )),
                      );
                    },
                  );
                },
              );
            },
            icon: Icon(
              Icons.candlestick_chart_rounded,
              color: colors.textColor,
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: colors.primaryColor,
        backgroundColor: colors.textColor.withOpacity(0.8),
        onRefresh: getTransactions,
        child: SingleChildScrollView(
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
                        child: Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(50),
                              child: currentCrypto.icon == null
                                  ? Container(
                                      width: 65,
                                      height: 65,
                                      decoration: BoxDecoration(
                                          color:
                                              colors.textColor.withOpacity(0.6),
                                          borderRadius:
                                              BorderRadius.circular(50)),
                                      child: Center(
                                        child: Text(
                                          currentCrypto.symbol.length > 2
                                              ? currentCrypto.symbol
                                                  .substring(0, 2)
                                              : currentCrypto.symbol,
                                          style: GoogleFonts.roboto(
                                              color: colors.primaryColor,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 18),
                                        ),
                                      ),
                                    )
                                  : Image.asset(
                                      currentCrypto.icon ?? "",
                                      width: 65,
                                      height: 65,
                                    ),
                            ),
                            if (currentCrypto.type == CryptoType.token)
                              Positioned(
                                  top: 45,
                                  left: 45,
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(50),
                                    child: Image.asset(
                                      currentCrypto.network?.icon ?? "",
                                      width: 20,
                                      height: 20,
                                    ),
                                  ))
                          ],
                        ),
                      ),
                      SizedBox(
                        height: 10,
                      ),
                      SizedBox(
                        width: width * 0.4,
                        child: Center(
                          child: FutureBuilder(
                              future: web3InteractManager.getBalance(
                                  currentAccount, currentCrypto),
                              builder: (BuildContext balanceCtx,
                                  AsyncSnapshot result) {
                                if (result.hasData) {
                                  return Text(
                                    "${formatter.format(result.data).split('0').length - 1 > 6 ? 0 : formatter.format(result.data)} ${currentCrypto.symbol}",
                                    overflow: TextOverflow.clip,
                                    maxLines: 1,
                                    style: GoogleFonts.roboto(
                                        color: colors.textColor,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 24),
                                  );
                                } else {
                                  return Text(
                                    "$userLastBalance BNB",
                                    overflow: TextOverflow.clip,
                                    maxLines: 1,
                                    style: GoogleFonts.roboto(
                                        color: colors.textColor,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 24),
                                  );
                                }
                              }),
                        ),
                      ),
                      SizedBox(
                        height: 5,
                      ),
                      FutureBuilder(
                          future: getBalanceUsd(currentCrypto),
                          builder: (BuildContext ctx, AsyncSnapshot result) {
                            if (result.hasData) {
                              return Text(
                                "= \$${(result.data as double).toStringAsFixed(2)} ",
                                style: GoogleFonts.roboto(
                                    color: colors.textColor.withOpacity(0.5),
                                    fontSize: 14),
                              );
                            } else {
                              return Text(
                                " = \$0.00 ",
                                style: GoogleFonts.roboto(
                                    color: colors.textColor.withOpacity(0.5),
                                    fontSize: 14),
                              );
                            }
                          })
                    ],
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
                        Navigator.pushNamed(context, Routes.sendScreen,
                            arguments: ({"id": currentCrypto.cryptoId}));
                      },
                      bottomText: "Send",
                      icon: Icons.arrow_upward),
                  WalletViewButtonAction(
                      textColor: colors.textColor,
                      onTap: () {
                        Navigator.pushNamed(context, Routes.receiveScreen,
                            arguments: ({"id": currentCrypto.cryptoId}));
                      },
                      bottomText: "Receive",
                      icon: Icons.arrow_downward),
                ],
              ),
              SizedBox(
                height: 10,
              ),
              Divider(
                color: colors.textColor.withOpacity(0.05),
              ),
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
              SizedBox(
                height: height * 0.82,
                child: TabBarView(controller: _tabController, children: [
                  SingleChildScrollView(
                      child: SizedBox(
                    height: height * 0.82,
                    child: getFilteredTransactions().isEmpty
                        ? Align(
                            alignment: Alignment.topCenter,
                            child: Container(
                              height: 70,
                              margin: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(15),
                                  border: Border.all(
                                      width: 1, color: colors.grayColor)),
                              child: Align(
                                  alignment: Alignment.center,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        "Cannot find your transaction ? ",
                                        style: GoogleFonts.roboto(
                                            color: colors.textColor
                                                .withOpacity(0.7)),
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
                        : ListView.builder(
                            itemCount: getFilteredTransactions().length,
                            itemBuilder: (BuildContext listCtx, index) {
                              final transaction =
                                  getFilteredTransactions()[index];
                              final isFrom = transaction.from
                                      .trim()
                                      .toLowerCase() ==
                                  currentAccount.address.trim().toLowerCase();
                              return TransactionsListElement(
                                surfaceTintColor: colors.grayColor,
                                isFrom: isFrom,
                                tr: transaction,
                                textColor: colors.textColor,
                                secondaryColor: colors.themeColor,
                                darkColor: colors.primaryColor,
                                primaryColor: colors.secondaryColor,
                                currentNetwork: currentCrypto,
                              );
                            }),
                  )),
                  SingleChildScrollView(
                      child: SizedBox(
                    height: height * 0.82,
                    child: ListView.builder(
                        itemCount: getFilteredTransactions()
                            .where((tr) =>
                                tr.from.toLowerCase().trim() !=
                                currentAccount.address.toLowerCase().trim())
                            .toList()
                            .length,
                        itemBuilder: (BuildContext listCtx, index) {
                          final trx = getFilteredTransactions();
                          final trIn = trx
                              .where((tr) =>
                                  tr.from.toLowerCase().trim() !=
                                  currentAccount.address.toLowerCase().trim())
                              .toList();
                          final tr = trIn[index];
                          final isFrom = tr.from.trim().toLowerCase() ==
                              currentAccount.address.trim().toLowerCase();
                          return TransactionsListElement(
                            surfaceTintColor: colors.grayColor,
                            isFrom: isFrom,
                            tr: tr,
                            textColor: colors.textColor,
                            secondaryColor: colors.themeColor,
                            darkColor: colors.primaryColor,
                            primaryColor: colors.secondaryColor,
                            currentNetwork: currentCrypto,
                          );
                        }),
                  )),
                  SingleChildScrollView(
                      child: SizedBox(
                          height: height * 0.82,
                          child: ListView.builder(
                              itemCount: getFilteredTransactions()
                                  .where((tr) =>
                                      tr.from.toLowerCase().trim() ==
                                      currentAccount.address
                                          .toLowerCase()
                                          .trim())
                                  .toList()
                                  .length,
                              itemBuilder: (BuildContext listCtx, index) {
                                final trx = getFilteredTransactions();
                                final trOut = trx
                                    .where((tr) =>
                                        tr.from.toLowerCase().trim() ==
                                        currentAccount.address
                                            .toLowerCase()
                                            .trim())
                                    .toList();
                                final tr = trOut[index];
                                final isFrom = tr.from.trim().toLowerCase() ==
                                    currentAccount.address.trim().toLowerCase();
                                return TransactionsListElement(
                                  surfaceTintColor: colors.grayColor,
                                  isFrom: isFrom,
                                  tr: tr,
                                  textColor: colors.textColor,
                                  secondaryColor: colors.themeColor,
                                  darkColor: colors.primaryColor,
                                  primaryColor: colors.secondaryColor,
                                  currentNetwork: currentCrypto,
                                );
                              }))),
                ]),
              )
            ],
          ),
        ),
      ),
    );
  }
}
