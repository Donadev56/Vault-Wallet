// ignore_for_file: deprecated_member_use, use_build_context_synchronously

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:moonwallet/custom/web3_webview/lib/utils/loading.dart';
import 'package:moonwallet/logger/logger.dart';
import 'package:moonwallet/main.dart';
import 'package:moonwallet/notifiers/providers.dart';
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
    required bool hasSaved}) {
  Crypto? selectedNetwork;
  TextEditingController contractAddressController = TextEditingController();

  final tokenManager = TokenManager();
  SearchingContractInfo? searchingContractInfo;
  List<Crypto> reorganizedCrypto = [];

  showCupertinoModalBottomSheet(
      backgroundColor: colors.primaryColor,
      context: context,
      builder: (context) {
        final textTheme = Theme.of(context).textTheme;
        notifySuccess(String message) => showCustomSnackBar(
            context: context,
            message: message,
            colors: colors,
            type: MessageType.success);
        notifyError(String message) => showCustomSnackBar(
            context: context,
            message: message,
            colors: colors,
            type: MessageType.error);

        return StatefulBuilder(builder: (bCtx, setModalState) {
          String generateUUID() {
            return Ulid().toUuid();
          }

          return Consumer(builder: (ctx, ref, child) {
            final savedCryptoAsync = ref.watch(savedCryptosProviderNotifier);
            final savedCryptoProvider =
                ref.watch(savedCryptosProviderNotifier.notifier);

            savedCryptoAsync.whenData(
              (value) {
                setModalState(() {
                  reorganizedCrypto = value ?? [];
                });
              },
            );

            Future<void> addCrypto() async {
              try {
                {
                  final newCrypto = Crypto(
                      isNetworkIcon: false,
                      symbol: searchingContractInfo?.symbol ?? "",
                      name: searchingContractInfo?.name ?? "Unknown ",
                      color: selectedNetwork?.color ?? Colors.white,
                      type: CryptoType.token,
                      valueUsd: 0,
                      cryptoId: generateUUID(),
                      canDisplay: true,
                      network: selectedNetwork,
                      decimals: searchingContractInfo?.decimals.toInt(),
                      binanceSymbol: "${searchingContractInfo?.symbol}USDT",
                      contractAddress: contractAddressController.text);

                  final saveResult =
                      await savedCryptoProvider.addCrypto(newCrypto);
                  if (saveResult) {
                    hasSaved = true;
                    notifySuccess('Token added successfully.');

                    Navigator.pop(context);
                  } else {
                    notifyError('Error adding token.');
                    Navigator.pop(context);
                  }
                }
              } catch (e) {
                logError(e.toString());
                notifyError(e.toString());
              }
            }

            return SafeArea(
                child: Scaffold(
              backgroundColor: colors.primaryColor,
              appBar: AppBar(
                actions: [
                  IconButton(
                      onPressed: () async {
                        if (selectedNetwork == null) {
                          notifyError("Please select a network.");
                        }
                        if (contractAddressController.text.isEmpty) {
                          notifyError('Please enter a contract address.');
                        }
                        final tokenFoundedData = await tokenManager
                            .getCryptoInfo(
                                address: contractAddressController.text.trim(),
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
                                    filter:
                                        ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                                    child: Dialog(
                                      backgroundColor: colors.primaryColor,
                                      child: CustomDialog(
                                          colors: colors,
                                          title: "Confirmation",
                                          subtitle:
                                              "Do your own research before adding a TOKEN, as anyone can create them, even malicious people.",
                                          content: Padding(
                                              padding:
                                                  const EdgeInsets.only(top: 0),
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
                                                        tokenFoundedData.name,
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
                                                        tokenFoundedData.symbol,
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
                                                          child: ElevatedButton(
                                                            style: ElevatedButton.styleFrom(
                                                                elevation: 0,
                                                                shape: RoundedRectangleBorder(
                                                                    borderRadius:
                                                                        BorderRadius.circular(
                                                                            30)),
                                                                backgroundColor:
                                                                    colors
                                                                        .themeColor),
                                                            onPressed:
                                                                addCrypto,
                                                            child: Text(
                                                              "Add Token",
                                                              style: textTheme
                                                                  .bodyLarge
                                                                  ?.copyWith(
                                                                      color: colors
                                                                          .primaryColor),
                                                            ),
                                                          )),
                                                      SizedBox(
                                                          width: width * 0.9,
                                                          child: OutlinedButton(
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
                          notifyError('Token not found.');
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
                                              crypto.type == CryptoType.network)
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
                        controller: contractAddressController,
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
      });
}
