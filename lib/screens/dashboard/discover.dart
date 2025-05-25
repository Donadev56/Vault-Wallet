// ignore_for_file: deprecated_member_use

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:moonwallet/logger/logger.dart';
import 'package:moonwallet/notifiers/providers.dart';
import 'package:moonwallet/screens/dashboard/discover/browser.dart';
import 'package:moonwallet/service/external_data/browser_data_request_manager.dart';
import 'package:moonwallet/types/account_related_types.dart';
import 'package:moonwallet/types/browser.dart';
import 'package:moonwallet/types/types.dart';
import 'package:moonwallet/utils/colors.dart';
import 'package:moonwallet/utils/prefs.dart';
import 'package:moonwallet/utils/themes.dart';

import 'package:moonwallet/widgets/dialogs/show_custom_snackbar.dart';
import 'package:moonwallet/widgets/func/discover/dapps_view.dart';
import 'package:moonwallet/widgets/func/discover/history_listTitle.dart';
import 'package:moonwallet/widgets/func/discover/show_dapp_details.dart';
import 'package:moonwallet/widgets/func/tokens_config/show_select_network_modal.dart';
import 'package:moonwallet/widgets/screen_widgets/chips.dart';
import 'package:moonwallet/widgets/screen_widgets/search_text_field.dart';

class DiscoverScreen extends StatefulHookConsumerWidget {
  final AppColors? colors;
  const DiscoverScreen({super.key, this.colors});

  @override
  ConsumerState<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends ConsumerState<DiscoverScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final publicDataManager = PublicDataManager();

  final _textEditingController = TextEditingController();
  bool _isSearchFocused = false;
  bool isDarkMode = false;
  List<Crypto> networks = [];
  PublicAccount? currentAccount;
  List<PublicAccount> accounts = [];

  final String historyName = "UserHistory";
  final _focusNode = FocusNode();

  List<HistoryItem> history = [];
  AppColors colors = AppColors.defaultTheme;
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
    if (widget.colors != null) {
      setState(() {
        colors = widget.colors!;
      });
    }
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

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    final textTheme = Theme.of(context).textTheme;
    final currentAccountAsync = ref.watch(currentAccountProvider);
    final accountListAsync = ref.watch(accountsNotifierProvider);
    final savedCryptoAsync = ref.watch(savedCryptosProviderNotifier);
    final uiConfig = useState<AppUIConfig>(AppUIConfig.defaultConfig);
    final appUIConfigAsync = ref.watch(appUIConfigProvider);
    final browserData = useState<(List<DApp>, List<Category>)>(([], []));
    final selectedIndex = useState<int>(0);

    Future<void> getBrowserData() async {
      try {
        final manager = BrowserDataRequestManager();
        final data = await manager.getBrowserData();
        if (data == null) {
          throw Exception("Failed  to fetch dapps info");
        }
        browserData.value = data;
      } catch (e) {
        logError(e.toString());
        notifyError(e.toString(), context);
      }
    }

    Future<void> getSavedBrowserData() async {
      try {
        final manager = BrowserDataRequestManager();
        final data = await manager.getSavedDataToDart();
        browserData.value = data;
      } catch (e) {
        logError(e.toString());
        notifyError(e.toString(), context);
      }
    }

    useEffect(() {
      getSavedBrowserData();

      getBrowserData();

      return null;
    }, []);

    useEffect(() {
      appUIConfigAsync.whenData((data) {
        uiConfig.value = data;
      });
      return null;
    }, [appUIConfigAsync]);

    double fontSizeOf(double size) {
      return size * uiConfig.value.styles.fontSizeScaleFactor;
    }

    double imageSizeOf(double size) {
      return size * uiConfig.value.styles.imageSizeScaleFactor;
    }

    double iconSizeOf(double size) {
      return size * uiConfig.value.styles.iconSizeScaleFactor;
    }

    double roundedOf(double size) {
      return size * uiConfig.value.styles.radiusScaleFactor;
    }

    currentAccountAsync.whenData(
      (value) {
        setState(() {
          currentAccount = value;
        });
      },
    );
    accountListAsync.whenData(
      (value) {
        accounts = value;
      },
    );
    savedCryptoAsync.whenData(
      (value) {
        networks = value
            .where((crypto) => crypto.canDisplay && crypto.isNative)
            .toList();
      },
    );

    Future<void> openBrowser(String url) async {
      try {
        if (currentAccount == null) {
          throw "No account found";
        }

        if (url.isEmpty) {
          notifyError("Url cannot be empty", context);

          return;
        }
        if (networks.isEmpty) {
          notifyError("No saved cryptos found", context);

          return;
        }
        final selected = await showSelectNetworkModal(
          context: context,
          colors: colors,
          roundedOf: roundedOf,
          fontSizeOf: fontSizeOf,
          iconSizeOf: iconSizeOf,
          networks: networks,
        );

        if (selected != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => Web3BrowserScreen(
                networks: networks,
                account: currentAccount!,
                url: url,
                network: selected,
              ),
            ),
          );
        } else {
          logError("No network selected or result is not true");
        }
      } catch (e) {
        logError(e.toString());
        notifyError("Error opening browser: $e", context);
      }
    }

    List<Category> getCategory() {
      if (selectedIndex.value == 0) {
        return browserData.value.$2;
      }
      final targetCategory = browserData.value.$2[selectedIndex.value - 1];
      return [targetCategory];
    }

    Future<void> onDAppClick(DApp app) async {
      final doNotShow = await PublicDataManager().getDataFromPrefs(
          key: "Do-not-show-again-dapp-modal-for/${app.websiteUrl}");
      if (doNotShow != null && doNotShow == "true") {
        openBrowser(app.websiteUrl);

        return;
      }
      final enter = await showDappDetails(
          app: app,
          context: context,
          colors: colors,
          imageSizeOf: imageSizeOf,
          fontSizeOf: fontSizeOf);
      if (enter) {
        openBrowser(app.websiteUrl);
      }
    }

    return Scaffold(
        backgroundColor: colors.primaryColor,
        appBar: AppBar(
          surfaceTintColor: colors.primaryColor,
          automaticallyImplyLeading: false,
          backgroundColor: colors.primaryColor,
          title: Text(
            "Discover",
            style: textTheme.headlineMedium?.copyWith(
              fontSize: fontSizeOf(24),
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
                    child: SearchTextField(
                      hintText: "Enter DApp",
                      roundedOf: roundedOf,
                      colors: colors,
                      fontSizeOf: fontSizeOf,
                      onFormSubmitted: (data) async {
                        try {
                          if (data.isEmpty) return;
                          await updateSavedHistory(formateUrl(data.trim()));
                          _textEditingController.text = "";

                          await openBrowser(data.trim());
                        } catch (e) {
                          logError(e.toString());
                          notifyError("Invalid Url", context);
                        }
                      },
                      focusNode: _focusNode,
                      controller: _textEditingController,
                    ),
                  ),
                ),
              ),
              SliverPersistentHeader(
                key: ValueKey(colors.primaryColor),
                pinned: false,
                delegate: _SliverAppBarDelegate(
                  TabBar(
                    dividerColor: Colors.transparent,
                    controller: _tabController,
                    labelColor: colors.themeColor,
                    unselectedLabelColor: colors.textColor,
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
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 10, bottom: 20),
                        child: Row(
                          children: List.generate(
                              browserData.value.$2.length + 1, (index) {
                            if (index == 0) {
                              return IconChip(
                                colors: colors,
                                icon: Icon(
                                  LucideIcons.globe,
                                  color: colors.textColor,
                                ),
                                text: "All",
                                useBorder: selectedIndex.value == index,
                                borderColor: colors.themeColor,
                                onTap: () => selectedIndex.value = index,
                              );
                            }
                            final category = browserData.value.$2[index - 1];
                            return Container(
                              margin: const EdgeInsets.symmetric(horizontal: 5),
                              child: IconChip(
                                colors: colors,
                                icon: Image.network(
                                  category.iconUrl,
                                  width: 25,
                                  height: 25,
                                ),
                                text: category.name,
                                useBorder: selectedIndex.value == index,
                                borderColor: colors.themeColor,
                                onTap: () => selectedIndex.value = index,
                              ),
                            );
                          }),
                        ),
                      ),
                    ),
                    Expanded(
                        child: ListView.builder(
                            itemCount: getCategory().length,
                            itemBuilder: (ctx, index) {
                              final category = getCategory()[index];
                              final dapps = browserData.value.$1.where((e) =>
                                  e.categories.any((cat) =>
                                      cat.id.trim().toLowerCase() ==
                                      category.name.trim().toLowerCase()));

                              final primaryDapps =
                                  dapps.where((e) => e.isPrimary).toList();
                              final nonPrimaryDapps =
                                  dapps.where((e) => !e.isPrimary).toList();

                              return DappsViewList(
                                  onSelect: (value) {
                                    onDAppClick(value);
                                  },
                                  category: category,
                                  colors: colors,
                                  fontSizeOf: fontSizeOf,
                                  imageSizeOf: imageSizeOf,
                                  nonPrimaryDapps: nonPrimaryDapps,
                                  primaryDapps: primaryDapps);
                            }))
                  ],
                ),
              ),
            ),
            Container(
              decoration: BoxDecoration(),
              child: ListView.builder(
                  itemCount: history.length,
                  itemBuilder: (ctx, index) {
                    final hist = history[index];

                    return HistoryListTitle(
                        colors: colors,
                        fontSizeOf: fontSizeOf,
                        imageSizeOf: imageSizeOf,
                        roundedOf: roundedOf,
                        link: hist.link,
                        title: hist.title,
                        onDeleteClick: () async {
                          final res = await deleteHistoryItem(index);
                          if (res) {
                            notifySuccess("Deleted successfully", context);
                          } else {
                            notifyError("Failed to delete", context);
                          }
                        },
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
