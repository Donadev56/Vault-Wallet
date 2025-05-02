import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:moonwallet/custom/web3_webview/lib/utils/loading.dart';
import 'package:moonwallet/service/web3_interactions/evm/web3_client.dart';
import 'package:moonwallet/types/types.dart';
import 'package:moonwallet/utils/id_manager.dart';
import 'package:moonwallet/widgets/custom_filled_text_field.dart';
import 'package:moonwallet/widgets/func/snackbar.dart';

Future<Crypto?> showAddNetwork({
  required BuildContext context,
  required AppColors colors,
  required DoubleFactor roundedOf,
  required DoubleFactor fontSizeOf,
  required DoubleFactor iconSizeOf,
}) async {
  final formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final symbolController = TextEditingController();
  final rpcUrlController = TextEditingController();
  final explorerController = TextEditingController();
  final chainIdController = TextEditingController();

  notifyError(String message) => showCustomSnackBar(
      context: context,
      message: message,
      colors: colors,
      type: MessageType.error);

  final crypto = await showCupertinoModalBottomSheet<Crypto>(
      backgroundColor: colors.primaryColor,
      context: context,
      builder: (context) {
        final textTheme = Theme.of(context).textTheme;

        return Scaffold(
          backgroundColor: colors.primaryColor,
          appBar: AppBar(
            backgroundColor: colors.primaryColor,
            surfaceTintColor: colors.primaryColor,
            leading: IconButton(
                onPressed: () => Navigator.pop(context),
                icon: Icon(
                  LucideIcons.chevronLeft,
                  color: colors.textColor.withValues(alpha: 0.5),
                )),
            actions: [
              IconButton(
                  onPressed: () async {
                    if (formKey.currentState?.validate() == true) {
                      final web3Client =
                          DynamicWeb3Client(rpcUrl: rpcUrlController.text);
                      final chainId = await web3Client
                          .getChainId()
                          .withLoading(context, colors);
                      if (chainId == null) {
                        notifyError("Invalid Rpc Url");
                      } else if (chainId !=
                          int.tryParse(chainIdController.text)) {
                        notifyError(
                            "RPC URL points to $chainId not ${chainIdController.text} ");
                      } else {
                        final newCrypto = Crypto(
                            name: nameController.text,
                            color: Colors.grey,
                            type: CryptoType.native,
                            decimals: 18,
                            cryptoId: IdManager().generateUUID(),
                            canDisplay: true,
                            symbol: symbolController.text,
                            rpcUrls: [rpcUrlController.text],
                            explorers: [explorerController.text],
                            chainId: int.parse(chainIdController.text));
                        Navigator.pop(context, newCrypto);
                      }
                    }
                  },
                  icon: Icon(
                    Icons.check,
                    color: colors.textColor.withValues(alpha: 0.5),
                  ))
            ],
          ),
          body: Form(
              key: formKey,
              child: Padding(
                padding: const EdgeInsets.all(15),
                child: ListView(
                  children: [
                    Text("Add Network",
                        style: textTheme.labelLarge?.copyWith(
                            color: colors.textColor, fontSize: fontSizeOf(20))),
                    SizedBox(
                      height: 15,
                    ),
                    CustomFilledTextFormField(
                      roundedOf: roundedOf,
                      fontSizeOf: fontSizeOf,
                      iconSizeOf: iconSizeOf,
                      labelText: "Name",
                      colors: colors,
                      hintText: "Name",
                      validator: (v) {
                        if (v == null || v.isEmpty) {
                          return "Name is required";
                        }

                        return null;
                      },
                      controller: nameController,
                    ),
                    SizedBox(
                      height: 10,
                    ),
                    CustomFilledTextFormField(
                      roundedOf: roundedOf,
                      fontSizeOf: fontSizeOf,
                      iconSizeOf: iconSizeOf,
                      labelText: "Symbol",
                      colors: colors,
                      hintText: "Symbol",
                      validator: (v) {
                        if (v == null || v.isEmpty) {
                          return "Symbol is required";
                        }

                        return null;
                      },
                      controller: symbolController,
                    ),
                    SizedBox(
                      height: 10,
                    ),
                    CustomFilledTextFormField(
                      roundedOf: roundedOf,
                      fontSizeOf: fontSizeOf,
                      iconSizeOf: iconSizeOf,
                      labelText: "Chain Id",
                      colors: colors,
                      hintText: "Chain Id",
                      validator: (v) {
                        if (v == null || v.isEmpty || int.tryParse(v) == null) {
                          return "Chain id is required";
                        }

                        return null;
                      },
                      keyboardType: TextInputType.numberWithOptions(),
                      controller: chainIdController,
                    ),
                    SizedBox(
                      height: 10,
                    ),
                    CustomFilledTextFormField(
                      roundedOf: roundedOf,
                      fontSizeOf: fontSizeOf,
                      iconSizeOf: iconSizeOf,
                      labelText: "Rpc Url",
                      colors: colors,
                      hintText: "Rpc Url",
                      validator: (v) {
                        if (v == null || v.isEmpty) {
                          return "Rpc Url is required";
                        }

                        return null;
                      },
                      controller: rpcUrlController,
                    ),
                    SizedBox(
                      height: 10,
                    ),
                    CustomFilledTextFormField(
                      roundedOf: roundedOf,
                      fontSizeOf: fontSizeOf,
                      iconSizeOf: iconSizeOf,
                      labelText: "Explorer (optional)",
                      colors: colors,
                      hintText: "Explorer (optional)",
                      controller: explorerController,
                    ),
                  ],
                ),
              )),
        );
      });
  return crypto;
}
