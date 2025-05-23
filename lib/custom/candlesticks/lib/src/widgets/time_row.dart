import 'package:flutter/material.dart';
import 'dart:math' as math;

import 'package:moonwallet/custom/candlesticks/lib/candlesticks.dart';
import 'package:moonwallet/custom/candlesticks/lib/src/constant/view_constants.dart';
import 'package:moonwallet/logger/logger.dart';
import 'package:moonwallet/types/types.dart';
import 'package:moonwallet/utils/colors.dart';

class TimeRow extends StatefulWidget {
  final List<Candle> candles;
  final double candleWidth;
  final double? indicatorX;
  final DateTime? indicatorTime;
  final int index;

  const TimeRow({
    Key? key,
    required this.candles,
    required this.candleWidth,
    this.indicatorX,
    required this.indicatorTime,
    required this.index,
  }) : super(key: key);

  @override
  State<TimeRow> createState() => _TimeRowState();
}

class _TimeRowState extends State<TimeRow> {
  final ScrollController _scrollController = new ScrollController();
  AppColors colors = AppColors.defaultTheme;
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

  /// Calculates number of candles between two time indicator
  int _stepCalculator() {
    if (widget.candleWidth < 3)
      return 31;
    else if (widget.candleWidth < 5)
      return 19;
    else if (widget.candleWidth < 7)
      return 13;
    else
      return 9;
  }

  /// Calculates [DateTime] of a given candle index
  DateTime _timeCalculator(int step, int index, Duration dif) {
    int candleNumber = (step + 1) ~/ 2 - 10 + index * step + -1;
    DateTime? _time;
    if (candleNumber < 0)
      _time = widget.candles[step + candleNumber].date.add(dif);
    else if (candleNumber < widget.candles.length)
      _time = widget.candles[candleNumber].date;
    else {
      final stepsBack = (candleNumber - widget.candles.length) ~/ step + 1;
      final newIndex = candleNumber - stepsBack * step;
      _time = widget.candles[newIndex].date.subtract(dif * stepsBack);
    }
    return _time;
  }

  /// Fomats number as 2 digit integer
  String numberFormat(int value) {
    return "${value < 10 ? 0 : ""}$value";
  }

  /// Day/month text widget
  Text _monthDayText(DateTime _time, Color color) {
    return Text(
      numberFormat(_time.month) + "/" + numberFormat(_time.day),
      style: TextStyle(
        color: color,
        fontSize: 12,
      ),
    );
  }

  /// Hour/minute text widget
  Text _hourMinuteText(DateTime _time, Color color) {
    return Text(
      numberFormat(_time.hour) + ":" + numberFormat(_time.minute),
      style: TextStyle(
        color: color,
        fontSize: 12,
      ),
    );
  }

  String dateFormatter(DateTime date) {
    return "${date.year}-${numberFormat(date.month)}-${numberFormat(date.day)} ${numberFormat(date.hour)}:${numberFormat(date.minute)}";
  }

  @override
  void didUpdateWidget(TimeRow oldWidget) {
    if (oldWidget.index != widget.index ||
        oldWidget.candleWidth != widget.candleWidth)
      _scrollController.jumpTo((widget.index + 10) * widget.candleWidth);
    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    int step = _stepCalculator();
    final dif = widget.candles[0].date.difference(widget.candles[step].date);
    return Padding(
      padding: const EdgeInsets.only(right: PRICE_BAR_WIDTH + 1.0),
      child: Stack(
        children: [
          ListView.builder(
            physics: NeverScrollableScrollPhysics(),
            itemCount: widget.candles.length,
            scrollDirection: Axis.horizontal,
            itemExtent: step * widget.candleWidth,
            controller: _scrollController,
            reverse: true,
            itemBuilder: (context, index) {
              DateTime _time = _timeCalculator(step, index, dif);
              return Column(
                mainAxisSize: MainAxisSize.max,
                children: [
                  Expanded(
                    child: Container(
                      width: 0.05,
                      color: colors.grayColor,
                    ),
                  ),
                  dif.compareTo(Duration(days: 1)) > 0
                      ? _monthDayText(_time, colors.secondaryColor)
                      : _hourMinuteText(_time, colors.secondaryColor),
                ],
              );
            },
          ),
          widget.indicatorX == null
              ? Container()
              : Positioned(
                  bottom: 0,
                  left: math.max(widget.indicatorX! - 55, 0),
                  child: Container(
                    color: colors.grayColor,
                    child: Center(
                      child: Text(
                        dateFormatter(widget.indicatorTime!),
                        style: TextStyle(
                          color: colors.textColor,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    width: 110,
                    height: 20,
                  ),
                ),
        ],
      ),
    );
  }
}
