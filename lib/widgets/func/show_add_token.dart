// ignore_for_file: deprecated_member_use

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:moonwallet/main.dart';
import 'package:moonwallet/service/crypto_storage_manager.dart';
import 'package:moonwallet/service/token_manager.dart';
import 'package:moonwallet/types/types.dart';
import 'package:moonwallet/utils/constant.dart';
import 'package:moonwallet/widgets/barre.dart';
import 'package:moonwallet/widgets/snackbar.dart';
import 'package:ulid/ulid.dart';

void showAddToken(
    {required BuildContext context,
    required AppColors colors,
    required double width,
    required List<Crypto> reorganizedCrypto,
    required PublicData currentAccount,
    required bool hasSaved}) {
  Crypto? selectedNetwork;
  TextEditingController _contractAddressController = TextEditingController();
  final tokenManager = TokenManager();
  final cryptoStorageManager = CryptoStorageManager();
  SearchingContractInfo? searchingContractInfo;
  showModalBottomSheet(
      isScrollControlled: true,
      backgroundColor: colors.primaryColor,
      context: context,
      builder: (ctx) {
        return StatefulBuilder(builder: (bCtx, setModalState) {
          String generateUUID() {
            return Ulid().toUuid();
          }

          return SizedBox(
              height: MediaQuery.of(context).size.height * 0.95,
              child: Scaffold(
                backgroundColor: colors.primaryColor,
                appBar: AppBar(
                  actions: [
                    IconButton(
                        onPressed: () async {
                          if (selectedNetwork == null) {
                            showCustomSnackBar(
                                colors: colors,
                                primaryColor: colors.primaryColor,
                                context: context,
                                message: 'Please select a network.',
                                iconColor: Colors.pinkAccent);
                          }
                          if (_contractAddressController.text.isEmpty) {
                            showCustomSnackBar(
                                colors: colors,
                                primaryColor: colors.primaryColor,
                                context: context,
                                message: 'Please enter a contract address.',
                                iconColor: Colors.pinkAccent);
                          }
                          final tokenFoundedData =
                              await tokenManager.getCryptoInfo(
                                  address:
                                      _contractAddressController.text.trim(),
                                  network: selectedNetwork ?? cryptos[0]);
                          setModalState(() {
                            searchingContractInfo = tokenFoundedData;
                          });
                          if (tokenFoundedData != null) {
                            showDialog(
                                context: context,
                                builder: (btx) {
                                  return BackdropFilter(
                                    filter:
                                        ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                                    child: AlertDialog(
                                      backgroundColor: colors.primaryColor,
                                      title: Text(
                                        "Confirmation",
                                        style: GoogleFonts.roboto(
                                            color: colors.textColor),
                                      ),
                                      content: Column(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(10),
                                            child: Row(
                                              spacing: 10,
                                              children: [
                                                Text(
                                                  "Name :",
                                                  style: GoogleFonts.roboto(
                                                      color: colors.textColor
                                                          .withOpacity(0.5)),
                                                ),
                                                Text(
                                                  "${tokenFoundedData.name}",
                                                  style: GoogleFonts.roboto(
                                                      color: colors.textColor
                                                          .withOpacity(0.8),
                                                      fontWeight:
                                                          FontWeight.bold),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.all(10),
                                            child: Row(
                                              spacing: 10,
                                              children: [
                                                Text(
                                                  "Symbol :",
                                                  style: GoogleFonts.roboto(
                                                      color: colors.textColor
                                                          .withOpacity(0.5)),
                                                ),
                                                Text(
                                                  "${tokenFoundedData.symbol}",
                                                  style: GoogleFonts.roboto(
                                                      color: colors.textColor
                                                          .withOpacity(0.8),
                                                      fontWeight:
                                                          FontWeight.bold),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.all(10),
                                            child: Row(
                                              spacing: 10,
                                              children: [
                                                Text(
                                                  "Decimals :",
                                                  style: GoogleFonts.roboto(
                                                      color: colors.textColor
                                                          .withOpacity(0.5)),
                                                ),
                                                Text(
                                                  "${tokenFoundedData.decimals}",
                                                  style: GoogleFonts.roboto(
                                                      color: colors.textColor
                                                          .withOpacity(0.8),
                                                      fontWeight:
                                                          FontWeight.bold),
                                                ),
                                              ],
                                            ),
                                          )
                                        ],
                                      ),
                                      actions: [
                                        TextButton(
                                          style: ElevatedButton.styleFrom(
                                              backgroundColor:
                                                  colors.textColor),
                                          child: Text(
                                            "Add Token",
                                            style: GoogleFonts.roboto(
                                                color: colors.primaryColor),
                                          ),
                                          onPressed: () async {
                                            final List<Crypto>? cryptos =
                                                await cryptoStorageManager
                                                    .getSavedCryptos(
                                                        wallet: currentAccount);
                                            if (cryptos != null) {
                                              for (final crypto in cryptos) {
                                                if (crypto.contractAddress !=
                                                        null &&
                                                    crypto.contractAddress
                                                            ?.trim()
                                                            .toLowerCase() ==
                                                        _contractAddressController
                                                            .text
                                                            .trim()
                                                            .toLowerCase()) {
                                                  showCustomSnackBar(
                                                      colors: colors,
                                                      primaryColor:
                                                          colors.primaryColor,
                                                      context: context,
                                                      message:
                                                          'Token already added.',
                                                      iconColor: Colors.orange);
                                                  Navigator.pop(context);
                                                  return;
                                                }
                                              }
                                            }

                                            final newCrypto = Crypto(
                                                symbol: searchingContractInfo
                                                        ?.symbol ??
                                                    "",
                                                name:
                                                    searchingContractInfo
                                                            ?.name ??
                                                        "Unknown ",
                                                color:
                                                    selectedNetwork
                                                            ?.color ??
                                                        Colors.white,
                                                type: CryptoType.token,
                                                valueUsd: 0,
                                                cryptoId: generateUUID(),
                                                canDisplay: true,
                                                network: selectedNetwork,
                                                decimals:
                                                    searchingContractInfo
                                                        ?.decimals
                                                        .toInt(),
                                                binanceSymbol:
                                                    "${searchingContractInfo?.symbol}USDT",
                                                contractAddress:
                                                    _contractAddressController
                                                        .text);
                                            final saveResult =
                                                await cryptoStorageManager
                                                    .addCrypto(
                                                        wallet: currentAccount,
                                                        crypto: newCrypto);
                                            if (saveResult) {
                                              hasSaved = true;
                                              showCustomSnackBar(
                                                  colors: colors,
                                                  primaryColor:
                                                      colors.primaryColor,
                                                  context: context,
                                                  icon: Icons.check,
                                                  message:
                                                      'Token added successfully.',
                                                  iconColor: Colors.green);
                                              Navigator.pop(context);
                                            } else {
                                              showCustomSnackBar(
                                                colors: colors,
                                                primaryColor:
                                                    colors.primaryColor,
                                                context: context,
                                                message: 'Error adding token.',
                                                iconColor: Colors.red,
                                              );
                                              Navigator.pop(context);
                                            }
                                          },
                                        ),
                                        TextButton(
                                          style: ElevatedButton.styleFrom(
                                              backgroundColor:
                                                  Colors.pinkAccent),
                                          child: Text(
                                            "Cancel",
                                            style: GoogleFonts.roboto(
                                                color: colors.textColor),
                                          ),
                                          onPressed: () {
                                            Navigator.pop(btx);
                                          },
                                        )
                                      ],
                                    ),
                                  );
                                });
                          } else {
                            showCustomSnackBar(
                                colors: colors,
                                primaryColor: colors.primaryColor,
                                context: context,
                                message: 'Token not found.',
                                iconColor: Colors.pinkAccent);
                          }
                        },
                        icon: Icon(
                          Icons.check,
                          color: colors.textColor.withOpacity(0.5),
                        ))
                  ],
                  backgroundColor: colors.primaryColor,
                  leading: IconButton(
                      onPressed: () {
                        if (hasSaved) {
                          Navigator.pushNamed(context, Routes.pageManager);
                        } else {
                          Navigator.pop(context);
                        }
                      },
                      icon: Icon(
                        LucideIcons.chevronLeft,
                        color: colors.textColor.withOpacity(0.5),
                      )),
                ),
                body: SingleChildScrollView(
                  child: Column(
                    spacing: 10,
                    children: [
                      ListTile(
                        onTap: () {
                          showModalBottomSheet(
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.only(
                                      topLeft: Radius.circular(30),
                                      topRight: Radius.circular(30))),
                              backgroundColor: colors.primaryColor,
                              context: context,
                              builder: (ctx) {
                                return SingleChildScrollView(
                                    child: Column(
                                        children: List.generate(
                                            reorganizedCrypto
                                                    .where((crypto) =>
                                                        crypto.type ==
                                                        CryptoType.network)
                                                    .length +
                                                1, (index) {
                                  if (index == 0) {
                                    return DraggableBar(colors: colors);
                                  }

                                  final crypto = reorganizedCrypto
                                      .where((crypto) =>
                                          crypto.type == CryptoType.network)
                                      .toList()[index - 1];
                                  return ListTile(
                                    leading: ClipRRect(
                                      borderRadius: BorderRadius.circular(50),
                                      child: Image.asset(
                                        crypto.icon ?? "",
                                        fit: BoxFit.cover,
                                        width: 30,
                                        height: 30,
                                      ),
                                    ),
                                    title: Text(crypto.name,
                                        style: GoogleFonts.roboto(
                                            color: colors.textColor)),
                                    onTap: () {
                                      setModalState(() {
                                        selectedNetwork = crypto;
                                      });
                                      Navigator.pop(context);
                                    },
                                    trailing: Icon(
                                      LucideIcons.chevronRight,
                                      color: colors.textColor,
                                    ),
                                  );
                                })));
                              });
                        },
                        title: Text(
                          "${selectedNetwork != null ? selectedNetwork?.name : "Select an network"}",
                          style: GoogleFonts.roboto(
                              color: colors.textColor.withOpacity(0.5)),
                        ),
                        trailing: Icon(
                          LucideIcons.chevronRight,
                          color: colors.textColor,
                        ),
                      ),
                      SizedBox(
                        width: width * 0.92,
                        child: TextField(
                          style: GoogleFonts.roboto(color: colors.textColor),
                          cursorColor: colors.themeColor,
                          controller: _contractAddressController,
                          decoration: InputDecoration(
                              hintText: "Contract address",
                              hintStyle: GoogleFonts.robotoFlex(
                                  color: colors.textColor.withOpacity(0.4)),
                              contentPadding: const EdgeInsets.symmetric(
                                  vertical: 8, horizontal: 8),
                              prefixIcon: Icon(
                                LucideIcons.scrollText,
                                color: colors.textColor.withOpacity(0.3),
                              ),
                              filled: true,
                              fillColor: colors.grayColor.withOpacity(0.1),
                              enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide(
                                      width: 0, color: Colors.transparent)),
                              focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide(
                                      width: 0, color: Colors.transparent))),
                        ),
                      ),
                    ],
                  ),
                ),
              ));
        });
      });
}
