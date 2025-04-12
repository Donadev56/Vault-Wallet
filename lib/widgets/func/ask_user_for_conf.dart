// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:flutter_web3_webview/flutter_web3_webview.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:moonwallet/logger/logger.dart';
import 'package:moonwallet/service/number_formatter.dart';
import 'package:moonwallet/types/types.dart';

Future<UserRequestResponse> askUserForConfirmation(
    {Crypto? crypto,
    required JsTransactionObject txData,
    required BuildContext context,
    required AppColors colors,
    PublicData? currentAccount,
    required BigInt estimatedGas,
    required BigInt gasPrice,
    required BigInt gasLimit,
    required BigInt valueInWei,
    required double cryptoPrice,
    required int operationType}) async {
  int currentIndex = 1;
  BigInt customGasPrice = BigInt.zero;
  BigInt customGasLimit = BigInt.zero;
  bool canUseCustomGas = false;

  double calculatePrice(BigInt wei) {
    final double tokenAmount = double.parse(wei.toString()) / 1e18;
    final double price = tokenAmount * cryptoPrice;
    log("Conversion: $wei wei correspond to $tokenAmount token(s)  $price USD");
    return price;
  }

  final BigInt baseCost = (estimatedGas == BigInt.zero)
      ? gasLimit * gasPrice
      : estimatedGas * gasPrice;
  final BigInt rcmdCost =
      (baseCost * BigInt.from(130)) ~/ BigInt.from(100); // 1.3x
  final BigInt highCost =
      (baseCost * BigInt.from(150)) ~/ BigInt.from(100); // 1.5x

  final BigInt gasPriceGwei = gasPrice ~/ BigInt.from(10).pow(9);

  final List<Map<String, dynamic>> gasData = [
    {
      "name": "Low",
      "wei": baseCost,
      "gwei": gasPriceGwei,
    },
    {
      "name": "Rcmd",
      "wei": rcmdCost,
      "gwei": gasPriceGwei,
    },
    {
      "name": "High",
      "wei": highCost,
      "gwei": gasPriceGwei,
    },
    {
      "name": "Custom",
      "wei": BigInt.zero,
      "gwei": BigInt.zero,
    },
  ];
  String getValue() {
    final valueInWei =
        BigInt.parse(txData.value!.replaceFirst("0x", ""), radix: 16);
    final double tokenAmount = double.parse(valueInWei.toString()) / 1e18;

    return NumberFormatter().formatCrypto(value: tokenAmount.toString());
  }

  final result = await showBarModalBottomSheet<UserRequestResponse>(
    backgroundColor: Colors.transparent,
    context: context,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.only(
        topLeft: Radius.circular(30),
        topRight: Radius.circular(30),
      ),
    ),
    builder: (BuildContext confirmationCtx) {
      final textTheme = Theme.of(context).textTheme;
      final width = MediaQuery.of(confirmationCtx).size.width;
      return StatefulBuilder(
        builder: (BuildContext ctx, StateSetter setModalState) {
          return Container(
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              color: colors.primaryColor,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(30),
                topRight: Radius.circular(30),
              ),
            ),
            child: ListView(
              shrinkWrap: true,
              children: [
                Padding(
                  padding: const EdgeInsets.all(10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(10),
                        child: operationType == 0
                            ? Row(
                                spacing: 10,
                                children: [
                                  Icon(
                                    LucideIcons.fileText,
                                    color: colors.textColor,
                                  ),
                                  SizedBox(
                                    width: width * 0.6,
                                    child: Text(
                                      "Smart Contract Call",
                                      overflow: TextOverflow.ellipsis,
                                      style: textTheme.headlineMedium?.copyWith(
                                          color: colors.textColor,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 22),
                                    ),
                                  )
                                ],
                              )
                            : Text(
                                "Transfer",
                                style: textTheme.headlineMedium?.copyWith(
                                    color: colors.textColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 22),
                              ),
                      ),
                      IconButton(
                        onPressed: () {
                          Navigator.pop(
                            confirmationCtx,
                            UserRequestResponse(
                              ok: false,
                              gasPrice: gasPriceGwei,
                              gasLimit: estimatedGas,
                            ),
                          );
                        },
                        icon: Icon(FeatherIcons.xCircle,
                            color: Colors.pinkAccent),
                      )
                    ],
                  ),
                ),
                Align(
                  alignment: Alignment.topLeft,
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    margin: const EdgeInsets.all(10),
                    width: width,
                    decoration: BoxDecoration(
                      color: colors.secondaryColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Align(
                        alignment: Alignment.center,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              txData.value != null ? "${getValue()} " : "0 ",
                              overflow: TextOverflow.clip,
                              maxLines: 1,
                              style: textTheme.bodyMedium?.copyWith(
                                  color: colors.textColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 25),
                            ),
                            Text(
                              crypto != null ? crypto.symbol.toUpperCase() : "",
                              overflow: TextOverflow.clip,
                              maxLines: 1,
                              style: textTheme.bodyMedium?.copyWith(
                                  color: colors.textColor.withOpacity(0.5),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 25),
                            ),
                          ],
                        )),
                  ),
                ),
                Align(
                  alignment: Alignment.center,
                  child: operationType == 0
                      ? Text(
                          "This is a third-party app. Please check the info.",
                          style: textTheme.bodySmall?.copyWith(
                            color: Colors.orange,
                          ),
                        )
                      : null,
                ),
                SizedBox(height: 10),
                Container(
                  margin: const EdgeInsets.all(10),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: colors.secondaryColor,
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          operationType == 0
                              ? Text(
                                  "My Wallet",
                                  style: textTheme.bodyMedium?.copyWith(
                                      color: colors.textColor, fontSize: 14),
                                )
                              : Text(
                                  "From ",
                                  style: textTheme.bodyMedium?.copyWith(
                                      color: colors.textColor, fontSize: 14),
                                ),
                          Text(
                            currentAccount?.address != null
                                ? "${currentAccount!.address.substring(0, 6)}...${currentAccount.address.substring(currentAccount.address.length - 6)}"
                                : "",
                            style: textTheme.bodyMedium?.copyWith(
                                color: colors.textColor, fontSize: 14),
                          ),
                        ],
                      ),
                      SizedBox(height: 13),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          operationType == 0
                              ? Text(
                                  "Interact with",
                                  style: textTheme.bodyMedium?.copyWith(
                                      color: colors.textColor, fontSize: 14),
                                )
                              : Text(
                                  "To",
                                  style: textTheme.bodyMedium?.copyWith(
                                      color: colors.textColor, fontSize: 14),
                                ),
                          Text(
                            txData.to != null
                                ? "${txData.to!.substring(0, 6)}...${txData.to!.substring(txData.to!.length - 6)}"
                                : "",
                            style: textTheme.bodyMedium?.copyWith(
                                color: colors.textColor, fontSize: 14),
                          ),
                        ],
                      )
                    ],
                  ),
                ),
                Container(
                  margin: const EdgeInsets.only(left: 10, right: 10, top: 5),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: colors.secondaryColor,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Data :",
                        style: textTheme.bodyMedium
                            ?.copyWith(color: colors.textColor, fontSize: 14),
                      ),
                      SizedBox(height: 5),
                      SizedBox(
                        height: 55,
                        width: width,
                        child: SingleChildScrollView(
                          child: Text(
                            txData.data ?? "",
                            style: textTheme.bodyMedium?.copyWith(
                                color: colors.textColor, fontSize: 14),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  margin: const EdgeInsets.all(10),
                  child: Row(
                    spacing: 6,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(gasData.length, (index) {
                      final selected = currentIndex == index;
                      final gas = gasData[index];
                      if (index == 3) {
                        return InkWell(
                          onTap: () {
                            showCupertinoModalBottomSheet(
                              context: context,
                              builder: (BuildContext editCtx) {
                                return SafeArea(
                                  child: Material(
                                      color: Colors.transparent,
                                      child: Container(
                                          padding: const EdgeInsets.all(20),
                                          decoration: BoxDecoration(
                                            color: colors.primaryColor,
                                          ),
                                          child: ListView(
                                            children: [
                                              Container(
                                                padding:
                                                    const EdgeInsets.all(10),
                                                child: Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment
                                                          .spaceBetween,
                                                  children: [
                                                    Text(
                                                      "Customize gas",
                                                      style: textTheme
                                                          .headlineMedium
                                                          ?.copyWith(
                                                              color: colors
                                                                  .textColor,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                              fontSize: 22),
                                                    ),
                                                    IconButton(
                                                      icon: Icon(
                                                        FeatherIcons.xCircle,
                                                        color:
                                                            Colors.pinkAccent,
                                                      ),
                                                      onPressed: () {
                                                        Navigator.pop(editCtx);
                                                      },
                                                    )
                                                  ],
                                                ),
                                              ),
                                              TextField(
                                                onChanged: (value) {
                                                  setModalState(() {
                                                    customGasLimit =
                                                        BigInt.from(
                                                            int.parse(value));
                                                    log("New custom gas limit $customGasLimit ");
                                                  });
                                                },
                                                keyboardType:
                                                    TextInputType.number,
                                                style: textTheme.bodyMedium
                                                    ?.copyWith(
                                                        color:
                                                            colors.textColor),
                                                decoration: InputDecoration(
                                                  enabledBorder:
                                                      OutlineInputBorder(
                                                    borderSide: BorderSide(
                                                        width: 1,
                                                        color: colors.textColor
                                                            .withOpacity(0.1)),
                                                  ),
                                                  focusedBorder:
                                                      OutlineInputBorder(
                                                    borderSide: BorderSide(
                                                        width: 1,
                                                        color: colors
                                                            .primaryColor
                                                            .withOpacity(0.1)),
                                                  ),
                                                  labelText: "Gas Limit",
                                                  border: InputBorder.none,
                                                  suffixText: "Gwei",
                                                ),
                                              ),
                                              SizedBox(height: 20),
                                              TextField(
                                                style: textTheme.bodyMedium
                                                    ?.copyWith(
                                                        color:
                                                            colors.textColor),
                                                keyboardType:
                                                    TextInputType.number,
                                                onChanged: (value) {
                                                  setModalState(() {
                                                    customGasPrice =
                                                        BigInt.from(
                                                            int.parse(value));
                                                    log("New custom gas price $customGasPrice ");
                                                  });
                                                },
                                                decoration: InputDecoration(
                                                  enabledBorder:
                                                      OutlineInputBorder(
                                                    borderSide: BorderSide(
                                                        width: 1,
                                                        color: colors.textColor
                                                            .withOpacity(0.1)),
                                                  ),
                                                  focusedBorder:
                                                      OutlineInputBorder(
                                                    borderSide: BorderSide(
                                                        width: 1,
                                                        color: colors
                                                            .secondaryColor),
                                                  ),
                                                  labelText: "Gas Price",
                                                  border: InputBorder.none,
                                                  suffixText: "Gwei",
                                                ),
                                              ),
                                              SizedBox(
                                                  height: 20,
                                                  width: width * 0.8),
                                              Container(
                                                width: width,
                                                decoration: BoxDecoration(
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                  color: colors.themeColor,
                                                ),
                                                child: Material(
                                                  color: Colors.transparent,
                                                  child: InkWell(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            10),
                                                    onTap: () {
                                                      setModalState(() {
                                                        canUseCustomGas = true;
                                                      });
                                                      Navigator.pop(editCtx);
                                                    },
                                                    child: Container(
                                                      padding:
                                                          const EdgeInsets.all(
                                                              10),
                                                      child: Center(
                                                        child: Text(
                                                          "Confirm",
                                                          style: textTheme
                                                              .bodyMedium
                                                              ?.copyWith(
                                                            color: colors
                                                                .primaryColor,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            fontSize: 16,
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ))),
                                );
                              },
                            );
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                width: 0.5,
                                color: canUseCustomGas
                                    ? Colors.greenAccent
                                    : Colors.grey.withOpacity(0.3),
                              ),
                            ),
                            width: width / 5,
                            height: 70,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  "${gas["name"]}",
                                  style: textTheme.bodyMedium?.copyWith(
                                      color: colors.textColor, fontSize: 10),
                                ),
                                SizedBox(height: 2),
                                Icon(Icons.edit, color: colors.textColor),
                                SizedBox(height: 2),
                              ],
                            ),
                          ),
                        );
                      }
                      return Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(10),
                          onTap: () {
                            setModalState(() {
                              currentIndex = index;
                              if (canUseCustomGas) {
                                setModalState(() {
                                  canUseCustomGas = false;
                                });
                              }
                            });
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                  width: 0.8,
                                  color: selected && !canUseCustomGas
                                      ? colors.themeColor
                                      : Colors.grey.withOpacity(0.3)),
                            ),
                            width: width / 5,
                            height: 70,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  "${gas["name"]}",
                                  style: textTheme.bodyMedium?.copyWith(
                                      color: colors.textColor, fontSize: 10),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  "\$ ${calculatePrice(gas["wei"]).toStringAsFixed(4)}",
                                  style: textTheme.bodyMedium?.copyWith(
                                      color: colors.textColor, fontSize: 10),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  "${(gas["gwei"] as BigInt).toString()} GWEI",
                                  style: textTheme.bodyMedium?.copyWith(
                                      color: colors.textColor, fontSize: 10),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
                Container(
                  width: width,
                  margin:
                      const EdgeInsets.only(bottom: 20, left: 10, right: 10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: colors.themeColor,
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(30),
                      onTap: () {
                        if (canUseCustomGas) {
                          Navigator.pop(
                              confirmationCtx,
                              UserRequestResponse(
                                ok: true,
                                gasPrice: customGasPrice,
                                gasLimit: (customGasLimit * BigInt.from(130)) ~/
                                    BigInt.from(100),
                              ));
                        } else {
                          Navigator.pop(
                              confirmationCtx,
                              UserRequestResponse(
                                ok: true,
                                gasPrice: gasPrice,
                                gasLimit: (gasLimit * BigInt.from(130)) ~/
                                    BigInt.from(100),
                              ));
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        child: Center(
                          child: Text(
                            "Confirm",
                            style: textTheme.bodyMedium?.copyWith(
                              color: colors.primaryColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                )
              ],
            ),
          );
        },
      );
    },
  );

  return result ??
      UserRequestResponse(
          ok: false, gasPrice: gasPriceGwei, gasLimit: estimatedGas);
}
