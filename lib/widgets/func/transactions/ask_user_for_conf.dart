// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:moonwallet/logger/logger.dart';
import 'package:moonwallet/types/types.dart';
import 'package:moonwallet/utils/number_formatter.dart';
import 'package:moonwallet/widgets/func/transactions/transaction_container.dart';

Future<UserRequestResponse> askUserForConfirmation({
  Crypto? crypto,
  required TransactionToConfirm txData,
  required BuildContext context,
  required AppColors colors,
}) async {
  try {
    int currentIndex = 1;
    BigInt customGasPrice = BigInt.zero;
    BigInt customGasLimit = BigInt.zero;
    bool canUseCustomGas = false;

    final BigInt baseCost =
        ((txData.gasBigint ?? BigInt.from(21000)) * txData.gasPrice);

    final BigInt rcmdCost =
        (baseCost * BigInt.from(130)) ~/ BigInt.from(100); // 1.3x
    final BigInt highCost =
        (baseCost * BigInt.from(150)) ~/ BigInt.from(100); // 1.5x

    final List<Map<String, dynamic>> gasData = [
      {
        "name": "Low",
        "wei": baseCost,
      },
      {
        "name": "Rcmd",
        "wei": rcmdCost,
      },
      {
        "name": "High",
        "wei": highCost,
      },
      {
        "name": "Custom",
        "wei": BigInt.zero,
        "gwei": BigInt.zero,
      },
    ];

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
                          child: Text(
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
                    child: TransactionContainer(
                      colors: colors,
                      child: Align(
                          alignment: Alignment.center,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            spacing: 5,
                            children: [
                              Text(
                                NumberFormatter().formatCrypto(
                                    value: txData.valueEth.toString()),
                                overflow: TextOverflow.clip,
                                maxLines: 1,
                                style: textTheme.bodyMedium?.copyWith(
                                    color: colors.textColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 25),
                              ),
                              Text(
                                crypto != null
                                    ? crypto.symbol.toUpperCase()
                                    : "",
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
                  SizedBox(height: 10),
                  TransactionContainer(
                    colors: colors,
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "From ",
                              style: textTheme.bodyMedium?.copyWith(
                                  color: colors.textColor, fontSize: 14),
                            ),
                            Text(
                              "${txData.account.address.substring(0, 6)}...${txData.account.address.substring(txData.account.address.length - 6)}",
                              style: textTheme.bodyMedium?.copyWith(
                                  color: colors.textColor, fontSize: 14),
                            ),
                          ],
                        ),
                        SizedBox(height: 13),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "To",
                              style: textTheme.bodyMedium?.copyWith(
                                  color: colors.textColor, fontSize: 14),
                            ),
                            Text(
                              "${txData.addressTo.substring(0, 6)}...${txData.addressTo.substring(txData.addressTo.length - 6)}",
                              style: textTheme.bodyMedium?.copyWith(
                                  color: colors.textColor, fontSize: 14),
                            ),
                          ],
                        )
                      ],
                    ),
                  ),
                  TransactionContainer(
                    colors: colors,
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
                                                          Navigator.pop(
                                                              editCtx);
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
                                                          color: colors
                                                              .textColor
                                                              .withOpacity(
                                                                  0.1)),
                                                    ),
                                                    focusedBorder:
                                                        OutlineInputBorder(
                                                      borderSide: BorderSide(
                                                          width: 1,
                                                          color: colors
                                                              .primaryColor
                                                              .withOpacity(
                                                                  0.1)),
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
                                                          color: colors
                                                              .textColor
                                                              .withOpacity(
                                                                  0.1)),
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
                                                        BorderRadius.circular(
                                                            10),
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
                                                          canUseCustomGas =
                                                              true;
                                                        });
                                                        Navigator.pop(editCtx);
                                                      },
                                                      child: Container(
                                                        padding:
                                                            const EdgeInsets
                                                                .all(10),
                                                        child: Center(
                                                          child: Text(
                                                            "Confirm",
                                                            style: textTheme
                                                                .bodyMedium
                                                                ?.copyWith(
                                                              color: colors
                                                                  .primaryColor,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
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
                                    "\$ ${(txData.cryptoPrice * ((gas["wei"] as BigInt) / BigInt.from(10).pow(txData.crypto.decimals))).toStringAsFixed(4)}",
                                    style: textTheme.bodyMedium?.copyWith(
                                        color: colors.textColor, fontSize: 10),
                                  ),
                                  SizedBox(height: 2),
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
                                  gasLimit:
                                      (customGasLimit * BigInt.from(130)) ~/
                                          BigInt.from(100),
                                ));
                          } else {
                            Navigator.pop(
                                confirmationCtx,
                                UserRequestResponse(
                                  ok: true,
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

    return result ?? UserRequestResponse(ok: false);
  } catch (e) {
    logError(e.toString());
    return UserRequestResponse(ok: false);
  }
}
