// ignore_for_file: deprecated_member_use

import 'dart:convert';

import 'package:fast_cached_network_image/fast_cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:moonwallet/custom/web3_webview/lib/utils/loading.dart';
import 'package:moonwallet/logger/logger.dart';
import 'package:moonwallet/screens/dashboard/discover/browser.dart';
import 'package:moonwallet/service/crypto_storage_manager.dart';
import 'package:moonwallet/service/wallet_saver.dart';
import 'package:moonwallet/service/web3.dart';
import 'package:moonwallet/types/types.dart';
import 'package:moonwallet/utils/colors.dart';
import 'package:moonwallet/utils/crypto.dart';
import 'package:moonwallet/utils/prefs.dart';
import 'package:moonwallet/utils/themes.dart';
import 'package:moonwallet/widgets/func/browser/change_network.dart';

import 'package:moonwallet/widgets/func/snackbar.dart';

class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({super.key});

  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final publicDataManager = PublicDataManager();

  TextEditingController _textEditingController = TextEditingController();
  bool _isSearchFocused = false;
  bool isDarkMode = false;
  List<Crypto> networks = [];
  PublicData? currentAccount;
  List<PublicData> accounts = [];

  final String historyName = "UserHistory";
  FocusNode _focusNode = FocusNode();
  final List<DApp> dapps = [
    DApp(
      description: "Moon BNB is Global smart contract for global earnings",
      icon: "assets/image.png",
      name: 'Moon BNB',
      link: "https://moonbnb.pro",
      isNetworkImage: false,
    ),
    DApp(
      description:
          "Trade, earn, and own crypto on the all-in-one multichain DEX",
      icon:
          "https://tokens.pancakeswap.finance/images/0x0E09FaBB73Bd3Ade0a17ECC321fD13a19e81cE82.png",
      name: 'Pancakeswap',
      link: "https://pancakeswap.finance",
      isNetworkImage: true,
    ),
    DApp(
      description: "Buy, sell & trade Ethereum and other top tokens on Uniswap",
      icon:
          "https://raw.githubusercontent.com/trustwallet/assets/master/blockchains/ethereum/assets/0x1f9840a85d5aF5bf1D1762F925BDADdC4201F984/logo.png",
      name: 'Uniswap',
      link: "https://app.uniswap.org/swap",
      isNetworkImage: true,
    ),
  ];
  List<HistoryItem> history = [];
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

  @override
  void initState() {
    super.initState();

    _tabController = TabController(length: 2, vsync: this);
    getSavedTheme();
    _focusNode.addListener(() {
      setState(() {
        _isSearchFocused = _focusNode.hasFocus;
        if (_isSearchFocused) {
          _tabController.index = 1;
        }
      });
    });
    getHistoryItem();
    getSavedWallets();
  }

  Future<void> getSavedWallets() async {
    try {
      final web3Manager = WalletSaver();
      final encryptService = EncryptService();
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
          setState(() {
              currentAccount = account;

          });
       log("Last account address ${currentAccount?.address}");

          await getSavedCrypto(account: account);

          log("The current wallet is ${json.encode(account.toJson())}");
          break;
        } else {
          log("Not account found");
          setState(() {
                      currentAccount = accounts[0];

          });
                log("first account address ${currentAccount?.address}");


        }
      }

      log("Current account address ${currentAccount?.address}");
    } catch (e) {
      logError('Error getting saved wallets: $e');
    }
  }

  Future<bool> deleteHistoryItem(int index) async {
    try {
      final prefs = PublicDataManager();

      // ignore: non_constant_identifier_names
      final List<HistoryItem> ListHist = [];
      final savedHist = await prefs.getDataFromPrefs(key: historyName);

      if (savedHist != null) {
        log("History found");
        final historyJson = json.decode(savedHist) as List<dynamic>;
        for (final hist in historyJson) {
          log("New hist ${json.encode(hist)}");
          final newHist = HistoryItem.fromJson(hist);

          ListHist.add(newHist);
        }
        if (ListHist.isNotEmpty) {
          final removedElement = ListHist.removeAt(index);
          setState(() {
            history = ListHist;
          });
          log('deleted element ${json.encode(removedElement.toJson())}');
          if (ListHist.isEmpty) {
            await prefs.removeDataFromPrefs(key: historyName);
            return true;
          }
          final jsonListHist = [];
          for (final hist in ListHist) {
            jsonListHist.add(hist.toJson());
          }
          await prefs.saveDataInPrefs(
              key: historyName, data: json.encode(jsonListHist));
          return true;
        } else {
          return true;
        }
      } else {
        log("Not data found");
        return false;
      }
    } catch (e) {
      logError('Error deleting history item: $e');
      return false;
    }
  }

  Future<void> changeHistoryIndex(int index) async {
    try {
      final prefs = PublicDataManager();
      if (index == 0) {
        return;
      }
      // ignore: non_constant_identifier_names
      final List<HistoryItem> ListHist = [];
      final savedHist = await prefs.getDataFromPrefs(key: historyName);

      if (savedHist != null) {
        log("History found");
        final historyJson = json.decode(savedHist) as List<dynamic>;
        for (final hist in historyJson) {
          log("New hist ${json.encode(hist)}");
          final newHist = HistoryItem.fromJson(hist);

          ListHist.add(newHist);
        }
        if (ListHist.isNotEmpty) {
          final element = ListHist.removeAt(index);
          ListHist.insert(0, element);
          setState(() {
            history = ListHist;
          });
          final jsonListHist = [];
          for (final hist in ListHist) {
            jsonListHist.add(hist.toJson());
          }
          await prefs.saveDataInPrefs(
              key: historyName, data: json.encode(jsonListHist));
        }
      }
    } catch (e) {
      logError('Error changing history index: $e');
    }
  }

  Future<void> getHistoryItem() async {
    try {
      log("Searching for history");
      final prefs = PublicDataManager();
      final savedHistory = await prefs.getDataFromPrefs(key: historyName);
      if (savedHistory != null) {
        log("History found");
        final historyJson = json.decode(savedHistory) as List<dynamic>;
        for (final hist in historyJson) {
          history.add(HistoryItem.fromJson(hist));
        }
      } else {
        log("No History");
      }
    } catch (e) {
      logError('Error getting history: $e');
    }
  }

  String formateUrl(String link) {
    if (link.toLowerCase().startsWith("http")) {
      return link;
    } else {
      return "https://$link";
    }
  }

  Future<void> updateSavedHistory(String link) async {
    try {
      if (link.isEmpty) {
        return;
      }
      log("Updating saved history");
      final prefs = PublicDataManager();
      final savedHistory = await prefs.getDataFromPrefs(key: historyName);
      if (savedHistory != null) {
        final title = Uri.parse(link).origin;
        if (title.isNotEmpty) {
          final history = json.decode(savedHistory) as List<dynamic>;
          for (final hist in history) {
            if (link.contains(hist["link"])) {
              log("Already saved");
              return;
            }
          }
          history.insert(0, {
            "link": link,
            "title": Uri.parse(link).origin,
          });
          await prefs.saveDataInPrefs(
              key: historyName, data: json.encode(history));
        }
      } else {
        log("history does not exist yet");
        final List<Map<String, dynamic>> history = [];
        final newHist = {
          "link": link,
          "title": Uri.parse(link).origin,
        };
        history.add(newHist);
        await prefs.saveDataInPrefs(
            key: historyName, data: json.encode(history));
      }
    } catch (e) {
      logError('Error updating saved history: $e');
    }
  }

  Future<void> getSavedCrypto({required PublicData account}) async {
    try {
      final savedCryptos =
          await CryptoStorageManager().getSavedCryptos(wallet: account);
      if (savedCryptos != null) {
        log("Saved crypto ${savedCryptos.length}");
        setState(() {
          networks =
              savedCryptos.where((c) => c.type == CryptoType.network).toList();
        });
      } else {
        logError("No saved cryptos found");

        showCustomSnackBar(
            context: context,
            message: "No saved cryptos found",
            primaryColor: colors.primaryColor,
            colors: colors);
      }
    } catch (e) {
      logError('Error getting saved crypto: $e');
    }
  }

  Future<void> openBrowser(String url) async {
    try {
      if (currentAccount == null) {
        throw "No account found";
      }
      await getSavedCrypto(account: currentAccount!)
          .withLoading(context, colors);

      if (url.isEmpty) {
        showCustomSnackBar(
            context: context,
            message: "Url cannot be empty",
            primaryColor: colors.primaryColor,
            colors: colors);
        return;
      }
      if (networks.isEmpty) {
        showCustomSnackBar(
            context: context,
            message: "No saved cryptos found",
            primaryColor: colors.primaryColor,
            colors: colors);
        return;
      }
      Crypto? network;
      await showChangeNetworkModal(
              title: "Select a network",
              networks: networks,
              colors: colors,
              changeNetwork: (crypto) async {
                network = crypto;
              },
              context: context,
              darkNavigatorColor: colors.primaryColor,
              textColor: colors.textColor,
              chainId: networks[0].chainId ?? 204)
          .then((result) {
        if (result && network != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => Web3BrowserScreen(
                url: url,
                network: network,
              ),
            ),
          );
        } else {
          logError("No network selected or result is not true");
        }
      });
    } catch (e) {
      logError(e.toString());
      showCustomSnackBar(
        context: context,
        message: "Error opening browser: $e",
        primaryColor: colors.primaryColor,
        colors: colors);
    }
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    return Scaffold(
        backgroundColor: colors.primaryColor,
        appBar: AppBar(
          surfaceTintColor: colors.primaryColor,
          automaticallyImplyLeading: false,
          backgroundColor: colors.primaryColor,
          title: Text(
            "Discover",
            style: GoogleFonts.roboto(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: colors.textColor,
            ),
          ),
        ),
        body: NestedScrollView(
          headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
            return [
              SliverToBoxAdapter(
                child: Align(
                  alignment: Alignment.center,
                  child: Container(
                    margin: const EdgeInsets.only(top: 10),
                    alignment: Alignment.center,
                    width: width * 0.9,
                    height: 40,
                    child: TextField(
                      onSubmitted: (data) async {
                        try {
                          if (data.isEmpty) return;
                          await updateSavedHistory(formateUrl(data.trim()));
                          _textEditingController.text = "";

                          await openBrowser(data.trim());
                        } catch (e) {
                          logError(e.toString());
                          showCustomSnackBar(
                              colors: colors,
                              primaryColor: colors.primaryColor,
                              context: context,
                              message: "Invalid Url",
                              iconColor: Colors.pinkAccent);
                        }
                      },
                      focusNode: _focusNode,
                      controller: _textEditingController,
                      cursorColor: colors.themeColor,
                      style: GoogleFonts.roboto(
                        color: colors.textColor,
                      ),
                      decoration: InputDecoration(
                        prefixIcon: Icon(
                          LucideIcons.search,
                          color: colors.textColor.withOpacity(0.3),
                        ),
                        filled: true,
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                              color: colors.textColor.withOpacity(0)),
                          borderRadius: BorderRadius.circular(40),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                              color: colors.grayColor.withOpacity(0)),
                          borderRadius: BorderRadius.circular(40),
                        ),
                        contentPadding:
                            const EdgeInsets.only(left: 10, right: 10),
                        border: OutlineInputBorder(
                            borderSide: BorderSide(
                                color: colors.grayColor.withOpacity(0)),
                            borderRadius: BorderRadius.circular(40)),
                        labelText: "Search",
                        labelStyle:
                            TextStyle(color: colors.textColor, fontSize: 12),
                        fillColor: colors.grayColor.withOpacity(0.2),
                      ),
                    ),
                  ),
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
                    unselectedLabelColor: colors.grayColor.withOpacity(0.7),
                    indicatorColor: colors.themeColor,
                    tabs: [
                      Tab(text: 'DApps'),
                      Tab(
                        text: 'History',
                      ),
                    ],
                  ),
                  primaryColor: colors.primaryColor,
                ),
              ),
            ];
          },
          body: TabBarView(controller: _tabController, children: [
            Container(
              decoration: BoxDecoration(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    child: Text(
                      "Best DApps",
                      style: GoogleFonts.roboto(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: colors.textColor,
                      ),
                    ),
                  ),
                  Expanded(
                      child: ListView.builder(
                          itemCount: dapps.length,
                          itemBuilder: (ctx, index) {
                            final dapp = dapps[index];
                            return ListTile(
                                leading: ClipRRect(
                                  borderRadius: BorderRadius.circular(50),
                                  child: dapp.isNetworkImage
                                      ? FastCachedImage(
                                          url: dapp.icon,
                                          width: 50,
                                          height: 50,
                                        )
                                      : Image.asset(
                                          dapp.icon,
                                          width: 50,
                                          height: 50,
                                        ),
                                ),
                                title: Text(
                                  dapp.name,
                                  style: GoogleFonts.roboto(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: colors.textColor,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                                subtitle: Text(
                                  dapp.description,
                                  style: GoogleFonts.roboto(
                                    fontSize: 14,
                                    color: colors.textColor.withOpacity(0.6),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                                onTap: () async {
                                  await updateSavedHistory(
                                      formateUrl(dapp.link.trim()));

                                  await openBrowser(dapp.link);
                                });
                          }))
                ],
              ),
            ),
            Container(
              decoration: BoxDecoration(),
              child: ListView.builder(
                  itemCount: history.length,
                  itemBuilder: (ctx, index) {
                    final hist = history[index];

                    return ListTile(
                        leading: ClipRRect(
                            borderRadius: BorderRadius.circular(50),
                            child: Container(
                                decoration: BoxDecoration(
                                    color: colors.grayColor.withOpacity(0.5)),
                                child: FastCachedImage(
                                  url:
                                      "https://www.google.com/s2/favicons?domain_url=${hist.link}",
                                  width: 30,
                                  height: 30,
                                  fit: BoxFit.cover,
                                  loadingBuilder: (ctx, p) {
                                    return CircularProgressIndicator(
                                      color: colors.themeColor,
                                      value: p.progressPercentage.value,
                                    );
                                  },
                                ))),
                        title: Text(
                          hist.title,
                          style: GoogleFonts.roboto(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: colors.textColor,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                        trailing: IconButton(
                            onPressed: () async {
                              final res = await deleteHistoryItem(index);
                              if (res) {
                                showCustomSnackBar(
                                    colors: colors,
                                    primaryColor: colors.primaryColor,
                                    context: context,
                                    message: "Deleted successfully",
                                    iconColor: Colors.greenAccent,
                                    icon: Icons.check);
                              } else {
                                showCustomSnackBar(
                                    colors: colors,
                                    primaryColor: colors.primaryColor,
                                    context: context,
                                    message: "Failed to delete",
                                    iconColor: Colors.pinkAccent,
                                    icon: Icons.error);
                              }
                            },
                            icon: Icon(
                              FeatherIcons.trash,
                              color: colors.textColor.withOpacity(0.7),
                            )),
                        onTap: () async {
                          await changeHistoryIndex(index);
                          await openBrowser(hist.link);
                        });
                  }),
            ),
          ]),
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
