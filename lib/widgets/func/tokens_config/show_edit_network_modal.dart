import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:moonwallet/types/types.dart';
import 'package:moonwallet/widgets/custom_filled_text_field.dart';
import 'package:moonwallet/widgets/func/snackbar.dart';

Future<Crypto?> showEditNetwork(
    {required Crypto network,
    required BuildContext context,
    required DoubleFactor roundedOf,
    required DoubleFactor fontSizeOf,
    required DoubleFactor iconSizeOf,
    required Future<bool> Function(
            {required int chainId,
            String? name,
            String? symbol,
            List<String>? explorers,
            List<String>? rpcUrls})
        onSubmitted,
    required AppColors colors}) async {
  final formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final symbolController = TextEditingController();
  final rpcUrlController = TextEditingController();
  final explorerController = TextEditingController();
  final chainIdController = TextEditingController();

  nameController.text = network.name;
  symbolController.text = network.symbol;
  chainIdController.text = network.chainId.toString();
  explorerController.text = network.explorers?.firstOrNull ?? "";
  rpcUrlController.text = network.rpcUrls?.firstOrNull ?? "";

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
                      final chainId = network.chainId;
                      if (chainId == null) {
                        notifyError("Invalid Chain ID");
                        return;
                      }
                      final response = await onSubmitted(
                          chainId: chainId,
                          name: nameController.text.isEmpty
                              ? null
                              : nameController.text,
                          symbol: symbolController.text.isEmpty
                              ? null
                              : symbolController.text,
                          explorers: explorerController.text.isEmpty
                              ? null
                              : [explorerController.text],
                          rpcUrls: rpcUrlController.text.isEmpty
                              ? null
                              : [rpcUrlController.text]);

                      if (response) {
                        Navigator.pop(context);
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
                    Text("Edit Network",
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
                      readOnly: true,
                      hintText: "Chain Id",
                      validator: (v) {
                        if (int.tryParse(v ?? "") == null) {
                          return "Invalid ChainId";
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
