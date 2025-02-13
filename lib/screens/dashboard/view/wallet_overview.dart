// ignore_for_file: deprecated_member_use

import 'dart:convert';
import 'package:http/http.dart' as http;

import 'package:flutter/material.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:moonwallet/logger/logger.dart';
import 'package:moonwallet/service/price_manager.dart';
import 'package:moonwallet/service/web3.dart';
import 'package:moonwallet/service/web3_interaction.dart';
import 'package:moonwallet/types/types.dart';
import 'package:moonwallet/utils/constant.dart';
import 'package:moonwallet/utils/crypto.dart';
import 'package:moonwallet/utils/prefs.dart';
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
  PublicData currentAccount =
      PublicData(keyId: "", creationDate: 0, walletName: "", address: "");
  List<PublicData> accounts = [];
  final web3Manager = Web3Manager();
  final encryptService = EncryptService();
  final priceManager = PriceManager();
  final web3InteractManager = Web3InteractionManager();
  final publicDataManager = PublicDataManager();
  double totalBalanceUsd = 0;
  bool _isInitialized = false;
  Network currentNetwork = networks[0];

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

          log("The current wallet is ${json.encode(account.toJson())}");
          break;
        } else {
          log("Not account found");
          currentAccount = accounts[0];
          getTransactions();
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

  Future<void> getTransactions() async {
    try {
      if (currentNetwork.chainId != 56 && currentNetwork.chainId != 204) return;
      List<BscScanTransaction> allTransactions = [];
      final savedTransactions = await publicDataManager.getDataFromPrefs(
          key: "${currentAccount.address}/lastTransactions");
      if (savedTransactions != null) {
        final List<dynamic> jsonData = json.decode(savedTransactions);
        final List<BscScanTransaction> tempList = [];
        for (final data in jsonData) {
          final tr = BscScanTransaction.fromJson(data);
          if (mounted) {
            setState(() {
              tempList.add(tr);
            });
          }
        }
        transactions = tempList;
      }
      final key = currentNetwork.chainId == 56
          ? "UKDSYXSDA8BJFT6QWP1IH161UQICTTJHHX"
          : "6VUMQRRIHQEFKSEU1GH4WWNU1Q9ZYG2KRZ";
      final baseUrl =
          "https://${currentNetwork.chainId == 56 ? "api.bscscan.com" : "api-opbnb.bscscan.com"}";
      final internalUrl =
          "$baseUrl/api?module=account&action=txlistinternal&address=${currentAccount.address.trim()}&startblock=0&endblock=latest&page=1&offset=200&sort=desc&apikey=$key";
      final trUrl =
          "$baseUrl/api?module=account&action=txlist&address=${currentAccount.address.trim()}&startblock=0&endblock=latest&page=1&offset=200&sort=desc&apikey=$key";
      log(trUrl);
      final trRequest = await http.get(Uri.parse(trUrl));
      final internalTrResult = await http.get(Uri.parse(internalUrl));

      if (trRequest.statusCode == 200) {
        final List<dynamic> dataJson = (json.decode(trRequest.body))["result"];

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
        }
      } else {
        logError("Error getting internal transactions");
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

  Future<double> getBalanceUsd(String symbol, String rpcUrl) async {
    try {
      log(rpcUrl);
      if (rpcUrl.isEmpty || symbol.isEmpty) {
        return 0;
      }
      final price = await getPrice(symbol);
      final balanceEth =
          await web3InteractManager.getBalance(currentAccount.address, rpcUrl);
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
    getSavedWallets();
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

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      final data = ModalRoute.of(context)?.settings.arguments;
      if (data != null && (data as Map<String, dynamic>)["index"] != null) {
        final index = data["index"];
        currentNetwork = networks[index];
        log("Network sets to ${currentNetwork.binanceSymbol}");
      }
      _isInitialized = true;
    }
  }

  Color primaryColor = Color(0XFF1B1B1B);
  Color textColor = Color.fromARGB(255, 255, 255, 255);
  Color secondaryColor = Colors.greenAccent;
  Color actionsColor = Color(0XFF353535);
  Color surfaceTintColor = Color(0XFF454545);
  Color darkNavigatorColor = Color(0XFF0D0D0D);

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    double height = MediaQuery.of(context).size.height;
    return Scaffold(
      backgroundColor: primaryColor,
      appBar: AppBar(
        surfaceTintColor: primaryColor,
        backgroundColor: primaryColor,
        leading: IconButton(
            onPressed: () {
              Navigator.pop(context);
            },
            icon: Icon(
              Icons.arrow_back,
              color: textColor,
            )),
        title: Text(
          currentNetwork.name,
          style: GoogleFonts.roboto(
              color: textColor, fontWeight: FontWeight.bold, fontSize: 22),
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: Icon(
              Icons.candlestick_chart_rounded,
              color: textColor,
            ),
          ),
          IconButton(
              icon: Icon(
                Icons.more_vert,
                color: textColor,
              ),
              onPressed: () {}),
        ],
      ),
      body: RefreshIndicator(
        color: primaryColor,
        backgroundColor: textColor.withOpacity(0.8),
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
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(50),
                          child: Image.asset(
                            currentNetwork.icon,
                            width: 65,
                            height: 65,
                            fit: BoxFit.cover,
                          ),
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
                                  currentAccount.address, currentNetwork.rpc),
                              builder: (BuildContext balanceCtx,
                                  AsyncSnapshot result) {
                                if (result.hasData) {
                                  return Text(
                                    "${result.data} ${currentNetwork.name}",
                                    overflow: TextOverflow.clip,
                                    maxLines: 1,
                                    style: GoogleFonts.roboto(
                                        color: textColor,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 24),
                                  );
                                } else {
                                  return Text(
                                    "0 BNB",
                                    overflow: TextOverflow.clip,
                                    maxLines: 1,
                                    style: GoogleFonts.roboto(
                                        color: textColor,
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
                          future: getBalanceUsd(
                              currentNetwork.binanceSymbol, currentNetwork.rpc),
                          builder: (BuildContext ctx, AsyncSnapshot result) {
                            if (result.hasData) {
                              return Text(
                                "= \$${(result.data as double).toStringAsFixed(2)} ",
                                style: GoogleFonts.roboto(
                                    color: textColor.withOpacity(0.5),
                                    fontSize: 14),
                              );
                            } else {
                              return Text(
                                " = \$0.00 ",
                                style: GoogleFonts.roboto(
                                    color: textColor.withOpacity(0.5),
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
                      textColor: textColor,
                      onTap: () {
                        log("clicked");
                      },
                      bottomText: "Send",
                      icon: Icons.arrow_upward),
                  WalletViewButtonAction(
                      textColor: textColor,
                      onTap: () {
                        log("clicked");
                      },
                      bottomText: "Receive",
                      icon: Icons.arrow_downward),
                ],
              ),
              SizedBox(
                height: 10,
              ),
              Divider(
                color: textColor.withOpacity(0.05),
              ),
              TabBar(
                dividerColor: Colors.transparent,
                controller: _tabController,
                labelColor: textColor,
                unselectedLabelColor: Colors.grey,
                indicatorColor: secondaryColor,
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
                                      width: 1, color: surfaceTintColor)),
                              child: Align(
                                  alignment: Alignment.center,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        "Cannot find your transaction ? ",
                                        style: GoogleFonts.roboto(
                                            color: textColor.withOpacity(0.7)),
                                      ),
                                      InkWell(
                                        onTap: () async {
                                          await launchUrl(Uri.parse(
                                              "${currentNetwork.explorer}/address/${currentAccount.address}"));
                                        },
                                        child: Text(
                                          "Check explorer",
                                          style: GoogleFonts.roboto(
                                              color: secondaryColor),
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
                                surfaceTintColor: surfaceTintColor,
                                isFrom: isFrom,
                                tr: transaction,
                                textColor: textColor,
                                secondaryColor: secondaryColor,
                                darkColor: darkNavigatorColor,
                                primaryColor: primaryColor,
                                currentNetwork: currentNetwork,
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
                            surfaceTintColor: surfaceTintColor,
                            isFrom: isFrom,
                            tr: tr,
                            textColor: textColor,
                            secondaryColor: secondaryColor,
                            primaryColor: primaryColor,
                            darkColor: darkNavigatorColor,
                            currentNetwork: currentNetwork,
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
                                currentAccount.address.toLowerCase().trim())
                            .toList()
                            .length,
                        itemBuilder: (BuildContext listCtx, index) {
                          final trx = getFilteredTransactions();
                          final trOut = trx
                              .where((tr) =>
                                  tr.from.toLowerCase().trim() ==
                                  currentAccount.address.toLowerCase().trim())
                              .toList();
                          final tr = trOut[index];
                          final isFrom = tr.from.trim().toLowerCase() ==
                              currentAccount.address.trim().toLowerCase();
                          return TransactionsListElement(
                            surfaceTintColor: surfaceTintColor,
                            isFrom: isFrom,
                            tr: tr,
                            textColor: textColor,
                            secondaryColor: secondaryColor,
                            darkColor: darkNavigatorColor,
                            primaryColor: primaryColor,
                            currentNetwork: currentNetwork,
                          );
                        }),
                  )),
                ]),
              )
            ],
          ),
        ),
      ),
    );
  }
}
