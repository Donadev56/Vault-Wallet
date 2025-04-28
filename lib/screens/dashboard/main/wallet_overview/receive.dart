// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:moonwallet/logger/logger.dart';
import 'package:moonwallet/notifiers/providers.dart';
import 'package:moonwallet/service/db/crypto_storage_manager.dart';
import 'package:moonwallet/service/external_data/price_manager.dart';
import 'package:moonwallet/service/db/wallet_db.dart';
import 'package:moonwallet/types/types.dart';
import 'package:moonwallet/utils/colors.dart';
import 'package:moonwallet/utils/crypto.dart';
import 'package:moonwallet/utils/prefs.dart';
import 'package:moonwallet/utils/themes.dart';
import 'package:moonwallet/widgets/app_bar_title.dart';
import 'package:moonwallet/widgets/screen_widgets/crypto_picture.dart';
import 'package:qr_flutter/qr_flutter.dart';

class ReceiveScreen extends StatefulHookConsumerWidget {
  final WidgetInitialData initData;
  const ReceiveScreen({super.key, required this.initData});

  @override
  ConsumerState<ReceiveScreen> createState() => _ReceiveScreenState();
}

class _ReceiveScreenState extends ConsumerState<ReceiveScreen> {
  Color warningColor = Colors.orange;
  bool isDarkMode = false;
  final cryptoStorageManager = CryptoStorageManager();

  List<PublicData> accounts = [];
  List<PublicData> filteredAccounts = [];
  PublicData currentAccount = PublicData(
      createdLocally: false,
      keyId: "",
      creationDate: 0,
      walletName: "",
      address: "",
      isWatchOnly: false);
  final web3Manager = WalletDatabase();
  final encryptService = EncryptService();
  final priceManager = PriceManager();
  final publicDataManager = PublicDataManager();
  Crypto? crypto;
  @override
  void initState() {
    super.initState();

    getSavedTheme();
    init();
  }

  void init() async {
    setState(() {
      currentAccount = widget.initData.account;
      crypto = widget.initData.crypto;
      colors = widget.initData.colors;
    });
  }

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
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final textTheme = Theme.of(context).textTheme;
    //final height = MediaQuery.of(context).size.height;
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

    double imageSizeOf(double size) {
      return size * uiConfig.value.styles.imageSizeScaleFactor;
    }

    double roundedOf(double size) {
      return size * uiConfig.value.styles.radiusScaleFactor;
    }

    if (crypto == null) {
      return Center(
        child: CircularProgressIndicator(
          color: colors.themeColor,
        ),
      );
    }

    return Scaffold(
      backgroundColor: colors.primaryColor,
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: colors.primaryColor,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: colors.textColor,
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: AppBarTitle(title: "Receive", colors: colors),
      ),
      body: Padding(
        padding: const EdgeInsets.all(15),
        child: SingleChildScrollView(
            child: Column(
          children: [
            Container(
              height: 60,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10.0),
                color: warningColor.withOpacity(0.15),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Icon(
                    LucideIcons.octagonAlert,
                    color: warningColor,
                  ),
                  SizedBox(
                    width: 5,
                  ),
                  Expanded(
                      child: RichText(
                    text: TextSpan(
                        text: "Only send ",
                        style:
                            textTheme.bodyMedium?.copyWith(color: warningColor),
                        children: [
                          TextSpan(
                            text: crypto!.name,
                            style: textTheme.bodyMedium?.copyWith(
                                color: warningColor,
                                fontWeight: FontWeight.bold),
                          ),
                          TextSpan(
                            text:
                                " assets to this address , other assets will be lost forever.",
                            style: textTheme.bodyMedium
                                ?.copyWith(color: warningColor),
                          )
                        ]),
                    overflow: TextOverflow.clip,
                  ))
                ],
              ),
            ),
            SizedBox(
              height: 20,
            ),
            Center(
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      CryptoPicture(
                          crypto: crypto!,
                          size: imageSizeOf(30),
                          colors: colors),
                      SizedBox(
                        width: 10,
                      ),
                      Text(
                        crypto!.symbol,
                        style: textTheme.bodyMedium?.copyWith(
                            color: colors.textColor,
                            fontSize: fontSizeOf(20),
                            fontWeight: FontWeight.w500),
                      )
                    ],
                  ),
                  SizedBox(
                    height: 10,
                  ),
                  ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: 300,
                      ),
                      child: Container(
                          padding: const EdgeInsets.all(10),
                          margin: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(roundedOf(10)),
                            color: Colors.white,
                          ),
                          child: LayoutBuilder(builder: (ctx, c) {
                            return Center(
                                child: Stack(
                              alignment: Alignment.center,
                              children: [
                                ConstrainedBox(
                                  constraints: BoxConstraints(
                                      maxWidth: 300, maxHeight: 270),
                                  child: QrImageView(
                                    data: currentAccount.address,
                                    version: 3,
                                    size: width * 0.8,
                                    gapless: false,
                                  ),
                                ),
                                Positioned(
                                    child: Container(
                                        padding: const EdgeInsets.all(2),
                                        decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(
                                                roundedOf(50))),
                                        child: CryptoPicture(
                                            crypto: crypto!,
                                            size: 30,
                                            colors: colors)))
                              ],
                            ));
                          })))
                ],
              ),
            ),
            SizedBox(
              height: 10,
            ),
            Center(
              child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: 300,
                  ),
                  child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(roundedOf(30)),
                          color: colors.secondaryColor),
                      child: Center(
                        child: Text(
                          currentAccount.address,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.bodyMedium?.copyWith(
                              color: colors.textColor,
                              fontSize: fontSizeOf(11)),
                        ),
                      ))),
            ),
            SizedBox(
              height: 10,
            ),
            ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: 300,
                ),
                child: SizedBox(
                  width: width * 0.85,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                        elevation: 0, backgroundColor: colors.themeColor),
                    onPressed: () {
                      Clipboard.setData(
                          ClipboardData(text: currentAccount.address.trim()));
                    },
                    icon: Icon(
                      Icons.copy,
                      color: colors.primaryColor,
                    ),
                    label: Text(
                      "Copy the address",
                      style: textTheme.bodyMedium?.copyWith(
                          color: colors.primaryColor, fontSize: fontSizeOf(14)),
                    ),
                  ),
                ))
          ],
        )),
      ),
    );
  }
}
