import 'package:flutter/material.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:moonwallet/logger/logger.dart';
import 'package:moonwallet/types/types.dart';
import 'package:moonwallet/widgets/func/snackbar.dart';

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
                        padding: const EdgeInsets.all(10),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Customize gas",
                              style: textTheme.headlineMedium?.copyWith(
                                  color: colors.textColor,
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
                        controller: gasLimitController,
                        keyboardType: TextInputType.number,
                        style: textTheme.bodyMedium
                            ?.copyWith(color: colors.textColor),
                        decoration: InputDecoration(
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                                width: 1,
                                color: colors.textColor.withOpacity(0.1)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                                width: 1,
                                color: colors.primaryColor.withOpacity(0.1)),
                          ),
                          labelText: "Gas Limit",
                          border: InputBorder.none,
                          suffixText: "Gwei",
                        ),
                      ),
                      SizedBox(height: 20),
                      TextField(
                        controller: gasPriceController,
                        style: textTheme.bodyMedium
                            ?.copyWith(color: colors.textColor),
                        keyboardType: TextInputType.number,
                        onChanged: (value) {},
                        decoration: InputDecoration(
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                                width: 1,
                                color: colors.textColor.withOpacity(0.1)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                                width: 1, color: colors.secondaryColor),
                          ),
                          labelText: "Gas Price",
                          border: InputBorder.none,
                          suffixText: "Gwei",
                        ),
                      ),
                      SizedBox(
                        height: 20,
                      ),
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          color: colors.themeColor,
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(10),
                            onTap: () {
                              if (gasLimitController.text.isEmpty ||
                                  gasPriceController.text.isEmpty) {
                                showCustomSnackBar(
                                    context: context,
                                    message: "Fill all fields",
                                    colors: colors);
                                return;
                              }

                              Navigator.pop(
                                  context,
                                  UserCustomGasRequestResponse(
                                      ok: true,
                                      gasLimit:
                                          BigInt.parse(gasLimitController.text),
                                      gasPrice: BigInt.parse(
                                          gasPriceController.text)));
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
                      ),
                    ],
                  ))),
        );
      },
    );

    return customGas;
  } catch (e) {
    logError(e.toString());
    return null;
  }
}
