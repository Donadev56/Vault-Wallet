import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:moonwallet/logger/logger.dart';
import 'package:moonwallet/notifiers/providers.dart';
import 'package:moonwallet/screens/dashboard/trending/crypto_trend_view.dart';
import 'package:moonwallet/service/external_data/crypto_request_manager.dart';
import 'package:moonwallet/service/external_data/price_manager.dart';
import 'package:moonwallet/types/account_related_types.dart';
import 'package:moonwallet/types/types.dart';
import 'package:moonwallet/utils/colors.dart';
import 'package:moonwallet/utils/number_formatter.dart';
import 'package:moonwallet/widgets/func/snackbar.dart';
import 'package:moonwallet/widgets/screen_widgets/chips.dart';
import 'package:moonwallet/widgets/screen_widgets/crypto_picture.dart';
import 'package:moonwallet/widgets/custom_filled_text_field.dart';
import 'package:moonwallet/widgets/screen_widgets/trending_list_view.dart';
import 'package:numeral/numeral.dart';
import 'package:page_transition/page_transition.dart';

class TrendingScreen extends StatefulHookConsumerWidget {
  final AppColors colors;
  const TrendingScreen({super.key, required this.colors});

  @override
  ConsumerState<TrendingScreen> createState() => _TrendingScreenState();
}

class _TrendingScreenState extends ConsumerState<TrendingScreen> {
  AppColors colors = AppColors.defaultTheme;
  List<CryptoMarketData> listMarketData = [];
  final formatter = NumberFormatter();

  @override
  void initState() {
    super.initState();
    colors = widget.colors;
    getSavedTheme();

    fetchMarketData();
  }

  Future<void> getSavedTheme() async {
    final manager = ColorsManager();
    final savedTheme = await manager.getDefaultTheme();
    setState(() {
      colors = savedTheme;
    });
  }

  Future<void> fetchMarketData() async {
    try {
      final response = await PriceManager().getListTokensMarketData();
      if (response.isNotEmpty) {
        setState(() {
          listMarketData = response;
        });
        return;
      }
      logError("No Market Data found");
    } catch (e) {
      logError(e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = TextTheme.of(context);
    final appUIConfigAsync = ref.watch(appUIConfigProvider);

    final uiConfig = useState<AppUIConfig>(AppUIConfig.defaultConfig);
    final cryptoList = useState<List<Crypto>>([]);
    final networks = cryptoList.value.where((c) => c.isNative).toList();
    final networkKeyId = useState<String?>(null);
    final query = useState<String>("");

    useEffect(() {
      appUIConfigAsync.whenData((data) {
        uiConfig.value = data;
      });
      return null;
    }, [appUIConfigAsync]);

    useEffect(() {
      Future<void> getListCrypto() async {
        try {
          final listCrypto = await CryptoRequestManager().getSavedCrypto();
          if (listCrypto.isNotEmpty) {
            cryptoList.value = listCrypto;
          }
        } catch (e) {
          logError(e.toString());
        }
      }

      getListCrypto();
      return null;
    }, []);

    notifyError(String message) => showCustomSnackBar(
        context: context,
        message: message,
        colors: colors,
        type: MessageType.error);

    double fontSizeOf(double size) {
      return size * uiConfig.value.styles.fontSizeScaleFactor;
    }

    double iconSizeOf(double size) {
      return size * uiConfig.value.styles.iconSizeScaleFactor;
    }

    double roundedOf(double size) {
      return size * uiConfig.value.styles.radiusScaleFactor;
    }

    double imageSizeOf(double size) {
      return size * uiConfig.value.styles.imageSizeScaleFactor;
    }

    List<Crypto> filteredCryptos() {
      final searchingCryptos = cryptoList.value
          .where((c) =>
              c.name.toLowerCase().contains(query.value.toLowerCase()) ||
              c.symbol.toLowerCase().contains(query.value.toLowerCase()))
          .toList();
      if (networkKeyId.value == null) {
        return searchingCryptos;
      }

      return searchingCryptos
          .where((c) =>
              c.network?.cryptoId.toLowerCase() ==
                  networkKeyId.value?.toLowerCase() ||
              c.cryptoId.toLowerCase() == networkKeyId.value?.toLowerCase())
          .toList();
    }

    return Scaffold(
      backgroundColor: colors.primaryColor,
      appBar: AppBar(
        backgroundColor: colors.primaryColor,
        surfaceTintColor: colors.primaryColor,
        automaticallyImplyLeading: false,
        title: Text(
          "Trending",
          style: textTheme.headlineMedium?.copyWith(
              fontSize: fontSizeOf(20),
              fontWeight: FontWeight.bold,
              color: colors.textColor),
        ),
      ),
      body: Padding(
          padding: const EdgeInsets.all(15),
          child: Column(
            children: [
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: List.generate(networks.length + 1, (index) {
                    if (index == 0) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 5),
                        child: GestureDetector(
                            onTap: () => networkKeyId.value = null,
                            child: IconChip(
                                colors: colors,
                                icon: Icon(
                                  Icons.public,
                                  color: colors.textColor,
                                ),
                                text: "All",
                                textColor: networkKeyId.value == null
                                    ? colors.themeColor
                                    : null,
                                useBorder: networkKeyId.value == null)),
                      );
                    }

                    final network = networks[index - 1];
                    final keyId = network.cryptoId;
                    final isSelected = networkKeyId.value == keyId;
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 5),
                      child: NetworkChip(
                        colors: colors,
                        isSelected: isSelected,
                        network: network,
                        onTap: () => networkKeyId.value = keyId,
                      ),
                    );
                  }),
                ),
              ),
              SizedBox(
                height: 15,
              ),
              SizedBox(
                height: 40,
                child: CustomFilledTextFormField(
                    onChanged: (v) {
                      query.value = v;
                    },
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 5, vertical: 0),
                    colors: colors,
                    hintText: "Search",
                    prefixIcon: Icon(Icons.search),
                    rounded: 30,
                    fontSizeOf: fontSizeOf,
                    iconSizeOf: iconSizeOf,
                    roundedOf: roundedOf),
              ),
              SizedBox(
                height: 15,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Volume",
                      style: textTheme.bodyMedium?.copyWith(
                          color: colors.textColor, fontSize: fontSizeOf(14)),
                    ),
                    Text(
                      "Price",
                      style: textTheme.bodyMedium?.copyWith(
                          color: colors.textColor, fontSize: fontSizeOf(14)),
                    )
                  ],
                ),
              ),
              SizedBox(
                height: 15,
              ),
              Expanded(
                  child: ListView(
                children: List.generate(filteredCryptos().length, (i) {
                  final crypto = filteredCryptos()[i];
                  final marketData = listMarketData
                      .where((e) =>
                          e.id.trim().toLowerCase() ==
                          crypto.cgSymbol?.trim().toLowerCase())
                      .toList()
                      .firstOrNull;

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: TrendingListTitle(
                      fontSizeOf: fontSizeOf,
                      roundedOf: roundedOf,
                      onTap: () {
                        if (marketData == null) {
                          notifyError("No market data for ${crypto.symbol}");
                          return;
                        }
                        Navigator.push(
                            context,
                            PageTransition(
                                alignment: Alignment.center,
                                type: PageTransitionType.theme,
                                child: CryptoTrendView(
                                    coin: crypto,
                                    marketData: marketData,
                                    colors: colors,
                                    roundedOf: roundedOf,
                                    fontSizeOf: fontSizeOf,
                                    iconSizeOf: iconSizeOf,
                                    imageSizeOf: imageSizeOf)));
                      },
                      icon: CryptoPicture(
                          crypto: crypto, size: 30, colors: colors),
                      name: crypto.symbol,
                      percent: marketData?.priceChangePercentage24h ?? 0,
                      price:
                          "\$${(formatter.formatDecimal((marketData?.currentPrice ?? 0).toString()))}",
                      volume: "\$${(marketData?.totalVolume ?? 0).numeral()}",
                      colors: colors,
                    ),
                  );
                }),
              ))
            ],
          )),
    );
  }
}
