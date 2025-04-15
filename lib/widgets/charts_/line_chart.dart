import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:moonwallet/types/types.dart';
import 'package:moonwallet/utils/app_utils.dart';

class CustomLineChart extends StatelessWidget {
  final bool isPositive ;
  final AppColors colors ;
  final String symbol ;
  final TransformationController? transformationController;
  final List<(DateTime, double)>? chartData ;
  final void Function(FlTouchEvent, LineTouchResponse?)? onTouchCallback;
  final bool enableToCallBack;
  final double touchSpotThreshold ;
  final double flLineStrokeWidth;
  final double minScale ;
  final double maxScale ;
  final double barWidth ;
  final Color shadowColor ;
  final double shadowRadius ;
  final double flDotCirclePainterRadius;
  final double tooltipRoundedRadius ;

  const CustomLineChart({super.key , this.symbol = "\$" , this.tooltipRoundedRadius = 2 , this.flDotCirclePainterRadius =6 , this.shadowRadius = 4 , this.shadowColor = Colors.transparent , this.barWidth = 2 ,  this.maxScale = 25 , this.minScale = 1 ,  this.flLineStrokeWidth = 1 , this.touchSpotThreshold = 5 , this.enableToCallBack = true,this.onTouchCallback , this.chartData , this.transformationController , required this.colors ,  required this.isPositive});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme ;
    return LineChart(
                                  transformationConfig: FlTransformationConfig(
                                    scaleAxis: FlScaleAxis.horizontal,
                                    minScale: minScale,
                                    maxScale: maxScale,
                                    transformationController:
                                        transformationController,
                                  ),
                                  LineChartData(
                                    borderData: FlBorderData(show: false),
                                    gridData: FlGridData(show: false),
                                    lineBarsData: [
                                      LineChartBarData(
                                        isCurved: true,
                                        spots: chartData
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
                                        barWidth: barWidth,
                                        shadow: Shadow(
                                          color: shadowColor,
                                          blurRadius: shadowRadius,
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
                                      touchCallback: onTouchCallback,
                                      enabled: enableToCallBack,
                                      touchSpotThreshold: touchSpotThreshold,
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
                                              strokeWidth: flLineStrokeWidth,
                                            ),
                                            FlDotData(
                                              show: true,
                                              getDotPainter: (spot, percent,
                                                  barData, index) {
                                                return FlDotCirclePainter(
                                                  radius: flDotCirclePainterRadius,
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
                                        tooltipRoundedRadius: tooltipRoundedRadius,
                                        getTooltipItems: (List<LineBarSpot>
                                            touchedBarSpots) {
                                          return touchedBarSpots.map((barSpot) {
                                            final price = barSpot.y;
                                            final date =
                                                chartData![barSpot.x.toInt()]
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
                                                    noDecimals: true, symbol : symbol
                                                    
                                                    
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
                                );
  }
}