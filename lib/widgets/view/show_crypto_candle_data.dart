import 'dart:ui';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:moonwallet/service/price_manager.dart';
import 'package:moonwallet/types/types.dart';
import 'package:moonwallet/utils/app_utils.dart';
import 'package:moonwallet/widgets/flowting_modat.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../../logger/logger.dart';

void showCryptoCandleModal(
    {required BuildContext context,
    required AppColors colors,
    required Crypto currentCrypto}) {
  final priceManager = PriceManager();
  int currentIndex = 0;
  final Offset offset = Offset(-500.0, 0.0);
  double price = 0.0;
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
              final data = await priceManager
                  .checkCryptoTrend(currentCrypto.binanceSymbol ?? "");

              final percent = data["percent"] ?? 0;
              final cryptoPrice = data["price"] ?? 0;

              setModalState(() {
                isPositive = percent > 0 ? true : false;
                price = cryptoPrice;
                trend = percent;
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
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(15),
                    topRight: Radius.circular(15),
                  ),
                ),
                child: ListView(shrinkWrap: true, children: [
                  Padding(
                    padding: const EdgeInsets.all(10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Skeletonizer(
                          containersColor: colors.secondaryColor,
                          enabled: isPriceLoading,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "\$$price",
                                style: textTheme.bodyMedium?.copyWith(
                                  color: isPositive
                                      ? colors.themeColor
                                      : colors.redColor,
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                " ${(trend).toStringAsFixed(5)}%",
                                style: textTheme.bodyMedium?.copyWith(
                                  color: isPositive
                                      ? colors.themeColor
                                      : colors.redColor,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
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
                              : LineChart(
                                  transformationConfig: FlTransformationConfig(
                                    scaleAxis: FlScaleAxis.horizontal,
                                    minScale: 1.0,
                                    maxScale: 25.0,
                                    transformationController:
                                        transformationController,
                                  ),
                                  LineChartData(
                                    borderData: FlBorderData(show: false),
                                    gridData: FlGridData(show: false),
                                    lineBarsData: [
                                      LineChartBarData(
                                        isCurved: true,
                                        spots: cryptoData
                                                ?.asMap()
                                                .entries
                                                .map((e) {
                                              final index = e.key;
                                              final item = e.value;
                                              final value = item.$2;

                                              return FlSpot(
                                                  index.toDouble(), value);
                                            }).toList() ??
                                            [],
                                        dotData: const FlDotData(show: false),
                                        color: isPositive
                                            ? colors.themeColor
                                            : colors.redColor,
                                        barWidth: 2,
                                        shadow: Shadow(
                                          color: Colors.transparent,
                                          blurRadius: 2,
                                        ),
                                        belowBarData: BarAreaData(
                                          show: true,
                                          gradient: LinearGradient(
                                            colors: [
                                              isPositive
                                                  ? colors.themeColor
                                                      .withValues(alpha: 0.2)
                                                  : colors.redColor
                                                      .withValues(alpha: 0.2),
                                              isPositive
                                                  ? colors.themeColor
                                                      .withValues(alpha: 0.0)
                                                  : colors.redColor
                                                      .withValues(alpha: 0.0),
                                            ],
                                            stops: const [0.5, 1.0],
                                            begin: Alignment.topCenter,
                                            end: Alignment.bottomCenter,
                                          ),
                                        ),
                                      ),
                                    ],
                                    lineTouchData: LineTouchData(
                                      handleBuiltInTouches: true,
                                      touchCallback: (FlTouchEvent event,
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
                                              final newTrend =
                                                  ((priceSince - currentPrice) /
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
                                      },
                                      enabled: true,
                                      touchSpotThreshold: 5,
                                      getTouchLineStart: (_, __) =>
                                          -double.infinity,
                                      getTouchLineEnd: (_, __) =>
                                          double.infinity,
                                      getTouchedSpotIndicator:
                                          (LineChartBarData barData,
                                              List<int> spotIndexes) {
                                        return spotIndexes.map((spotIndex) {
                                          return TouchedSpotIndicatorData(
                                            FlLine(
                                              color: !isPositive
                                                  ? colors.redColor
                                                  : colors.themeColor,
                                              strokeWidth: 1,
                                            ),
                                            FlDotData(
                                              show: true,
                                              getDotPainter: (spot, percent,
                                                  barData, index) {
                                                return FlDotCirclePainter(
                                                  radius: 6,
                                                  color: isPositive
                                                      ? colors.themeColor
                                                      : colors.redColor,
                                                  strokeWidth: 0,
                                                  strokeColor: isPositive
                                                      ? colors.themeColor
                                                      : colors.redColor,
                                                );
                                              },
                                            ),
                                          );
                                        }).toList();
                                      },
                                      touchTooltipData: LineTouchTooltipData(
                                        tooltipRoundedRadius: 2,
                                        getTooltipItems: (List<LineBarSpot>
                                            touchedBarSpots) {
                                          return touchedBarSpots.map((barSpot) {
                                            final price = barSpot.y;
                                            final date =
                                                cryptoData![barSpot.x.toInt()]
                                                    .$1;
                                            return LineTooltipItem(
                                              textAlign: TextAlign.left,
                                              '',
                                              textTheme.bodyMedium!.copyWith(
                                                color: colors.secondaryColor,
                                                fontWeight: FontWeight.bold,
                                              ),
                                              children: [
                                                TextSpan(
                                                  text:
                                                      '${date.year}-${date.month}-${date.day} ${date.hour}:${date.minute}',
                                                  style: textTheme.bodySmall
                                                      ?.copyWith(
                                                    color: colors.textColor,
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 9,
                                                  ),
                                                ),
                                                TextSpan(
                                                  text:
                                                      '\n${AppUtils.getFormattedCurrency(
                                                    context,
                                                    price,
                                                    noDecimals: true,
                                                  )}',
                                                  style: textTheme.bodyMedium
                                                      ?.copyWith(
                                                    color: isPositive
                                                        ? colors.themeColor
                                                        : colors.redColor,
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 11,
                                                  ),
                                                ),
                                              ],
                                            );
                                          }).toList();
                                        },
                                        getTooltipColor:
                                            (LineBarSpot barSpot) =>
                                                colors.secondaryColor,
                                      ),
                                    ),
                                    titlesData: FlTitlesData(
                                      show: true,
                                      rightTitles: const AxisTitles(
                                        sideTitles:
                                            SideTitles(showTitles: false),
                                      ),
                                      topTitles: const AxisTitles(
                                        sideTitles:
                                            SideTitles(showTitles: false),
                                      ),
                                      leftTitles: const AxisTitles(
                                        sideTitles: SideTitles(
                                          showTitles: false,
                                        ),
                                      ),
                                      bottomTitles: AxisTitles(
                                        sideTitles: SideTitles(
                                          showTitles: false,
                                        ),
                                      ),
                                    ),
                                  ),
                                  duration: Duration.zero,
                                )),
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
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Center(
                                child: Text(
                                  "${intervals[index]} D",
                                  style: textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: currentIndex == index
                                          ? colors.themeColor
                                          : colors.primaryColor,
                                      fontSize: 10),
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
