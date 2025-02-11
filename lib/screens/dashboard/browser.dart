// ignore_for_file: deprecated_member_use
import 'package:http/http.dart' as http;

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:flutter_web3_webview/flutter_web3_webview.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:moonwallet/logger/logger.dart';
import 'package:moonwallet/service/web3.dart';
import 'package:moonwallet/types/types.dart';
import 'package:moonwallet/utils/constant.dart';
import 'package:moonwallet/utils/crypto.dart';
import 'package:moonwallet/utils/prefs.dart';

class Web3BrowserScreen extends StatefulWidget {
  const Web3BrowserScreen({super.key});

  @override
  Web3BrowserScreenState createState() => Web3BrowserScreenState();
}

class Web3BrowserScreenState extends State<Web3BrowserScreen> {
  Color primaryColor = Color(0XFF1B1B1B);
  Color textColor = Color(0xFFF5F5F5);
  Color secondaryColor = Colors.greenAccent;
  Color actionsColor = Color(0XFF353535);
  Color surfaceTintColor = Color(0XFF454545);
  Color darkNavigatorColor = Color(0XFF0D0D0D);
  String _title = '';
  String currentUrl = 'https://www.google.com';
  bool canShowAppBarOptions = true;
  int _chainId = 204;
  InAppWebViewController? _webViewController;
  bool _isInitialized = false;
  bool isFullScreen = false;
  List<PublicData> accounts = [];
  PublicData? currentAccount;
  final web3Manager = Web3Manager();
  final encryptService = EncryptService();
  final String historyName = "UserHistory";

  void toggleShowAppBar() {
    getBgColor();
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

  Future<int> _ethChainId() async {
    return _chainId;
  }

  Future<List<String>> _ethAccounts() async {
    return [currentAccount!.address];
  }

  Future<bool> _walletSwitchEthereumChain(JsAddEthereumChain data) async {
    _chainId =
        int.parse((data.chainId)?.replaceFirst('0x', '') ?? '1', radix: 16);
    return true;
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

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Color(0xFF0D0D0D),
        statusBarIconBrightness: Brightness.light,
      ),
    );
    getSavedWallets();
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
          log("The current wallet is ${json.encode(account.toJson())}");
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

  void openModalBottomSheet() async {
    try {
      log("open modal bottom sheet");

      showModalBottomSheet(
          context: context,
          builder: (BuildContext context) {
            double width = MediaQuery.of(context).size.width;
            double height = MediaQuery.of(context).size.height;

            return Container(
              width: width,
              decoration: BoxDecoration(
                color: darkNavigatorColor,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.all(10),
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          margin: const EdgeInsets.only(left: 4),
                          child: Row(
                            children: [
                              SizedBox(
                                width: width * 0.3,
                                child: Text(
                                  _title,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.roboto(
                                      color: textColor,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 22),
                                ),
                              ),
                              SizedBox(
                                width: 10,
                              ),
                              Container(
                                padding: const EdgeInsets.all(2),
                                decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(50),
                                    border: Border.all(
                                        width: 1,
                                        color: Colors.orange.withOpacity(0.8))),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(50),
                                  child: Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(50),
                                      onTap: () {
                                        log("onTap");
                                      },
                                      child: Image.asset(
                                        "assets/b1.webp",
                                        width: 30,
                                        height: 30,
                                      ),
                                    ),
                                  ),
                                ),
                              )
                            ],
                          ),
                        ),
                        ConstrainedBox(
                          constraints:
                              BoxConstraints(maxWidth: 190, maxHeight: 70),
                          child: Container(
                            height: 40,
                            padding: const EdgeInsets.only(left: 7),
                            margin: const EdgeInsets.only(top: 10),
                            decoration: BoxDecoration(
                                color: secondaryColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(30)),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(20),
                                onTap: () {
                                  Clipboard.setData(
                                      ClipboardData(text: currentUrl));
                                },
                                child: Row(
                                  children: [
                                    ConstrainedBox(
                                      constraints:
                                          BoxConstraints(maxWidth: 140),
                                      child: Text(
                                        currentUrl,
                                        style: GoogleFonts.roboto(
                                          color: textColor.withOpacity(0.8),
                                          fontSize: 14,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    SizedBox(
                                      width: 5,
                                    ),
                                    Icon(
                                      FeatherIcons.copy,
                                      color: secondaryColor,
                                    )
                                  ],
                                ),
                              ),
                            ),
                          ),
                        )
                      ],
                    ),
                  ),
                  Divider(
                    color: textColor.withOpacity(0.05),
                  ),
                  Column(
                    children: List.generate(options.length, (index) {
                      final option = options[index];
                      return Material(
                        color: Colors.transparent,
                        child: ListTile(
                          onTap: () {
                            if (index == 0) {
                              _reload();
                              Navigator.pop(context);
                            } else if (index == 1) {
                              showDialog(
                                  context: context,
                                  builder: (BuildContext context) {
                                    return Dialog(
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(15)),
                                      child: Container(
                                        height: height * 0.5,
                                        decoration: BoxDecoration(
                                            color: darkNavigatorColor,
                                            borderRadius:
                                                BorderRadius.circular(10)),
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.start,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.only(
                                                  top: 20,
                                                  left: 15,
                                                  bottom: 10),
                                              child: Text(
                                                "Change Network :",
                                                style: GoogleFonts.roboto(
                                                    color: textColor,
                                                    fontWeight:
                                                        FontWeight.bold),
                                              ),
                                            ),
                                            ConstrainedBox(
                                              constraints: BoxConstraints(
                                                  maxHeight: height * 0.4),
                                              child: ListView.builder(
                                                itemCount: networks.length,
                                                itemBuilder:
                                                    (BuildContext context,
                                                        int index) {
                                                  final network =
                                                      networks[index];
                                                  return Material(
                                                    color: Colors.transparent,
                                                    child: ListTile(
                                                      selected: _chainId ==
                                                          network.chainId,
                                                      onTap: () {
                                                        log('message');
                                                      },
                                                      leading: Container(
                                                        padding:
                                                            const EdgeInsets
                                                                .all(4),
                                                        decoration: BoxDecoration(
                                                            border: Border.all(
                                                                width: 1,
                                                                color: network
                                                                    .color),
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        50)),
                                                        child: ClipRRect(
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(50),
                                                          child: Image.asset(
                                                            network.icon,
                                                            width: 30,
                                                            height: 30,
                                                          ),
                                                        ),
                                                      ),
                                                      title: Text(
                                                        network.name,
                                                        style:
                                                            GoogleFonts.roboto(
                                                                color:
                                                                    textColor),
                                                      ),
                                                      trailing: Icon(
                                                        Icons
                                                            .arrow_right_outlined,
                                                        color: textColor
                                                            .withOpacity(0.6),
                                                      ),
                                                    ),
                                                  );
                                                },
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  });
                            } else if (index == 2) {
                              toggleShowAppBar();
                              Navigator.pop(context);
                            } else if (index == 3) {
                              toggleShowAppBar();
                              Navigator.pop(context);
                            }
                          },
                          title: Row(
                            children: [
                              Text(
                                option["name"],
                                style: GoogleFonts.roboto(
                                  color: textColor,
                                ),
                              ),
                              SizedBox(
                                width: 7,
                              ),
                              if (index == 1)
                                Container(
                                  padding: const EdgeInsets.all(5),
                                  decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(10),
                                      color: primaryColor),
                                  child: Text(
                                    "OpBNB",
                                    style: GoogleFonts.roboto(
                                      color: textColor,
                                    ),
                                  ),
                                )
                            ],
                          ),
                          trailing: Icon(
                            option["icon"],
                            color: textColor.withOpacity(0.6),
                          ),
                        ),
                      );
                    }),
                  )
                ],
              ),
            );
          });
    } catch (e) {
      logError(e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return Scaffold(
        backgroundColor: darkNavigatorColor,
        floatingActionButton: !canShowAppBarOptions
            ? IconButton(
                onPressed: toggleShowAppBar,
                icon: Icon(
                  LucideIcons.minimize,
                  color: textColor.withOpacity(0.6),
                ))
            : null,
        appBar: !canShowAppBarOptions
            ? null
            : AppBar(
                automaticallyImplyLeading: false,
                title: canShowAppBarOptions
                    ? Row(
                        children: [
                          IconButton(
                              onPressed: () {
                                Navigator.pop(context);
                              },
                              icon: Icon(
                                Icons.arrow_back,
                                color: textColor.withOpacity(0.7),
                                size: 20,
                              )),
                          SizedBox(width: 5),
                          Row(
                            children: [
                              currentUrl.startsWith("https")
                                  ? Icon(
                                      Icons.lock,
                                      size: 20,
                                      color: const Color.fromARGB(
                                          255, 0, 255, 132),
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
                                  width: width * 0.5,
                                  child:Text(
                                  Uri.parse(currentUrl).host,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.roboto(
                                      color: textColor.withOpacity(0.8),
                                      fontSize: 16),
                                ) ,
                                ) 
                              )
                            ],
                          ),
                        ],
                      )
                    : null,
                backgroundColor: darkNavigatorColor,
                actions: canShowAppBarOptions
                    ? [
                        IconButton(
                          icon: Icon(
                            Icons.more_vert,
                            color: textColor.withOpacity(0.8),
                          ),
                          onPressed: openModalBottomSheet,
                        )
                      ]
                    : null,
              ),
        body: SafeArea(
            child: Web3Webview(
                onWebViewCreated: (crl) {
                  _webViewController = crl;
                },
                initialUrlRequest: URLRequest(url: WebUri(currentUrl)),
                settings: Web3Settings(
                    eth: Web3EthSettings(
                        chainId: _chainId, rdns: 'com.opennode.moonwallet')),
                shouldOverrideUrlLoading: (p0, action) async =>
                    NavigationActionPolicy.ALLOW,
                onTitleChanged: _onTitleChanged,
                ethAccounts: _ethAccounts,
                ethChainId: _ethChainId,
                walletSwitchEthereumChain: _walletSwitchEthereumChain)));
  }
}
