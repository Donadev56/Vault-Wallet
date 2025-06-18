import 'dart:ui';
import 'package:decimal/decimal.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:moonwallet/service/external_data/price_manager.dart';
import 'package:moonwallet/types/account_related_types.dart';
import 'package:moonwallet/types/types.dart';
import 'package:moonwallet/utils/number_formatter.dart';
import 'package:moonwallet/widgets/charts_/line_chart.dart';
import 'package:moonwallet/widgets/dialogs/empy_list.dart';
import 'package:moonwallet/widgets/dialogs/show_standard_sheet.dart';
import 'package:moonwallet/widgets/dialogs/standard_container.dart';
import 'package:moonwallet/widgets/screen_widgets/trending/widgets.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../logger/logger.dart';

void showCryptoCandleModal(
    {required BuildContext context,
    required DoubleFactor roundedOf,
    required DoubleFactor fontSizeOf,
    required AppColors colors,
    required Crypto currentCrypto}) {
  final priceManager = PriceManager();
  int currentIndex = 0;
  final Offset offset = Offset(-500.0, 0.0);
  String price = "0.0";
  bool isPriceLoading = true;
  bool loadedData = false;
  double trend = 0.0;
  final double scale = 4.0;
  double initialTrend = 0;
  List<(DateTime, double)>? cryptoData;
  TransformationController transformationController =
      TransformationController();

  transformationController.value = Matrix4.identity()
    ..translate(offset.dx, offset.dy)
    ..scale(scale);

  final intervals = [
    '1',
    '14',
    '30',
    '90',
    '365',
  ];
  bool isPositive = true;
  bool hasRun = false;
  showStandardModalBottomSheet(
    rounded: 0,
    enableDarg: false,
    barrierColor: Colors.transparent,
    context: context,
    builder: (BuildContext chartCtx) {
      return StatefulBuilder(
        builder: (BuildContext context, StateSetter setModalState) {
          Future<void> checkCryptoTrend() async {
            try {
              log("Loading price");

              final percent =
                  await priceManager.getPriceChange24h(currentCrypto);

              final cryptoPrice =
                  await priceManager.getTokenPriceUsd(currentCrypto);

              setModalState(() {
                isPositive = double.parse(percent) > 0 ? true : false;
                price = cryptoPrice;
                trend = double.parse(percent);
                initialTrend = trend;
                isPriceLoading = false;
                loadedData = true;
              });
            } catch (e) {
              logError(e.toString());
              setModalState(() {
                loadedData = true;
              });
            }
          }

          Future<void> loadData(String interval) async {
            try {
              final data =
                  await priceManager.getTokenHistData(currentCrypto, interval);

              if (data.isEmpty) {
                logError("Data is Null");
                return;
              }
              setModalState(() {
                cryptoData = data.map((item) {
                  final timestamp = item[0] as int;
                  final price = item[1] as double;
                  return (
                    DateTime.fromMillisecondsSinceEpoch(timestamp),
                    price
                  );
                }).toList();
              });
            } catch (e) {
              logError(e.toString());
            }
          }

          final textTheme = Theme.of(context).textTheme;
          if (!hasRun) {
            hasRun = true;

            WidgetsBinding.instance.addPostFrameCallback((_) {
              checkCryptoTrend();
              loadData(intervals[0]);
            });
          }

          return BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 0, sigmaY: 0),
              child: StandardContainer(
                  backgroundColor: colors.primaryColor,
                  border: Border(
                      top: BorderSide(width: 1, color: colors.secondaryColor)),
                  rounded: 0,
                  child: Material(
                    color: Colors.transparent,
                    child: ListView(shrinkWrap: true, children: [
                      Padding(
                        padding: const EdgeInsets.all(0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  !isPriceLoading
                                      ? "\$${NumberFormatter().formatDecimal(price)}"
                                      : "...",
                                  style: textTheme.bodyMedium?.copyWith(
                                    color: isPositive
                                        ? colors.themeColor
                                        : colors.redColor,
                                    fontSize: fontSizeOf(22),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  !isPriceLoading
                                      ? " ${(trend).toStringAsFixed(5)}%"
                                      : "...",
                                  style: textTheme.bodyMedium?.copyWith(
                                    color: isPositive
                                        ? colors.themeColor
                                        : colors.redColor,
                                    fontSize: fontSizeOf(14),
                                  ),
                                ),
                              ],
                            ),
                            IconButton(
                              onPressed: () {
                                Navigator.pop(context);
                              },
                              icon: Icon(FeatherIcons.xCircle,
                                  color: colors.redColor),
                            )
                          ],
                        ),
                      ),
                      SizedBox(
                        height: 25,
                      ),
                      Align(
                        alignment: Alignment.center,
                        child: AspectRatio(
                          aspectRatio: 1.8,
                          child: Padding(
                              padding: const EdgeInsets.only(
                                top: 0.0,
                                right: 0.0,
                              ),
                              child: cryptoData == null
                                  ? loadedData
                                      ? Column(
                                          spacing: 20,
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            EmptyList("Price data not found",
                                                colors: colors),
                                            TextButton(
                                                onPressed: () {
                                                  final explorer = currentCrypto
                                                      .firstExplorer;
                                                  String id;
                                                  if (currentCrypto.isNative) {
                                                    id = "";
                                                  } else {
                                                    id =
                                                        "address/${currentCrypto.contractAddress}";
                                                  }
                                                  if (explorer == null) {
                                                    return;
                                                  }
                                                  final url = "$explorer/$id";
                                                  log("Url $url");
                                                  launchUrl(Uri.parse(url));
                                                },
                                                child: Text(
                                                  "Learn More",
                                                  style: textTheme.bodyMedium
                                                      ?.copyWith(
                                                          color:
                                                              colors.themeColor,
                                                          fontWeight:
                                                              FontWeight.w500),
                                                ))
                                          ],
                                        )
                                      : Center(
                                          child: CircularProgressIndicator(
                                            color: colors.themeColor,
                                          ),
                                        )
                                  : CustomLineChart(
                                      showGradient: false,
                                      colors: colors,
                                      isPositive: isPositive,
                                      chartData: cryptoData,
                                      transformationController:
                                          transformationController,
                                      onTouchCallback: (FlTouchEvent event,
                                          LineTouchResponse? response) {
                                        if (event is FlTapUpEvent ||
                                            event is FlPanUpdateEvent) {
                                          if (response == null) {
                                            trend = initialTrend;
                                            log("Response is null");
                                            return;
                                          }

                                          final touchedSpots =
                                              response.lineBarSpots;

                                          if (touchedSpots != null) {
                                            final touchedSpots =
                                                response.lineBarSpots!;

                                            if (touchedSpots.isNotEmpty) {
                                              final spot = touchedSpots.first;
                                              final x = spot.x;
                                              final y = spot.y;
                                              final currentPrice = price;
                                              final priceSince = double.parse(
                                                  y.toStringAsFixed(2));
                                              final newTrend = ((Decimal.parse(
                                                                  priceSince
                                                                      .toString()) -
                                                              Decimal.parse(
                                                                  currentPrice))
                                                          .toDouble() /
                                                      priceSince) *
                                                  100;
                                              setModalState(() {
                                                trend = newTrend;
                                                isPositive = newTrend > 0;
                                              });
                                              debugPrint(
                                                  "User touched at: x=$x, y=$y");
                                            }
                                          }
                                        }
                                      })),
                        ),
                      ),
                      SizedBox(height: 15),
                      Wrap(
                        alignment: WrapAlignment.center,
                        children: List.generate(intervals.length, (index) {
                          return Padding(
                            padding: const EdgeInsets.only(
                                left: 5, right: 5, top: 10, bottom: 15),
                            child: TrendingWidgets.buildIntervalChip(
                                "${intervals[index]} D".toUpperCase(),
                                colors: colors,
                                context: context, onTap: () async {
                              setModalState(() {
                                isPositive = true;
                                trend = initialTrend;

                                currentIndex = index;
                                loadData(intervals[currentIndex]);
                                log("currentIndex: $currentIndex ");
                              });
                            },
                                fontSizeOf: fontSizeOf,
                                isSelected: currentIndex == index),
                          );
                        }),
                      ),
                    ]),
                  )));
        },
      );
    },
  );
}
