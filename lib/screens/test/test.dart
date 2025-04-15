import 'dart:convert';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class LineChartSample12 extends StatefulWidget {
  const LineChartSample12({super.key});

  @override
  State<LineChartSample12> createState() => _LineChartSample12State();
}

class _LineChartSample12State extends State<LineChartSample12> {
  List<(DateTime, double)>? _bitcoinPriceHistory;
  late TransformationController _transformationController;
  bool _isPanEnabled = true;
  bool _isScaleEnabled = true;

  @override
  void initState() {
    _reloadData();
    _transformationController = TransformationController();
    super.initState();
  }

  void _reloadData() async {
    final dataStr = await rootBundle.loadString(
      'assets/data/btc_price.json',
    );
    final json = jsonDecode(dataStr) as Map<String, dynamic>;
    setState(() {
      _bitcoinPriceHistory = (json['prices'] as List).map((item) {
        final timestamp = item[0] as int;
        final price = item[1] as double;
        return (DateTime.fromMillisecondsSinceEpoch(timestamp), price);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Material(
        color: Color(0XFF212121),
        child: Column(
          spacing: 16,
          children: [
            AspectRatio(
              aspectRatio: 1.4,
              child: Padding(
                padding: const EdgeInsets.only(
                  top: 0.0,
                  right: 18.0,
                ),
                child: LineChart(
                  transformationConfig: FlTransformationConfig(
                    scaleAxis: FlScaleAxis.horizontal,
                    minScale: 1.0,
                    maxScale: 25.0,
                    panEnabled: _isPanEnabled,
                    scaleEnabled: _isScaleEnabled,
                    transformationController: _transformationController,
                  ),
                  LineChartData(
                    gridData: FlGridData(show: false),
                    lineBarsData: [
                      LineChartBarData(
                        spots: _bitcoinPriceHistory?.asMap().entries.map((e) {
                              final index = e.key;
                              final item = e.value;
                              final value = item.$2;
                              return FlSpot(index.toDouble(), value);
                            }).toList() ??
                            [],
                        dotData: const FlDotData(show: false),
                        color: AppChartColors.contentColorYellow,
                        barWidth: 1,
                        shadow: const Shadow(
                          color: AppChartColors.contentColorYellow,
                          blurRadius: 2,
                        ),
                        belowBarData: BarAreaData(
                          show: true,
                          gradient: LinearGradient(
                            colors: [
                              AppChartColors.contentColorYellow
                                  .withValues(alpha: 0.2),
                              AppChartColors.contentColorYellow
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
                      touchSpotThreshold: 5,
                      getTouchLineStart: (_, __) => -double.infinity,
                      getTouchLineEnd: (_, __) => double.infinity,
                      getTouchedSpotIndicator:
                          (LineChartBarData barData, List<int> spotIndexes) {
                        return spotIndexes.map((spotIndex) {
                          return TouchedSpotIndicatorData(
                            const FlLine(
                              color: AppChartColors.contentColorRed,
                              strokeWidth: 1.5,
                              dashArray: [8, 2],
                            ),
                            FlDotData(
                              show: true,
                              getDotPainter: (spot, percent, barData, index) {
                                return FlDotCirclePainter(
                                  radius: 6,
                                  color: AppChartColors.contentColorYellow,
                                  strokeWidth: 0,
                                  strokeColor:
                                      AppChartColors.contentColorYellow,
                                );
                              },
                            ),
                          );
                        }).toList();
                      },
                      touchTooltipData: LineTouchTooltipData(
                        getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
                          return touchedBarSpots.map((barSpot) {
                            final price = barSpot.y;
                            final date =
                                _bitcoinPriceHistory![barSpot.x.toInt()].$1;
                            return LineTooltipItem(
                              '',
                              const TextStyle(
                                color: AppChartColors.contentColorBlack,
                                fontWeight: FontWeight.bold,
                              ),
                              children: [
                                TextSpan(
                                  text:
                                      '${date.year}/${date.month}/${date.day}',
                                  style: TextStyle(
                                    color: AppChartColors.contentColorGreen,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                                TextSpan(
                                  text: '\n${AppUtils.getFormattedCurrency(
                                    context,
                                    price,
                                    noDecimals: true,
                                  )}',
                                  style: const TextStyle(
                                    color: AppChartColors.contentColorYellow,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            );
                          }).toList();
                        },
                        getTooltipColor: (LineBarSpot barSpot) =>
                            AppChartColors.contentColorBlack,
                      ),
                    ),
                    titlesData: FlTitlesData(
                      show: true,
                      rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
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
                ),
              ),
            ),
          ],
        ));
  }

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }
}

class AppChartColors {
  static const Color primary = contentColorCyan;
  static const Color menuBackground = Color(0xFF090912);
  static const Color itemsBackground = Color(0xFF1B2339);
  static const Color pageBackground = Color(0xFF282E45);
  static const Color mainTextColor1 = Colors.white;
  static const Color mainTextColor2 = Colors.white70;
  static const Color mainTextColor3 = Colors.white38;
  static const Color mainGridLineColor = Colors.white10;
  static const Color borderColor = Colors.white54;
  static const Color gridLinesColor = Color(0x11FFFFFF);

  static const Color contentColorBlack = Colors.black;
  static const Color contentColorWhite = Colors.white;
  static const Color contentColorBlue = Color(0xFF2196F3);
  static const Color contentColorYellow = Color(0xFFFFC300);
  static const Color contentColorOrange = Color(0xFFFF683B);
  static const Color contentColorGreen = Color(0xFF3BFF49);
  static const Color contentColorPurple = Color(0xFF6E1BFF);
  static const Color contentColorPink = Color(0xFFFF3AF2);
  static const Color contentColorRed = Color(0xFFE80054);
  static const Color contentColorCyan = Color(0xFF50E4FF);
}

class AppUtils {
  static String getFormattedCurrency(
    BuildContext context,
    double value, {
    bool noDecimals = true,
  }) {
    final germanFormat = NumberFormat.currency(
      symbol: '€',
      decimalDigits: noDecimals && value % 1 == 0 ? 0 : 2,
    );
    return germanFormat.format(value);
  }
}
