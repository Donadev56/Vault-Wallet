import 'package:currency_formatter/currency_formatter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:flutter_web3_webview/flutter_web3_webview.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:moonwallet/logger/logger.dart';
import 'package:moonwallet/types/types.dart';

Future<UserRequestResponse> askUserForConfirmation(
    {Crypto? crypto,
    required JsTransactionObject txData,
    required BuildContext context,
    required Color textColor,
    required Color primaryColor,
    required Color actionsColor,
    required Color secondaryColor,
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

  CurrencyFormat formatterSettings = CurrencyFormat(
  symbol: crypto?.symbol ?? "",
  symbolSide: SymbolSide.right,
  thousandSeparator: ',',
  decimalSeparator: '.',
  symbolSeparator: ' ',
);

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
  final valueInWei = BigInt.parse(txData.value!.replaceFirst("0x", ""), radix: 16);
  final double tokenAmount = double.parse(valueInWei.toString()) / 1e18;
  String formatted = CurrencyFormatter.format(tokenAmount, formatterSettings, decimal: 8);

  formatted = formatted.replaceAll(RegExp(r'(\.\d*?[1-9])0+$'), r'$1'); 
  formatted = formatted.replaceAll(RegExp(r'\.0+$'), ''); 

  return formatted;
}
  final result = await showModalBottomSheet<UserRequestResponse>(
    context: context,
    isScrollControlled: true,
    enableDrag: false,
    builder: (BuildContext confirmationCtx) {
      final width = MediaQuery.of(confirmationCtx).size.width;
      final height = MediaQuery.of(confirmationCtx).size.height;
      return StatefulBuilder(
        builder: (BuildContext ctx, StateSetter setModalState) {
          return Container(
            height: height * 0.9,
            decoration: BoxDecoration(
              color: primaryColor,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(15),
                topRight: Radius.circular(15),
              ),
            ),
            child: Column(
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
                                    color: textColor,
                                  ),
                                  SizedBox(
                                    width: width * 0.6,
                                    child: Text(
                                      "Smart Contract Call",
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.roboto(
                                          color: textColor,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 22),
                                    ),
                                  )
                                ],
                              )
                            : Text(
                                "Transfer",
                                style: GoogleFonts.roboto(
                                    color: textColor,
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
                      color: actionsColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Align(
                      alignment: Alignment.center,
                      child: Text(
                        txData.value != null
                            ? "${getValue ()} "
                            : "0  ${crypto != null ? crypto.symbol : ""}",
                        overflow: TextOverflow.clip,
                        maxLines: 1,
                        style: GoogleFonts.roboto(
                            color: textColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 20),
                      ),
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.center,
                  child: operationType == 0
                      ? Text(
                          "This is a third-party app. Please check the info.",
                          style: GoogleFonts.roboto(
                              color: Colors.orange, fontSize: 12),
                        )
                      : null,
                ),
                SizedBox(height: 10),
                Container(
                  margin: const EdgeInsets.all(10),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: actionsColor),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          operationType == 0
                              ? Text(
                                  "My Wallet",
                                  style: GoogleFonts.roboto(
                                      color: textColor, fontSize: 14),
                                )
                              : Text(
                                  "From ",
                                  style: GoogleFonts.roboto(
                                      color: textColor, fontSize: 14),
                                ),
                          Text(
                            currentAccount?.address != null
                                ? "${currentAccount!.address.substring(0, 6)}...${currentAccount.address.substring(currentAccount.address.length - 6)}"
                                : "",
                            style: GoogleFonts.roboto(
                                color: textColor, fontSize: 14),
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
                                  style: GoogleFonts.roboto(
                                      color: textColor, fontSize: 14),
                                )
                              : Text(
                                  "To",
                                  style: GoogleFonts.roboto(
                                      color: textColor, fontSize: 14),
                                ),
                          Text(
                            txData.to != null
                                ? "${txData.to!.substring(0, 6)}...${txData.to!.substring(txData.to!.length - 6)}"
                                : "",
                            style: GoogleFonts.roboto(
                                color: textColor, fontSize: 14),
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
                      color: actionsColor),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Data :",
                        style:
                            GoogleFonts.roboto(color: textColor, fontSize: 14),
                      ),
                      SizedBox(height: 5),
                      SizedBox(
                        height: 55,
                        width: width,
                        child: SingleChildScrollView(
                          child: Text(
                            txData.data ?? "",
                            style: GoogleFonts.roboto(
                                color: textColor, fontSize: 14),
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
                            showModalBottomSheet(
                              isScrollControlled: true,
                              context: context,
                              builder: (BuildContext editCtx) {
                                return Container(
                                  height: height * 0.95,
                                  padding: const EdgeInsets.all(10),
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: primaryColor,
                                  ),
                                  child: Column(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(10),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              "Customize gas",
                                              style: GoogleFonts.roboto(
                                                  color: textColor,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 22),
                                            ),
                                            IconButton(
                                              icon: Icon(
                                                FeatherIcons.xCircle,
                                                color: Colors.pinkAccent,
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
                                                BigInt.from(int.parse(value));
                                            log("New custom gas limit $customGasLimit ");
                                          });
                                        },
                                        keyboardType: TextInputType.number,
                                        style: GoogleFonts.roboto(
                                            color: textColor),
                                        decoration: InputDecoration(
                                          enabledBorder: OutlineInputBorder(
                                            borderSide: BorderSide(
                                                width: 1,
                                                color:
                                                    textColor.withOpacity(0.1)),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderSide: BorderSide(
                                                width: 1,
                                                color: secondaryColor
                                                    .withOpacity(0.1)),
                                          ),
                                          labelText: "Gas Limit",
                                          border: InputBorder.none,
                                          suffixText: "Gwei",
                                        ),
                                      ),
                                      SizedBox(height: 20),
                                      TextField(
                                        style: GoogleFonts.roboto(
                                            color: textColor),
                                        keyboardType: TextInputType.number,
                                        onChanged: (value) {
                                          setModalState(() {
                                            customGasPrice =
                                                BigInt.from(int.parse(value));
                                            log("New custom gas price $customGasPrice ");
                                          });
                                        },
                                        decoration: InputDecoration(
                                          enabledBorder: OutlineInputBorder(
                                            borderSide: BorderSide(
                                                width: 1,
                                                color:
                                                    textColor.withOpacity(0.1)),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderSide: BorderSide(
                                                width: 1,
                                                color: secondaryColor
                                                    .withOpacity(0.1)),
                                          ),
                                          labelText: "Gas Price",
                                          border: InputBorder.none,
                                          suffixText: "Gwei",
                                        ),
                                      ),
                                      SizedBox(height: 20, width: width * 0.8),
                                      Container(
                                        width: width,
                                        decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(10),
                                          color: textColor,
                                        ),
                                        child: Material(
                                          color: Colors.transparent,
                                          child: InkWell(
                                            borderRadius:
                                                BorderRadius.circular(10),
                                            onTap: () {
                                              setModalState(() {
                                                canUseCustomGas = true;
                                              });
                                              Navigator.pop(editCtx);
                                            },
                                            child: Container(
                                              padding: const EdgeInsets.all(10),
                                              child: Center(
                                                child: Text(
                                                  "Confirm",
                                                  style: GoogleFonts.roboto(
                                                    color: primaryColor,
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 16,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
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
                            width: width / 4.5,
                            height: 70,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  "${gas["name"]}",
                                  style: GoogleFonts.roboto(
                                      color: textColor, fontSize: 12),
                                ),
                                SizedBox(height: 2),
                                Icon(Icons.edit, color: textColor),
                                SizedBox(height: 2),
                              ],
                            ),
                          ),
                        );
                      }
                      return Container(
                        child: Material(
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
                                    width: 0.5,
                                    color: selected && !canUseCustomGas
                                        ? Colors.greenAccent
                                        : Colors.grey.withOpacity(0.3)),
                              ),
                              width: width / 4.5,
                              height: 70,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    "${gas["name"]}",
                                    style: GoogleFonts.roboto(
                                        color: textColor, fontSize: 12),
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    "\$ ${calculatePrice(gas["wei"]).toStringAsFixed(4)}",
                                    style: GoogleFonts.roboto(
                                        color: textColor, fontSize: 12),
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    "${(gas["gwei"] as BigInt).toString()} GWEI",
                                    style: GoogleFonts.roboto(
                                        color: textColor, fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
                Spacer(),
                Container(
                  width: width,
                  margin:
                      const EdgeInsets.only(bottom: 20, left: 10, right: 10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(30),
                    color: textColor,
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
                            style: GoogleFonts.roboto(
                              color: primaryColor,
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
