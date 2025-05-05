// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:moonwallet/logger/logger.dart';
import 'package:moonwallet/types/account_related_types.dart';
import 'package:moonwallet/types/types.dart';
import 'package:moonwallet/widgets/buttons/elevated.dart';
import 'package:moonwallet/widgets/func/transactions/evm/show_custom_gas_modal.dart';
import 'package:moonwallet/widgets/func/transactions/transactions_body/show_transaction_request.dart';
import 'package:moonwallet/widgets/func/transactions/transactions_body/transaction_app_bar.dart';
import 'package:moonwallet/widgets/func/transactions/transactions_body/transaction_destination_details.dart';
import 'package:moonwallet/widgets/func/transactions/transactions_body/transaction_parent_container.dart';
import 'package:moonwallet/widgets/func/transactions/transactions_body/transaction_token_details.dart';

Future<UserCustomGasRequestResponse?> askUserEvm({
  required Crypto crypto,
  required TransactionToConfirm txData,
  required BuildContext context,
  required AppColors colors,
}) async {
  try {
    int currentIndex = 1;
    bool canUseCustomGas = false;
    UserCustomGasRequestResponse gasConfig =
        UserCustomGasRequestResponse(ok: false);

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

    final result = await showTransactionRequest<UserCustomGasRequestResponse>(
      context: context,
      builder: (BuildContext confirmationCtx) {
        final textTheme = Theme.of(context).textTheme;
        final width = MediaQuery.of(confirmationCtx).size.width;
        return StatefulBuilder(
          builder: (BuildContext ctx, StateSetter setModalState) {
            return TransactionParentContainer(
              colors: colors,
              child: ListView(
                shrinkWrap: true,
                children: [
                  TransactionAppBar(
                      padding: const EdgeInsets.only(bottom: 10),
                      colors: colors,
                      title: "Transfer",
                      actions: [
                        IconButton(
                          onPressed: () {
                            Navigator.pop(
                              confirmationCtx,
                            );
                          },
                          icon: Icon(FeatherIcons.xCircle,
                              color: Colors.pinkAccent),
                        )
                      ]),
                  TransactionTokenDetails(
                      colors: colors, crypto: crypto, value: txData.valueEth),
                  SizedBox(
                    height: 10,
                  ),

                  TransactionDestinationDetails(
                      colors: colors,
                      crypto: crypto,
                      from: txData.account.evmAddress,
                      to: txData.addressTo),
                  SizedBox(
                    height: 15,
                  ),
                  // ethereum only widget
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
                            onTap: () async {
                              final customGas = await showCustomGasModal(
                                  context: context, colors: colors);
                              if (customGas != null) {
                                gasConfig = customGas;
                                setModalState(() {
                                  canUseCustomGas = true;
                                });
                              }
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
                              width: width / 5.3,
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
                              width: width / 5.3,
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
                  SizedBox(
                    height: 40,
                  ),

                  CustomElevatedButton(
                    colors: colors,
                    onPressed: () {
                      if (canUseCustomGas) {
                        Navigator.pop(context, gasConfig);
                      } else {
                        Navigator.pop(
                            context,
                            UserCustomGasRequestResponse(
                              ok: true,
                            ));
                      }
                    },
                    text: "Continue",
                  )
                ],
              ),
            );
          },
        );
      },
    );

    return result;
  } catch (e) {
    logError(e.toString());
    return null;
  }
}
