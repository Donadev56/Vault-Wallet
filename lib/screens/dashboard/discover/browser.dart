// ignore_for_file: deprecated_member_use

import 'package:http/http.dart' as http;
import 'package:moonwallet/service/db/crypto_storage_manager.dart';
import 'package:moonwallet/service/external_data/price_manager.dart';

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:moonwallet/logger/logger.dart';
import 'package:moonwallet/service/db/wallet_db.dart';
import 'package:moonwallet/types/types.dart';
import 'package:moonwallet/utils/colors.dart';
import 'package:moonwallet/utils/constant.dart';
import 'package:moonwallet/utils/crypto.dart';
import 'package:moonwallet/utils/prefs.dart';
import 'package:moonwallet/utils/themes.dart';
import 'package:moonwallet/custom/web3_webview/lib/web3_webview.dart';
import 'package:moonwallet/widgets/func/browser/show_bottom_options.dart';

class Web3BrowserScreen extends StatefulWidget {
  final String? url;
  final Crypto? network;
  final List<Crypto> networks;
  final AppColors? colors;
  final PublicData account;

  const Web3BrowserScreen(
      {super.key,
      required this.networks,
      required this.account,
      this.url,
      this.network,
      this.colors});

  @override
  Web3BrowserScreenState createState() => Web3BrowserScreenState();
}

class Web3BrowserScreenState extends State<Web3BrowserScreen> {
  Color darkNavigatorColor = Color(0XFF0D0D0D);
  Color darkNavigatorColorMainValue = Color(0XFF0D0D0D);
  final GlobalKey<InAppWebViewEIP1193State> webViewKey = GlobalKey();
  final publicDataManager = PublicDataManager();
  bool isDarkMode = false;

  String _title = 'Loading...';
  String currentUrl = 'https://www.moonbnb.pro';
  bool canShowAppBarOptions = true;
  int _chainId = 204;
  double progress = 0;
  bool isLoading = true;
  bool isPageLoading = false;

  Crypto? currentCrypto;

  InAppWebViewController? _webViewController;
  bool _isInitialized = false;
  bool isFullScreen = false;
  List<PublicData> accounts = [];
  List<Crypto> networks = [];
  PublicData? currentAccount;
  final web3Manager = WalletDatabase();
  final priceManager = PriceManager();

  final encryptService = EncryptService();
  final String historyName = "UserHistory";
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
    if (currentCrypto == null) {
      log("Current crypto is null");
      return false;
    }

    int requestedChainId = network.chainId ?? 1;

    for (final net in networks) {
      log("Current network : ${net.chainId} . requested chain $requestedChainId");

      if (net.chainId == requestedChainId) {
        setState(() {
          currentCrypto = net;
          _chainId = requestedChainId;
          log("Switched to network: ${currentCrypto!.name}");
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
            currentCrypto = net;
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
          networks = savedCryptos.where((c) => c.isNative).toList();
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
    init();
  }

  void init() {
    setState(() {
      currentAccount = widget.account;
      networks = widget.networks;

      if (widget.network != null) {
        currentCrypto = widget.network!;
        _chainId = widget.network!.chainId!;
      }

      if (widget.colors != null) {
        colors = widget.colors!;
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

      isLoading = false;
    });
  }

  @override
  void dispose() {
    super.dispose();

    if (_webViewController != null) {
      _webViewController!.dispose();
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
    final textTheme = Theme.of(context).textTheme;
    if (isLoading) {
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
                        onPressed: () async {
                          if (_webViewController != null &&
                              await _webViewController!.canGoBack()) {
                            _webViewController!.goBack();
                            return;
                          }
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
                                style: textTheme.bodyMedium?.copyWith(
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
                          controller: _webViewController!,
                          onClose: () {
                            // close the first context
                            Navigator.pop(context);
                            // close the second context
                            Navigator.pop(context);
                          },
                          onShareClick: () async {
                            share(
                                subject: "Share Url",
                                text:
                                    "take a look at this url ${(await _webViewController?.getUrl()).toString()}");
                          },
                          context: context,
                          darkNavigatorColor: darkNavigatorColor,
                          colors: colors,
                          title: _title,
                          networks: networks,
                          manualChangeNetwork: manualChangeNetwork,
                          currentNetwork: currentCrypto!,
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
            if (isPageLoading)
              LinearProgressIndicator(
                borderRadius: BorderRadius.circular(10),
                minHeight: 2,
                color: colors.themeColor,
                backgroundColor: colors.secondaryColor,
                value: (progress / 100),
              ),
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
                        onLoadStart: (c, url) {
                          setState(() {
                            isPageLoading = true;
                            currentUrl = url.toString();
                          });
                        },
                        onLoadStop: (c, url) {
                          setState(() {
                            isPageLoading = false;
                          });
                          log("onLoadStop : $url");
                        },
                        onTitleChanged: _onTitleChanged,
                        onProgressChanged: (c, value) {
                          setState(() {
                            progress = value.toDouble();
                          });
                        },
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
                                blockExplorerUrls: currentCrypto?.explorers,
                                chainId:
                                    "0x${(currentCrypto!.chainId ?? 1).toRadixString(16)}",
                                chainName: currentCrypto!.name,
                                rpcUrls: currentCrypto!.rpcUrls ?? []),
                            supportNetworks:
                                List.generate(networks.length, (i) {
                              final network = networks[i];
                              return NetworkConfig(
                                  nativeCurrency: NativeCurrency(
                                      name: network.name,
                                      symbol: network.symbol,
                                      decimals: network.decimals),
                                  chainId:
                                      "0x${networks[i].chainId?.toRadixString(16)}",
                                  chainName: network.name,
                                  rpcUrls: network.rpcUrls ?? [],
                                  blockExplorerUrls: network.explorers);
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
