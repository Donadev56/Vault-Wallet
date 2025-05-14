import 'package:flutter/material.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:moonwallet/logger/logger.dart';
import 'package:moonwallet/types/types.dart';
import 'package:moonwallet/widgets/dialogs/show_custom_snackbar.dart';
import 'package:moonwallet/widgets/func/transactions/transactions_body/customization_parent_container.dart';
import 'package:moonwallet/widgets/func/transactions/transactions_body/expended_button.dart';

Future<UserCustomGasRequestResponse?> showCustomGasModal(
    {required BuildContext context, required AppColors colors}) async {
  try {
    TextEditingController gasLimitController = TextEditingController();
    TextEditingController gasPriceController = TextEditingController();

    final customGas =
        await showCupertinoModalBottomSheet<UserCustomGasRequestResponse?>(
      context: context,
      builder: (BuildContext editCtx) {
        final textTheme = TextTheme.of(context);
        return CustomizationParentContainer(
          colors: colors,
          title: "Custom Gas",
          actions: [
            IconButton(
              onPressed: () {
                Navigator.pop(
                  context,
                );
              },
              icon: Icon(FeatherIcons.xCircle, color: Colors.pinkAccent),
            )
          ],
          bottom: ExpendedElevatedButton(
            onPressed: () {
              if (gasLimitController.text.isEmpty ||
                  gasPriceController.text.isEmpty) {
                notifyError("Fill all fields", context);
                return;
              }

              Navigator.pop(
                  context,
                  UserCustomGasRequestResponse(
                      ok: true,
                      gasLimit: BigInt.parse(gasLimitController.text),
                      gasPrice: BigInt.parse(gasPriceController.text)));
            },
            colors: colors,
            text: "Confirm",
          ),
          children: [
            TextField(
              controller: gasLimitController,
              keyboardType: TextInputType.number,
              style: textTheme.bodyMedium?.copyWith(color: colors.textColor),
              decoration: InputDecoration(
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                      width: 1, color: colors.textColor.withOpacity(0.1)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                      width: 1, color: colors.primaryColor.withOpacity(0.1)),
                ),
                labelText: "Gas Limit",
                border: InputBorder.none,
                suffixText: "Gwei",
              ),
            ),
            SizedBox(height: 20),
            TextField(
              controller: gasPriceController,
              style: textTheme.bodyMedium?.copyWith(color: colors.textColor),
              keyboardType: TextInputType.number,
              onChanged: (value) {},
              decoration: InputDecoration(
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                      width: 1, color: colors.textColor.withOpacity(0.1)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide:
                      BorderSide(width: 1, color: colors.secondaryColor),
                ),
                labelText: "Gas Price",
                border: InputBorder.none,
                suffixText: "Gwei",
              ),
            ),
            SizedBox(
              height: 20,
            ),
          ],
        );
      },
    );

    return customGas;
  } catch (e) {
    logError(e.toString());
    return null;
  }
}
