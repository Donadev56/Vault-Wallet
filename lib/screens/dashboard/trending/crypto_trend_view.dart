import 'package:flutter/material.dart';
import 'package:moonwallet/logger/logger.dart';
import 'package:moonwallet/service/external_data/price_manager.dart';
import 'package:moonwallet/types/account_related_types.dart';
import 'package:moonwallet/types/types.dart';
import 'package:moonwallet/utils/number_formatter.dart';
import 'package:moonwallet/widgets/charts_/line_chart.dart';
import 'package:moonwallet/widgets/dialogs/show_custom_snackbar.dart';
import 'package:moonwallet/widgets/screen_widgets/crypto_picture.dart';
import 'package:moonwallet/widgets/screen_widgets/standard_app_bar.dart';
import 'package:numeral/numeral.dart';
import 'package:url_launcher/url_launcher.dart';

class CryptoTrendView extends StatefulWidget {
  final Crypto coin;
  final AppColors colors;
  final DoubleFactor roundedOf;
  final DoubleFactor fontSizeOf;
  final DoubleFactor iconSizeOf;
  final DoubleFactor imageSizeOf;

  final CryptoMarketData marketData;
  const CryptoTrendView(
      {super.key,
      required this.coin,
      required this.marketData,
      required this.colors,
      required this.roundedOf,
      required this.fontSizeOf,
      required this.iconSizeOf,
      required this.imageSizeOf});

  @override
  State<CryptoTrendView> createState() => _CryptoTrendViewState();
}

class _CryptoTrendViewState extends State<CryptoTrendView> {
  late Crypto coin;
  late CryptoMarketData data;
  AppColors colors = AppColors.defaultTheme;
  late DoubleFactor roundedOf;
  late DoubleFactor fontSizeOf;
  late DoubleFactor iconSizeOf;
  late DoubleFactor imageSizeOf;
  final NumberFormatter formatter = NumberFormatter();
  List<(DateTime, double)>? cryptoData;
  TransformationController transformationController =
      TransformationController();
  final Offset offset = Offset(-500.0, 0.0);
  final double scale = 4.0;
  final intervals = [
    '1',
    '14',
    '30',
    '90',
    '365',
  ];
  int currentIndex = 0;

  @override
  void initState() {
    super.initState();

    coin = widget.coin;
    data = widget.marketData;
    colors = widget.colors;
    roundedOf = widget.roundedOf;
    fontSizeOf = widget.fontSizeOf;
    iconSizeOf = widget.iconSizeOf;
    imageSizeOf = widget.imageSizeOf;

    transformationController.value = Matrix4.identity()
      ..translate(offset.dx, offset.dy)
      ..scale(scale);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      loadData(intervals[0]);
    });
  }

  Future<void> loadData(String interval) async {
    try {
      final data = await PriceManager().getPriceDataUsingCg(coin, interval);

      if (data == null) {
        logError("Data is Null");
        return;
      }
      setState(() {
        cryptoData = data.map((item) {
          final timestamp = item[0] as int;
          final price = item[1] as double;
          return (DateTime.fromMillisecondsSinceEpoch(timestamp), price);
        }).toList();
      });
    } catch (e) {
      logError(e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = TextTheme.of(context);
    final explorers = coin.isNative ? coin.explorers : coin.network?.explorers;

    return Scaffold(
      backgroundColor: colors.primaryColor,
      appBar: StandardAppBar(
          title: coin.symbol, colors: colors, fontSizeOf: fontSizeOf),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15),
        child: ListView(
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Column(
                children: [
                  Row(
                    spacing: 10,
                    children: [
                      CryptoPicture(
                          crypto: coin, size: iconSizeOf(35), colors: colors),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            coin.name.toUpperCase(),
                            style: textTheme.bodyLarge?.copyWith(
                                fontSize: fontSizeOf(16),
                                fontWeight: FontWeight.w800,
                                color: colors.textColor),
                          ),
                          Text(
                            "${coin.isNative ? coin.name : coin.network?.name}",
                            style: textTheme.bodyLarge?.copyWith(
                                fontSize: fontSizeOf(14),
                                color: colors.textColor.withValues(alpha: 0.7)),
                          ),
                        ],
                      )
                    ],
                  ),
                  SizedBox(
                    height: 15,
                  ),
                  Row(
                    spacing: 15,
                    children: [
                      Text(
                        "\$${NumberFormatter().formatDecimal(data.currentPrice.toString())}",
                        style: textTheme.bodyMedium?.copyWith(
                            color: colors.textColor, fontSize: fontSizeOf(15)),
                      ),
                      Text(
                        "${data.priceChangePercentage24h}%",
                        style: textTheme.bodyMedium?.copyWith(
                            color: data.priceChangePercentage24h > 0
                                ? colors.greenColor
                                : colors.redColor,
                            fontSize: fontSizeOf(15)),
                      )
                    ],
                  ),
                  Divider(
                    color: colors.secondaryColor.withValues(alpha: 0.6),
                  ),
                  SizedBox(
                    height: 15,
                  ),
                  AspectRatio(
                      aspectRatio: 1.7,
                      child: CustomLineChart(
                        showGradient: false,
                        transformationController: transformationController,
                        chartData: cryptoData,
                        symbol: "",
                        colors: colors,
                        isPositive: data.priceChangePercentage24h > 0,
                      )),
                  SizedBox(
                    height: 15,
                  ),
                  Wrap(
                    children: List.generate(intervals.length, (index) {
                      final interval = intervals[index];
                      return Container(
                        decoration: BoxDecoration(
                            color: currentIndex == index
                                ? colors.secondaryColor
                                : Colors.transparent),
                        child: InkWell(
                          onTap: () {
                            setState(() {
                              currentIndex = index;
                            });
                            loadData(intervals[currentIndex]);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                vertical: 5, horizontal: 10),
                            decoration: BoxDecoration(),
                            child: Text(
                              "$interval D".toUpperCase(),
                              style: textTheme.bodyMedium?.copyWith(
                                  color: colors.textColor,
                                  fontSize: fontSizeOf(14),
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                  SizedBox(
                    height: 10,
                  ),
                  Divider(
                    color: colors.secondaryColor.withValues(alpha: 0.6),
                  ),
                  SizedBox(
                    height: 15,
                  ),
                  Align(
                    alignment: Alignment.center,
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                          color: colors.secondaryColor,
                          borderRadius: BorderRadius.circular(roundedOf(10))),
                      child: Column(
                        spacing: 7,
                        children: [
                          TrendDataRow(
                              colors: colors,
                              title: "Market Cap",
                              value: "\$${(data.marketCap ?? 0).numeral()}"),
                          TrendDataRow(
                              colors: colors,
                              title: "Circulation Supply",
                              value:
                                  "\$${(data.circulatingSupply ?? 0).numeral()}"),
                          TrendDataRow(
                              colors: colors,
                              title: "Total Supply",
                              value: "\$${(data.totalSupply ?? 0).numeral()}"),
                          TrendDataRow(
                              colors: colors,
                              title: "Price Change 24H",
                              value: formatter.formatUsd(
                                  value: (data.priceChange24h ?? 0)))
                        ],
                      ),
                    ),
                  ),
                  SizedBox(
                    height: 10,
                  ),
                  if (!coin.isNative)
                    if (coin.network != null)
                      Align(
                        alignment: Alignment.center,
                        child: ListTile(
                          visualDensity:
                              VisualDensity(vertical: -2, horizontal: -4),
                          shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(roundedOf(10))),
                          tileColor: colors.secondaryColor,
                          onTap: () async {
                            final baseUrl =
                                coin.network?.explorers?.firstOrNull;
                            if (baseUrl == null) {
                              notifyError("No explorer found", context);
                              return;
                            }
                            await launchUrl(Uri.parse(
                                "$baseUrl/address/${coin.contractAddress}"));
                          },
                          leading: CryptoPicture(
                              crypto: coin.network!,
                              size: imageSizeOf(20),
                              colors: colors),
                          title: Text(
                            "Contract Address",
                            style: textTheme.bodyMedium?.copyWith(
                              color: colors.textColor,
                              fontSize: fontSizeOf(14),
                            ),
                          ),
                          trailing: Text(
                            "${coin.contractAddress?.substring(0, 9)}...",
                            style: textTheme.bodyMedium?.copyWith(
                                fontSize: fontSizeOf(14),
                                fontWeight: FontWeight.bold,
                                color: colors.textColor),
                          ),
                        ),
                      ),
                  SizedBox(
                    height: 15,
                  ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "Other",
                      style: textTheme.bodyMedium?.copyWith(
                          fontSize: fontSizeOf(14),
                          fontWeight: FontWeight.bold,
                          color: colors.textColor),
                    ),
                  ),
                  SizedBox(
                    height: 5,
                  ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "Explorers",
                      style: textTheme.bodyMedium?.copyWith(
                          fontSize: fontSizeOf(14), color: colors.textColor),
                    ),
                  ),
                  SizedBox(
                    height: 15,
                  ),
                  if (explorers != null)
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: List.generate(explorers.length, (index) {
                          final explorer = explorers[index];
                          return SizedBox(
                            width: 180,
                            child: GestureDetector(
                              onTap: () {
                                final baseUrl = Uri.parse(explorer);
                                launchUrl(baseUrl);
                              },
                              child: Chip(
                                  shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(roundedOf(30))),
                                  backgroundColor: colors.primaryColor,
                                  avatar: Icon(
                                    Icons.link,
                                    color: colors.textColor,
                                  ),
                                  label: Text(
                                    explorer,
                                    style: textTheme.bodyMedium?.copyWith(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: colors.textColor),
                                  )),
                            ),
                          );
                        }),
                      ),
                    )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}

class TrendDataRow extends StatelessWidget {
  final String title;
  final String value;
  final AppColors colors;
  const TrendDataRow(
      {super.key,
      required this.colors,
      required this.title,
      required this.value});

  @override
  Widget build(BuildContext context) {
    final textTheme = TextTheme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: textTheme.bodyMedium
              ?.copyWith(fontSize: 14, color: colors.textColor),
        ),
        Text(
          value,
          style: textTheme.bodyMedium?.copyWith(
              fontSize: 14,
              color: colors.textColor,
              fontWeight: FontWeight.bold),
        )
      ],
    );
  }
}
