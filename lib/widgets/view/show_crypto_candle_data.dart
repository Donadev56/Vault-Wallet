import 'dart:ui';
import 'package:decimal/decimal.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:moonwallet/service/external_data/price_manager.dart';
import 'package:moonwallet/types/account_related_types.dart';
import 'package:moonwallet/types/types.dart';
import 'package:moonwallet/widgets/charts_/line_chart.dart';
import 'package:moonwallet/widgets/flowting_modat.dart';

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
  showFloatingModalBottomSheet(
    barrierColor: const Color.fromARGB(185, 0, 0, 0),
    enableDrag: false,
    backgroundColor: Colors.transparent,
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
              });
            } catch (e) {
              logError(e.toString());
            }
          }

          Future<void> loadData(String interval) async {
            try {
              final data = await priceManager.getPriceDataUsingCg(
                  currentCrypto, interval);

              if (data == null) {
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
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                decoration: BoxDecoration(
                  color: colors.primaryColor,
                  borderRadius:
                      BorderRadius.all(Radius.circular(roundedOf(15))),
                ),
                child: ListView(shrinkWrap: true, children: [
                  Padding(
                    padding: const EdgeInsets.all(10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              !isPriceLoading ? "\$$price" : "...",
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
                  Align(
                    alignment: Alignment.center,
                    child: AspectRatio(
                      aspectRatio: 1.4,
                      child: Padding(
                          padding: const EdgeInsets.only(
                            top: 0.0,
                            right: 0.0,
                          ),
                          child: cryptoData == null
                              ? Center(
                                  child: CircularProgressIndicator(
                                    color: colors.themeColor,
                                  ),
                                )
                              : CustomLineChart(
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
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(8),
                            onTap: () async {
                              setModalState(() {
                                isPositive = true;
                                trend = initialTrend;

                                currentIndex = index;
                                loadData(intervals[currentIndex]);
                                log("currentIndex: $currentIndex ");
                              });
                            },
                            child: Container(
                              height: 35,
                              width: 45,
                              padding: const EdgeInsets.all(5),
                              decoration: BoxDecoration(
                                border: Border.all(
                                    width: currentIndex == index ? 2 : 0,
                                    color: currentIndex == index
                                        ? colors.themeColor
                                        : Colors.transparent),
                                color: currentIndex == index
                                    ? Colors.transparent
                                    : colors.themeColor,
                                borderRadius:
                                    BorderRadius.circular(roundedOf(8)),
                              ),
                              child: Center(
                                child: Text(
                                  "${intervals[index]} D",
                                  style: textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: currentIndex == index
                                          ? colors.themeColor
                                          : colors.primaryColor,
                                      fontSize: fontSizeOf(10)),
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ]),
              ));
        },
      );
    },
  );
}
