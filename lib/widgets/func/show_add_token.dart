// ignore_for_file: deprecated_member_use

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:moonwallet/custom/web3_webview/lib/utils/loading.dart';
import 'package:moonwallet/main.dart';
import 'package:moonwallet/service/crypto_storage_manager.dart';
import 'package:moonwallet/service/token_manager.dart';
import 'package:moonwallet/types/types.dart';
import 'package:moonwallet/widgets/crypto_picture.dart';
import 'package:moonwallet/widgets/custom_dialog.dart';
import 'package:moonwallet/widgets/func/snackbar.dart';
import 'package:ulid/ulid.dart';

typedef ActionWithIndexType = void Function(int index);
typedef ActionWithCryptoId = void Function(String cryptoId);

void showAddToken(
    {required BuildContext context,
    required AppColors colors,
    required double width,
    required List<Crypto> reorganizedCrypto,
    required PublicData currentAccount,
    required bool hasSaved}) {
  Crypto? selectedNetwork;
  TextEditingController _contractAddressController = TextEditingController();
  final textTheme = Theme.of(context).textTheme;

  final tokenManager = TokenManager();
  final cryptoStorageManager = CryptoStorageManager();
  SearchingContractInfo? searchingContractInfo;

  showCupertinoModalBottomSheet(
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
                                type: MessageType.error,
                                colors: colors,
                                context: context,
                                message: 'Please select a network.',
                                iconColor: Colors.pinkAccent);
                          }
                          if (_contractAddressController.text.isEmpty) {
                            showCustomSnackBar(
                                type: MessageType.error,
                                colors: colors,
                                context: context,
                                message: 'Please enter a contract address.',
                                iconColor: Colors.pinkAccent);
                          }
                          final tokenFoundedData = await tokenManager
                              .getCryptoInfo(
                                  address:
                                      _contractAddressController.text.trim(),
                                  network: selectedNetwork!)
                              .withLoading(context, colors);
                          setModalState(() {
                            searchingContractInfo = tokenFoundedData;
                          });
                          if (tokenFoundedData != null) {
                            showDialog(
                                context: context,
                                builder: (btx) {
                                  return BackdropFilter(
                                      filter: ImageFilter.blur(
                                          sigmaX: 8, sigmaY: 8),
                                      child: Dialog(
                                        backgroundColor: colors.primaryColor,
                                        child: CustomDialog(
                                            colors: colors,
                                            title: "Confirmation",
                                            subtitle:
                                                "Do your own research before adding a TOKEN, as anyone can create them, even malicious people.",
                                            content: Padding(
                                                padding: const EdgeInsets.only(
                                                    top: 0),
                                                child: Column(
                                                  spacing: 10,
                                                  children: [
                                                    Divider(
                                                      color: colors.textColor
                                                          .withOpacity(0.2),
                                                    ),
                                                    Row(
                                                      spacing: 10,
                                                      children: [
                                                        Text(
                                                          "Name :",
                                                          style: textTheme
                                                              .bodyMedium
                                                              ?.copyWith(
                                                                  color: colors
                                                                      .textColor
                                                                      .withOpacity(
                                                                          0.5)),
                                                        ),
                                                        Text(
                                                          "${tokenFoundedData.name}",
                                                          style: textTheme
                                                              .bodyMedium
                                                              ?.copyWith(
                                                                  color: colors
                                                                      .textColor
                                                                      .withOpacity(
                                                                          0.8),
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold),
                                                        ),
                                                      ],
                                                    ),
                                                    Row(
                                                      spacing: 10,
                                                      children: [
                                                        Text(
                                                          "Symbol :",
                                                          style: textTheme
                                                              .bodyMedium
                                                              ?.copyWith(
                                                                  color: colors
                                                                      .textColor
                                                                      .withOpacity(
                                                                          0.5)),
                                                        ),
                                                        Text(
                                                          "${tokenFoundedData.symbol}",
                                                          style: textTheme
                                                              .bodyMedium
                                                              ?.copyWith(
                                                                  color: colors
                                                                      .textColor
                                                                      .withOpacity(
                                                                          0.8),
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold),
                                                        ),
                                                      ],
                                                    ),
                                                    Row(
                                                      spacing: 10,
                                                      children: [
                                                        Text(
                                                          "Decimals :",
                                                          style: textTheme
                                                              .bodyMedium
                                                              ?.copyWith(
                                                                  color: colors
                                                                      .textColor
                                                                      .withOpacity(
                                                                          0.5)),
                                                        ),
                                                        Text(
                                                          "${tokenFoundedData.decimals}",
                                                          style: textTheme
                                                              .bodyMedium
                                                              ?.copyWith(
                                                                  color: colors
                                                                      .textColor
                                                                      .withOpacity(
                                                                          0.8),
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold),
                                                        ),
                                                      ],
                                                    ),
                                                    Column(
                                                      children: [
                                                        SizedBox(
                                                            width: width * 0.9,
                                                            child:
                                                                ElevatedButton(
                                                              style: ElevatedButton.styleFrom(
                                                                  elevation: 0,
                                                                  shape: RoundedRectangleBorder(
                                                                      borderRadius:
                                                                          BorderRadius.circular(
                                                                              30)),
                                                                  backgroundColor:
                                                                      colors
                                                                          .themeColor),
                                                              child: Text(
                                                                "Add Token",
                                                                style: textTheme
                                                                    .bodyLarge
                                                                    ?.copyWith(
                                                                        color: colors
                                                                            .primaryColor),
                                                              ),
                                                              onPressed:
                                                                  () async {
                                                                final List<
                                                                        Crypto>?
                                                                    cryptos =
                                                                    await cryptoStorageManager
                                                                        .getSavedCryptos(
                                                                            wallet:
                                                                                currentAccount);
                                                                if (cryptos !=
                                                                    null) {
                                                                  for (final crypto
                                                                      in cryptos) {
                                                                    if (crypto.contractAddress !=
                                                                            null &&
                                                                        crypto.contractAddress?.trim().toLowerCase() ==
                                                                            _contractAddressController.text.trim().toLowerCase()) {
                                                                      showCustomSnackBar(
                                                                          type: MessageType
                                                                              .warning,
                                                                          colors:
                                                                              colors,
                                                                          context:
                                                                              context,
                                                                          message:
                                                                              'Token already added.',
                                                                          iconColor:
                                                                              Colors.orange);
                                                                      Navigator.pop(
                                                                          context);
                                                                      return;
                                                                    }
                                                                  }
                                                                }

                                                                final newCrypto = Crypto(
                                                                    isNetworkIcon:
                                                                        false,
                                                                    symbol: searchingContractInfo?.symbol ??
                                                                        "",
                                                                    name: searchingContractInfo
                                                                            ?.name ??
                                                                        "Unknown ",
                                                                    color: selectedNetwork
                                                                            ?.color ??
                                                                        Colors
                                                                            .white,
                                                                    type: CryptoType
                                                                        .token,
                                                                    valueUsd: 0,
                                                                    cryptoId:
                                                                        generateUUID(),
                                                                    canDisplay:
                                                                        true,
                                                                    network:
                                                                        selectedNetwork,
                                                                    decimals: searchingContractInfo
                                                                        ?.decimals
                                                                        .toInt(),
                                                                    binanceSymbol:
                                                                        "${searchingContractInfo?.symbol}USDT",
                                                                    contractAddress:
                                                                        _contractAddressController
                                                                            .text);
                                                                final saveResult =
                                                                    await cryptoStorageManager.addCrypto(
                                                                        wallet:
                                                                            currentAccount,
                                                                        crypto:
                                                                            newCrypto);
                                                                if (saveResult) {
                                                                  hasSaved =
                                                                      true;
                                                                  showCustomSnackBar(
                                                                      type: MessageType
                                                                          .success,
                                                                      colors:
                                                                          colors,
                                                                      context:
                                                                          context,
                                                                      icon: Icons
                                                                          .check,
                                                                      message:
                                                                          'Token added successfully.',
                                                                      iconColor:
                                                                          Colors
                                                                              .green);
                                                                  Navigator.pop(
                                                                      context);
                                                                } else {
                                                                  showCustomSnackBar(
                                                                    type: MessageType
                                                                        .error,
                                                                    colors:
                                                                        colors,
                                                                    context:
                                                                        context,
                                                                    message:
                                                                        'Error adding token.',
                                                                    iconColor:
                                                                        Colors
                                                                            .red,
                                                                  );
                                                                  Navigator.pop(
                                                                      context);
                                                                }
                                                              },
                                                            )),
                                                        SizedBox(
                                                            width: width * 0.9,
                                                            child:
                                                                OutlinedButton(
                                                              style: OutlinedButton.styleFrom(
                                                                  side: BorderSide(
                                                                      color: colors
                                                                          .redColor),
                                                                  shape: RoundedRectangleBorder(
                                                                      borderRadius:
                                                                          BorderRadius.circular(
                                                                              30))),
                                                              child: Text(
                                                                "Cancel",
                                                                style: textTheme
                                                                    .bodyLarge
                                                                    ?.copyWith(
                                                                        color: colors
                                                                            .redColor),
                                                              ),
                                                              onPressed: () {
                                                                Navigator.pop(
                                                                    btx);
                                                              },
                                                            ))
                                                      ],
                                                    )
                                                  ],
                                                ))),
                                      ));
                                });
                          } else {
                            showCustomSnackBar(
                                type: MessageType.error,
                                colors: colors,
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
                          showBarModalBottomSheet(
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.only(
                                      topLeft: Radius.circular(30),
                                      topRight: Radius.circular(30))),
                              backgroundColor: colors.primaryColor,
                              context: context,
                              builder: (ctx) {
                                return Material(
                                    color: Colors.transparent,
                                    child: ListView.builder(
                                      shrinkWrap: true,
                                      itemCount: reorganizedCrypto
                                          .where((crypto) =>
                                              crypto.type == CryptoType.network)
                                          .length,
                                      itemBuilder: (ctx, i) {
                                        final crypto = reorganizedCrypto
                                            .where((crypto) =>
                                                crypto.type ==
                                                CryptoType.network)
                                            .toList()[i];
                                        return ListTile(
                                          leading: CryptoPicture(
                                              crypto: crypto,
                                              size: 30,
                                              colors: colors),
                                          title: Text(crypto.name,
                                              style: textTheme.bodyMedium
                                                  ?.copyWith(
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
                                      },
                                    ));
                              });
                        },
                        title: Text(
                          "${selectedNetwork != null ? selectedNetwork?.name : "Select an network"}",
                          style: textTheme.bodyMedium?.copyWith(
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
                          style: textTheme.bodyMedium
                              ?.copyWith(color: colors.textColor),
                          cursorColor: colors.themeColor,
                          controller: _contractAddressController,
                          decoration: InputDecoration(
                              hintText: "Contract address",
                              hintStyle: textTheme.bodyMedium?.copyWith(
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
