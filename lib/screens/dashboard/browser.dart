// ignore_for_file: deprecated_member_use
import 'package:http/http.dart' as http;
import 'package:moonwallet/service/crypto_storage_manager.dart';
import 'package:moonwallet/service/price_manager.dart';

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:moonwallet/logger/logger.dart';
import 'package:moonwallet/service/wallet_saver.dart';
import 'package:moonwallet/service/web3_interaction.dart';
import 'package:moonwallet/types/types.dart';
import 'package:moonwallet/utils/colors.dart';
import 'package:moonwallet/utils/constant.dart';
import 'package:moonwallet/utils/crypto.dart';
import 'package:moonwallet/utils/prefs.dart';
import 'package:moonwallet/utils/themes.dart';
import 'package:moonwallet/web3_webview/lib/models/network_config.dart';
import 'package:moonwallet/web3_webview/lib/models/web3_wallet_config.dart';
import 'package:moonwallet/web3_webview/lib/web3_webview.dart';
import 'package:moonwallet/web3_webview/lib/web3_webview_eip1193.dart';
import 'package:moonwallet/widgets/func/browser/show_bottom_options.dart';

class Web3BrowserScreen extends StatefulWidget {
  final String? url;
  final Crypto? network;

  const Web3BrowserScreen({super.key, this.url, this.network});

  @override
  Web3BrowserScreenState createState() => Web3BrowserScreenState();
}

class Web3BrowserScreenState extends State<Web3BrowserScreen> {
  Color darkNavigatorColor = Color(0XFF0D0D0D);
  Color darkNavigatorColorMainValue = Color(0XFF0D0D0D);
  final GlobalKey<InAppWebViewEIP1193State> webViewKey = GlobalKey();
  final publicDataManager = PublicDataManager();
  bool isDarkMode = false;

  String _title = '';
  String currentUrl = 'https://www.moonbnb.pro';
  bool canShowAppBarOptions = true;
  int _chainId = 204;
  double progress = 0;
  bool isPageLoading = true;
  Crypto currentNetwork = cryptos[0];
  InAppWebViewController? _webViewController;
  bool _isInitialized = false;
  bool isFullScreen = false;
  List<PublicData> accounts = [];
  List<Crypto> networks = [];
  PublicData? currentAccount;
  final web3Manager = WalletSaver();
  final web3IntManager = Web3InteractionManager();
  final priceManager = PriceManager();

  final encryptService = EncryptService();
  final String historyName = "UserHistory";
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
        darkNavigatorColor = colors.primaryColor;
        darkNavigatorColorMainValue = colors.primaryColor;
      });
    } catch (e) {
      logError(e.toString());
    }
  }

  void toggleShowAppBar() {
    if (!canShowAppBarOptions) {
      setState(() {
        darkNavigatorColor = darkNavigatorColorMainValue;
      });
    } else {
      getBgColor();
    }

    setState(() {
      canShowAppBarOptions = !canShowAppBarOptions;
    });
  }

  void _onTitleChanged(InAppWebViewController c, String? value) {
    if (value == null || value == _title) return;

    _title = value;
    setState(() {});
  }

  void _reload() async {
    if (_webViewController != null) {
      await _webViewController!.reload();
    }
  }

  Future<bool> changeNetwork(Crypto network) async {
    log("Changing the network id");

    int requestedChainId = network.chainId ?? 1;

    for (final net in networks) {
      log("Current network : ${net.chainId} . requested chain $requestedChainId");

      if (net.chainId == requestedChainId) {
        setState(() {
          currentNetwork = net;
          _chainId = requestedChainId;
          log("Switched to network: ${currentNetwork.name}");
        });

        return true;
      } else {
        continue;
      }
    }
    return _chainId == requestedChainId;
  }

  Future<void> manualChangeNetwork(Crypto network) async {
    try {
      int requestedChainId = network.chainId ?? 1;

      for (final net in networks) {
        if (net.chainId == requestedChainId) {
          setState(() {
            currentNetwork = net;
            _chainId = requestedChainId;
          });
          webViewKey.currentState?.changeNetwork(
              chainId: '0x${requestedChainId.toRadixString(16)}',
              context: context,
              colors: colors);
          Navigator.pop(context);
        } else {
          continue;
        }
      }
    } catch (e) {
      logError(e.toString());
    }
  }

  Uint8List hexToUint8List(String hex) {
    if (hex.startsWith("0x") || hex.startsWith("0X")) {
      hex = hex.substring(2);
    }
    if (hex.length % 2 != 0) {
      throw 'Odd number of hex digits';
    }
    var l = hex.length ~/ 2;
    var result = Uint8List(l);
    for (var i = 0; i < l; ++i) {
      var x = int.parse(hex.substring(2 * i, 2 * (i + 1)), radix: 16);
      if (x.isNaN) {
        throw 'Expected hex string';
      }
      result[i] = x;
    }
    return result;
  }

  Future<void> getBgColor() async {
    try {
      if (_webViewController != null) {
        String? manifestUrl =
            await _webViewController?.evaluateJavascript(source: '''
        (function() {
          var link = document.querySelector('link[rel="manifest"]');
          return link ? link.href : null;
        })();
        ''');
        if (manifestUrl == null) {
          log("No manifest");
          return;
        } else {
          log(manifestUrl);
          final response = await http.get(Uri.parse(manifestUrl));
          if (response.statusCode == 200) {
            final manifest = jsonDecode(response.body);
            String? hexColor = manifest['background_color'];
            log("Background color:  $hexColor");
            if (hexColor != null) {
              hexColor = hexColor.replaceAll("#", "");
              if (hexColor.length == 6) {
                hexColor = "FF$hexColor";
              }
              Color bgColor = Color(int.parse("0x$hexColor"));
              setState(() {
                darkNavigatorColor = bgColor;
                log("Color changed to $hexColor");
              });
            }
          }
        }
      }
    } catch (e) {
      logError('Error getting background color: $e');
    }
  }

  Future<void> getSavedCrypto({required PublicData account}) async {
    try {
      final savedCryptos =
          await CryptoStorageManager().getSavedCryptos(wallet: account);
      if (savedCryptos != null) {
        setState(() {
          networks =
              savedCryptos.where((c) => c.type == CryptoType.network).toList();
        });
      }
    } catch (e) {
      logError('Error getting saved crypto: $e');
    }
  }

  @override
  void initState() {
    super.initState();

    getSavedTheme();
    getSavedWallets();
    if (widget.network != null) {
      currentNetwork = widget.network!;
    }
    if (widget.url != null) {
      String url = widget.url!;
      if (!(url.startsWith("http://") || url.startsWith("https://"))) {
        url = "https://$url";
      }
      currentUrl = url;
      if (_webViewController != null) {
        _webViewController!
            .loadUrl(urlRequest: URLRequest(url: WebUri(currentUrl)));
      }
    }
  }

  @override
  void dispose() {
    super.dispose();

    if (_webViewController != null) {
      _webViewController!.dispose();
    }
  }

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
          await getSavedCrypto(account: account);

          isPageLoading = false;

          log("The current wallet is ${json.encode(account.toJson())}");
          break;
        } else {
          log("Not account found");
          isPageLoading = false;

          currentAccount = accounts[0];
        }
      }
    } catch (e) {
      logError('Error getting saved wallets: $e');
      isPageLoading = false;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      final data = ModalRoute.of(context)?.settings.arguments;
      if (data != null && (data as Map<String, dynamic>)["url"] != null) {
        String url = data["url"];
        if (!(url.startsWith("http://") || url.startsWith("https://"))) {
          url = "https://$url";
        }
        currentUrl = url;
        if (_webViewController != null) {
          _webViewController!
              .loadUrl(urlRequest: URLRequest(url: WebUri(currentUrl)));
        }
      }
      _isInitialized = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (isPageLoading) {
      return Center(
        child: SizedBox(
          width: 40,
          height: 40,
          child: CircularProgressIndicator(
            color: colors.themeColor,
          ),
        ),
      );
    }
    return Scaffold(
        backgroundColor: darkNavigatorColor,
        floatingActionButton: !canShowAppBarOptions
            ? FloatingActionButton(
                backgroundColor: colors.grayColor,
                onPressed: toggleShowAppBar,
                child: Icon(
                  LucideIcons.minimize,
                  color: colors.textColor.withOpacity(0.6),
                ),
              )
            : null,
        appBar: !canShowAppBarOptions
            ? null
            : AppBar(
                automaticallyImplyLeading: false,
                title: Row(
                  children: [
                    IconButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        icon: Icon(
                          Icons.arrow_back,
                          color: colors.textColor.withOpacity(0.7),
                          size: 20,
                        )),
                    SizedBox(width: 5),
                    Row(
                      children: [
                        currentUrl.startsWith("https")
                            ? Icon(
                                Icons.lock,
                                size: 20,
                                color: const Color.fromARGB(255, 0, 255, 132),
                              )
                            : Icon(
                                Icons.lock_open,
                                color: Colors.pinkAccent,
                                size: 20,
                              ),
                        SizedBox(width: 2),
                        TextButton(
                            onPressed: () {
                              Clipboard.setData(
                                  ClipboardData(text: currentUrl));
                            },
                            child: Container(
                              width: width * 0.4,
                              child: Text(
                                Uri.parse(currentUrl).host,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.roboto(
                                    color: colors.textColor.withOpacity(0.8),
                                    fontSize: 16),
                              ),
                            ))
                      ],
                    ),
                  ],
                ),
                backgroundColor: darkNavigatorColor,
                actions: [
                  /*  if (isPageLoading) SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        value: progress,
                        color: secondaryColor,
                      ),
                      )  */
                  IconButton(
                    icon: Icon(
                      Icons.more_vert,
                      color: colors.textColor.withOpacity(0.8),
                    ),
                    onPressed: () {
                      showBrowserBottomOptions(
                          context: context,
                          darkNavigatorColor: darkNavigatorColor,
                          colors: colors,
                          title: _title,
                          networks: networks,
                          manualChangeNetwork: manualChangeNetwork,
                          currentNetwork: currentNetwork,
                          chainId: _chainId,
                          currentUrl: currentUrl,
                          reload: _reload,
                          toggleShowAppBar: toggleShowAppBar);
                    },
                  )
                ],
              ),
        body: SafeArea(
            child: Column(
          children: [
            Expanded(
                child: currentAccount == null
                    ? Center(
                        child: SizedBox(
                          width: 40,
                          height: 40,
                          child: CircularProgressIndicator(
                            color: colors.themeColor,
                          ),
                        ),
                      )
                    : Web3WebView(
                        key: webViewKey,
                        onChangeNetwork: (chainId) async {
                          for (final net in networks) {
                            if (chainId == net.chainId) {
                              await changeNetwork(net);
                            }
                          }
                        },
                        onTitleChanged: _onTitleChanged,
                        colors: colors,
                        onConsoleMessage: (crt, msg) {
                          log("console message : $msg");
                        },
                        onWebViewCreated: (crt) {
                          _webViewController = crt;
                        },
                        web3WalletConfig: Web3WalletConfig(
                            currentAccount: currentAccount!,
                            name: "Moon Wallet",
                            icon: "https://moonbnb.pro/moon.png",
                            address: currentAccount?.address,
                            currentNetwork: NetworkConfig(
                                blockExplorerUrls: [
                                  currentNetwork.explorer ?? ""
                                ],
                                chainId:
                                    "0x${(currentNetwork.chainId ?? 1).toRadixString(16)}",
                                chainName: currentNetwork.name,
                                rpcUrls: [currentNetwork.rpc ?? ""]),
                            supportNetworks:
                                List.generate(networks.length, (i) {
                              return NetworkConfig(
                                  chainId:
                                      "0x${networks[i].chainId?.toRadixString(16)}",
                                  chainName: networks[i].name,
                                  rpcUrls: [
                                    networks[i].rpc ?? ""
                                  ],
                                  blockExplorerUrls: [
                                    networks[i].explorer ?? ""
                                  ]);
                            })),
                        initialUrlRequest: URLRequest(
                          url: WebUri(
                            currentUrl, // Replace your dapp domain
                          ),
                        ),
                      ))
          ],
        )));
  }
}
