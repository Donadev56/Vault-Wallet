import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:moonwallet/custom/candlesticks/lib/candlesticks.dart';
import 'package:moonwallet/custom/candlesticks/lib/src/widgets/desktop_chart.dart';
import 'package:moonwallet/custom/candlesticks/lib/src/widgets/mobile_chart.dart';
import 'package:moonwallet/custom/candlesticks/lib/src/widgets/toolbar.dart';
import 'package:moonwallet/logger/logger.dart';
import 'package:moonwallet/types/types.dart';
import 'package:moonwallet/utils/colors.dart';
import 'models/candle.dart';
import 'dart:io' show Platform;

/// StatefulWidget that holds Chart's State (index of
/// current position and candles width).
class Candlesticks extends StatefulWidget {
  /// The arrangement of the array should be such that
  ///  the newest item is in position 0
  final List<Candle> candles;

  /// this callback calls when the last candle gets visible
  final Future<void> Function()? onLoadMoreCandles;

  /// list of buttons you what to add on top tool bar
  final List<ToolBarAction> actions;

  Candlesticks({
    Key? key,
    required this.candles,
    this.onLoadMoreCandles,
    this.actions = const [],
  }) : super(key: key);

  @override
  _CandlesticksState createState() => _CandlesticksState();
}

class _CandlesticksState extends State<Candlesticks> {
  /// index of the newest candle to be displayed
  /// changes when user scrolls along the chart
  int index = -10;
  double lastX = 0;
  int lastIndex = -10;

  /// candleWidth controls the width of the single candles.
  ///  range: [2...10]
  double candleWidth = 6;

  /// true when widget.onLoadMoreCandles is fetching new candles.
  bool isCallingLoadMore = false;

  AppColors colors = AppColors(
      primaryColor: Color(0XFF0D0D0D),
      themeColor: Colors.greenAccent,
      greenColor: Colors.greenAccent,
      secondaryColor: Color(0XFF121212),
      grayColor: Color(0XFF353535),
      textColor: Colors.white,
      redColor: Colors.pinkAccent);
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
    return Column(
      children: [
        ToolBar(
          colors: colors,
          onZoomInPressed: () {
            setState(() {
              candleWidth += 2;
              candleWidth = min(candleWidth, 16);
            });
          },
          onZoomOutPressed: () {
            setState(() {
              candleWidth -= 2;
              candleWidth = max(candleWidth, 4);
            });
          },
          children: widget.actions,
        ),
        if (widget.candles.length == 0)
          Expanded(
            child: Center(
              child: CircularProgressIndicator(
                color: colors.themeColor,
              ),
            ),
          )
        else
          Expanded(
            child: TweenAnimationBuilder(
              tween: Tween(begin: 6.toDouble(), end: candleWidth),
              duration: Duration(milliseconds: 120),
              builder: (_, double width, __) {
                if (kIsWeb ||
                    Platform.isMacOS ||
                    Platform.isWindows ||
                    Platform.isLinux) {
                  return DesktopChart(
                    onScaleUpdate: (double scale) {
                      scale = max(0.90, scale);
                      scale = min(1.1, scale);
                      setState(() {
                        candleWidth *= scale;
                        candleWidth = min(candleWidth, 16);
                        candleWidth = max(candleWidth, 4);
                      });
                    },
                    onPanEnd: () {
                      lastIndex = index;
                    },
                    onHorizontalDragUpdate: (double x) {
                      setState(() {
                        x = x - lastX;
                        index = lastIndex + x ~/ candleWidth;
                        index = max(index, -10);
                        index = min(index, widget.candles.length - 1);
                      });
                    },
                    onPanDown: (double value) {
                      lastX = value;
                      lastIndex = index;
                    },
                    onReachEnd: () {
                      if (isCallingLoadMore == false &&
                          widget.onLoadMoreCandles != null) {
                        isCallingLoadMore = true;
                        widget.onLoadMoreCandles!().then((_) {
                          isCallingLoadMore = false;
                        });
                      }
                    },
                    candleWidth: width,
                    candles: widget.candles,
                    index: index,
                  );
                } else {
                  return MobileChart(
                    onScaleUpdate: (double scale) {
                      scale = max(0.90, scale);
                      scale = min(1.1, scale);
                      setState(() {
                        candleWidth *= scale;
                        candleWidth = min(candleWidth, 16);
                        candleWidth = max(candleWidth, 4);
                      });
                    },
                    onPanEnd: () {
                      lastIndex = index;
                    },
                    onHorizontalDragUpdate: (double x) {
                      setState(() {
                        x = x - lastX;
                        index = lastIndex + x ~/ candleWidth;
                        index = max(index, -10);
                        index = min(index, widget.candles.length - 1);
                      });
                    },
                    onPanDown: (double value) {
                      lastX = value;
                      lastIndex = index;
                    },
                    onReachEnd: () {
                      if (isCallingLoadMore == false &&
                          widget.onLoadMoreCandles != null) {
                        isCallingLoadMore = true;
                        widget.onLoadMoreCandles!().then((_) {
                          isCallingLoadMore = false;
                        });
                      }
                    },
                    candleWidth: width,
                    candles: widget.candles,
                    index: index,
                  );
                }
              },
            ),
          ),
      ],
    );
  }
}
