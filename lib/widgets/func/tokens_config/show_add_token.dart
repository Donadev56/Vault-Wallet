// ignore_for_file: deprecated_member_use, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:moonwallet/custom/web3_webview/lib/utils/loading.dart';
import 'package:moonwallet/main.dart';
import 'package:moonwallet/service/web3_interactions/evm/token_manager.dart';
import 'package:moonwallet/types/account_related_types.dart';
import 'package:moonwallet/types/types.dart';
import 'package:moonwallet/widgets/dialogs/show_custom_snackbar.dart';
import 'package:moonwallet/widgets/func/tokens_config/show_confirm_add_token.dart';
import 'package:moonwallet/widgets/func/tokens_config/show_select_network_modal.dart';

typedef ActionWithIndexType = void Function(int index);
typedef ActionWithCryptoId = void Function(String cryptoId);

void showAddToken(
    {required BuildContext context,
    required AppColors colors,
    required double width,
    required DoubleFactor roundedOf,
    required DoubleFactor fontSizeOf,
    required DoubleFactor iconSizeOf,
    required void Function(SearchingContractInfo?, String, Crypto?) addCrypto,
    required List<Crypto> reorganizedCrypto,
    required bool hasSaved}) {
  Crypto? selectedNetwork;
  TextEditingController contractAddressController = TextEditingController();

  final tokenManager = TokenManager();
  SearchingContractInfo? searchingContractInfo;

  showCupertinoModalBottomSheet(
      backgroundColor: colors.primaryColor,
      context: context,
      builder: (context) {
        final textTheme = Theme.of(context).textTheme;

        return StatefulBuilder(builder: (bCtx, setModalState) {
          return SafeArea(
              child: Scaffold(
            backgroundColor: colors.primaryColor,
            appBar: AppBar(
              actions: [
                IconButton(
                    onPressed: () async {
                      if (selectedNetwork == null) {
                        notifyError("Please select a network.", context);
                      }
                      if (contractAddressController.text.isEmpty) {
                        notifyError(
                            'Please enter a contract address.', context);
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
                        final response = await showConfirmAddTokenDialog(
                            roundedOf: roundedOf,
                            fontSizeOf: fontSizeOf,
                            iconSizeOf: iconSizeOf,
                            context: context,
                            tokenFoundedData: tokenFoundedData,
                            colors: colors);
                        if (response) {
                          addCrypto(searchingContractInfo,
                              contractAddressController.text, selectedNetwork);
                        }
                      } else {
                        notifyError('Token not found.', context);
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
                    onTap: () async {
                      final selectedCrypto = await showSelectNetworkModal(
                          roundedOf: roundedOf,
                          fontSizeOf: fontSizeOf,
                          iconSizeOf: iconSizeOf,
                          context: context,
                          colors: colors,
                          networks: reorganizedCrypto);
                      if (selectedCrypto != null) {
                        setModalState(() {
                          selectedNetwork = selectedCrypto;
                        });
                      }
                    },
                    title: Text(
                      "${selectedNetwork != null ? selectedNetwork?.name : "Select an network"}",
                      style: textTheme.bodyMedium
                          ?.copyWith(color: colors.textColor.withOpacity(0.5)),
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
                              fontSize: fontSizeOf(14),
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
                              borderRadius:
                                  BorderRadius.circular(roundedOf(10)),
                              borderSide: BorderSide(
                                  width: 0, color: Colors.transparent)),
                          focusedBorder: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.circular(roundedOf(10)),
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
