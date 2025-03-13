import 'package:flutter/material.dart';
import 'package:moonwallet/custom/candlesticks/lib/candlesticks.dart';
import 'package:moonwallet/custom/candlesticks/lib/src/constant/view_constants.dart';
import 'package:moonwallet/custom/candlesticks/lib/src/utils/helper_functions.dart';
import 'package:moonwallet/logger/logger.dart';
import 'package:moonwallet/types/types.dart';
import 'package:moonwallet/utils/colors.dart';

class PriceColumn extends StatefulWidget {
  const PriceColumn({
    Key? key,
    required this.low,
    required this.high,
    required this.priceScale,
    required this.width,
    required this.chartHeight,
    required this.lastCandle,
    required this.onScale,
    required this.additionalVerticalPadding,
  }) : super(key: key);

  final double low;
  final double high;
  final double priceScale;
  final double width;
  final double chartHeight;
  final Candle lastCandle;
  final double additionalVerticalPadding;
  final void Function(double) onScale;

  @override
  State<PriceColumn> createState() => _PriceColumnState();
}

class _PriceColumnState extends State<PriceColumn> {
  ScrollController scrollController = new ScrollController();
  AppColors colors = AppColors(
      primaryColor: Color(0XFF0D0D0D),
      themeColor: Colors.greenAccent,
      greenColor: Colors.greenAccent,
      secondaryColor: Color(0XFF121212),
      grayColor: Color(0XFF353535),
      textColor: Colors.white,
      redColor: Colors.pinkAccent);

  double calcutePriceIndicatorTopPadding(
      double chartHeight, double low, double high) {
    return chartHeight +
        10 -
        (widget.lastCandle.close - low) / (high - low) * chartHeight;
  }

  Future<void> getSavedTheme() async {
    try {
      final manager = ColorsManager();
      final savedTheme = await manager.getDefaultTheme();
      setState(() {
        colors = savedTheme;
      });
    } catch (e) {
      logError(e.toString());
    }
  }

  @override
  void initState() {
    super.initState();
    getSavedTheme();
  }

  @override
  Widget build(BuildContext context) {
    final double priceTileHeight =
        widget.chartHeight / ((widget.high - widget.low) / widget.priceScale);
    return GestureDetector(
      onVerticalDragUpdate: (details) {
        widget.onScale(details.delta.dy);
      },
      child: AbsorbPointer(
        child: Padding(
          padding:
              EdgeInsets.symmetric(vertical: widget.additionalVerticalPadding),
          child: Stack(
            children: [
              AnimatedPositioned(
                duration: Duration(milliseconds: 300),
                top: MAIN_CHART_VERTICAL_PADDING - priceTileHeight / 2,
                height: widget.chartHeight +
                    MAIN_CHART_VERTICAL_PADDING +
                    priceTileHeight / 2,
                width: widget.width,
                child: ListView(
                  controller: scrollController,
                  children: List<Widget>.generate(20, (i) {
                    return AnimatedContainer(
                      duration: Duration(milliseconds: 300),
                      height: priceTileHeight,
                      width: double.infinity,
                      child: Center(
                        child: Row(
                          children: [
                            Container(
                              width: widget.width - PRICE_BAR_WIDTH,
                              height: 0.05,
                              color: colors.grayColor,
                            ),
                            Expanded(
                              child: Text(
                                "${HelperFunctions.priceToString(widget.high - widget.priceScale * i)}",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: colors.grayColor.withOpacity(0.8),
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              AnimatedPositioned(
                duration: Duration(milliseconds: 300),
                right: 0,
                top: calcutePriceIndicatorTopPadding(
                  widget.chartHeight,
                  widget.low,
                  widget.high,
                ),
                child: Row(
                  children: [
                    Container(
                      color: widget.lastCandle.isBull
                          ? colors.greenColor
                          : colors.redColor,
                      child: Center(
                        child: Text(
                          HelperFunctions.priceToString(
                              widget.lastCandle.close),
                          style: TextStyle(
                            color: colors.themeColor.withGreen(700),
                            fontSize: 11,
                          ),
                        ),
                      ),
                      width: PRICE_BAR_WIDTH,
                      height: PRICE_INDICATOR_HEIGHT,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
