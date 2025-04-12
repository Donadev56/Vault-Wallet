import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:moonwallet/custom/candlesticks/lib/candlesticks.dart';
import 'package:moonwallet/service/price_manager.dart';
import 'package:moonwallet/types/types.dart';

import '../../logger/logger.dart';

void showCryptoCandleModal(
    {required BuildContext context,
    required AppColors colors,
    required Crypto currentCrypto}) {
  final priceManager = PriceManager();
  int currentIndex = 0;
  final intervals = [
    '1m',
    '15m',
    '30m',
    '1h',
    '12h',
    '1d',
    '1w',
    '1M',
  ];

  Future<List<Candle>> getCandleData(
      {int index = 0, required Crypto crypto}) async {
    try {
      log("getting crypto data");
      final result = await priceManager.getChartPriceDataUsingBinanceApi(
          crypto.binanceSymbol ?? "${crypto.symbol}USDT", intervals[index]);
      if (result.isNotEmpty) {
        return result;
      } else {
        logError("Crypto data is not available");
        return [];
      }
    } catch (e) {
      logError(e.toString());
      return [];
    }
  }

  showBarModalBottomSheet(
    backgroundColor: Colors.transparent,
    context: context,
    builder: (BuildContext chartCtx) {
      final height = MediaQuery.of(context).size.height;
      return StatefulBuilder(
        builder: (BuildContext context, StateSetter setModalState) {
          final textTheme = Theme.of(context).textTheme;
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
                        FutureBuilder(
                          future: priceManager.checkCryptoTrend(
                              currentCrypto.binanceSymbol ?? ""),
                          builder:
                              (BuildContext trendCtx, AsyncSnapshot result) {
                            if (result.hasData) {
                              final isPositive = result.data["percent"] != null
                                  ? result.data["percent"] > 0
                                  : false;
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "\$ ${result.data["price"]}",
                                    style: textTheme.bodyMedium?.copyWith(
                                      color: isPositive
                                          ? colors.greenColor
                                          : colors.redColor,
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    " ${(result.data["percent"] != null ? result.data["percent"] as double : 0).toStringAsFixed(5)}%",
                                    style: textTheme.bodyMedium?.copyWith(
                                      color: isPositive
                                          ? colors.greenColor
                                          : colors.redColor,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              );
                            } else if (result.hasError) {
                              return Text("Error fetching data");
                            } else {
                              return Text("Loading...");
                            }
                          },
                        ),
                        IconButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          icon: Icon(FeatherIcons.xCircle,
                              color: Colors.pinkAccent),
                        )
                      ],
                    ),
                  ),
                  FutureBuilder(
                      future: getCandleData(
                          crypto: currentCrypto, index: currentIndex),
                      builder: (ctx, result) {
                        if (result.hasData) {
                          return SizedBox(
                            height: height * 0.3,
                            child: Candlesticks(
                              candles: result.data ?? [],
                            ),
                          );
                        } else if (result.hasError) {
                          return SizedBox(
                            height: height * 0.3,
                            child: Text(
                              "Error fetching data",
                              style:
                                  textTheme.bodyMedium?.copyWith(color: Colors.pinkAccent),
                            ),
                          );
                        } else {
                          return SizedBox(
                              height: height * 0.3, child: Text("Loading..."));
                        }
                      }),
                  SizedBox(height: 15),
                  Wrap(
                    alignment: WrapAlignment.center,
                    children: List.generate(intervals.length, (index) {
                      return Padding(
                        padding: const EdgeInsets.all(5),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(15),
                            onTap: () async {
                              setModalState(() {
                                currentIndex = index;
                                log("currentIndex: $currentIndex ");
                              });
                            },
                            child: Container(
                              width: 35,
                              height: 35,
                              padding: const EdgeInsets.all(5),
                              decoration: BoxDecoration(
                                color: currentIndex == index
                                    ? colors.themeColor.withOpacity(0.3)
                                    : colors.themeColor,
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: Center(
                                child: Text(
                                  intervals[index],
                                  style: textTheme.bodyMedium?.copyWith(
                                      color: colors.primaryColor, fontSize: 10),
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
