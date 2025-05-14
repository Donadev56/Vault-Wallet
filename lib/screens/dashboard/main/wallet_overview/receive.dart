// ignore_for_file: deprecated_member_use

import 'dart:ui';

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
import 'package:moonwallet/types/account_related_types.dart';
import 'package:moonwallet/types/types.dart';
import 'package:moonwallet/utils/colors.dart';
import 'package:moonwallet/utils/encrypt_service.dart';
import 'package:moonwallet/utils/share_manager.dart';
import 'package:moonwallet/utils/themes.dart';
import 'package:moonwallet/widgets/actions.dart';
import 'package:moonwallet/widgets/app_bar_title.dart';
import 'package:moonwallet/widgets/screen_widgets/crypto_picture.dart';
import 'package:pretty_qr_code/pretty_qr_code.dart';

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

  List<PublicAccount> accounts = [];
  List<PublicAccount> filteredAccounts = [];
  late PublicAccount currentAccount;
  final web3Manager = WalletDatabase();
  final encryptService = EncryptService();
  final priceManager = PriceManager();
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

    double iconSizeOf(double size) {
      return size * uiConfig.value.styles.iconSizeScaleFactor;
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
            Icons.chevron_left,
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
                                fontSize: fontSizeOf(12),
                                color: warningColor,
                                fontWeight: FontWeight.bold),
                          ),
                          TextSpan(
                            text:
                                " assets to this address , other assets will be lost forever.",
                            style: textTheme.bodyMedium?.copyWith(
                                color: warningColor, fontSize: fontSizeOf(12)),
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
                    height: 20,
                  ),
                  ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: 300,
                      ),
                      child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(roundedOf(10)),
                            color: Colors.white,
                          ),
                          child: LayoutBuilder(builder: (ctx, c) {
                            return PrettyQrView.data(
                              data: currentAccount.addressByToken(crypto!),
                              decoration: const PrettyQrDecoration(
                                image: PrettyQrDecorationImage(
                                    image:
                                        AssetImage("assets/logo/png/icon.png")),
                                quietZone: PrettyQrQuietZone.standart,
                              ),
                            );
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
                      ),
                      child: Center(
                        child: GestureDetector(
                          onTap: () => Clipboard.setData(ClipboardData(
                            text: currentAccount.addressByToken(crypto!),
                          )),
                          child: Text(
                            currentAccount.addressByToken(crypto!),
                            overflow: TextOverflow.fade,
                            textAlign: TextAlign.center,
                            style: textTheme.bodyMedium?.copyWith(
                                color: colors.textColor,
                                fontWeight: FontWeight.bold,
                                fontSize: fontSizeOf(14)),
                          ),
                        ),
                      ))),
            ),
            SizedBox(
              height: 10,
            ),
            Align(
              alignment: Alignment.center,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ActionsWidgets(
                    radius: roundedOf(30),
                    showName: false,
                    size: iconSizeOf(60),
                    fontSize: fontSizeOf(14),
                    iconSize: iconSizeOf(20),
                    color: colors.secondaryColor,
                    textColor: colors.textColor,
                    text: "Copy",
                    onTap: () => Clipboard.setData(ClipboardData(
                        text: currentAccount.addressByToken(crypto!))),
                    actIcon: Icons.copy,
                  ),
                  ActionsWidgets(
                    showName: false,
                    radius: roundedOf(30),
                    size: iconSizeOf(60),
                    fontSize: fontSizeOf(14),
                    iconSize: iconSizeOf(20),
                    color: colors.secondaryColor,
                    textColor: colors.textColor,
                    text: "Share",
                    onTap: () async {
                      final qrCode = QrCode.fromData(
                        data: currentAccount.addressByToken(crypto!),
                        errorCorrectLevel: QrErrorCorrectLevel.H,
                      );

                      final qrImage = QrImage(qrCode);
                      final qrImageBytes = await qrImage.toImageAsBytes(
                        size: 512,
                        format: ImageByteFormat.png,
                        decoration: const PrettyQrDecoration(
                          quietZone: PrettyQrQuietZone.standart,
                          image: PrettyQrDecorationImage(
                              padding: EdgeInsets.all(20),
                              image: AssetImage("assets/logo/png/icon.png")),
                          background: Colors.white,
                        ),
                      );
                      if (qrImageBytes == null) {
                        return;
                      }

                      await ShareManager().shareQrImage(qrImageBytes);
                    },
                    actIcon: Icons.share,
                  )
                ],
              ),
            )
          ],
        )),
      ),
    );
  }
}
