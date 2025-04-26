import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:moonwallet/types/types.dart';
import 'package:moonwallet/widgets/custom_dialog.dart';

Future<bool> showConfirmAddTokenDialog({
  required BuildContext context,
  required SearchingContractInfo tokenFoundedData,
  required AppColors colors,
  required DoubleFactor roundedOf,
  required DoubleFactor fontSizeOf,
  required DoubleFactor iconSizeOf,
}) async {
  final response = await showDialog<bool>(
      context: context,
      builder: (btx) {
        final textTheme = TextTheme.of(btx);
        final width = MediaQuery.of(btx).size.width;
        return BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
            child: Dialog(
              backgroundColor: colors.primaryColor,
              child: CustomDialog(
                  colors: colors,
                  title: "Confirmation",
                  subtitle:
                      "Do your own research before adding a TOKEN, as anyone can create them, even malicious people.",
                  content: Padding(
                      padding: const EdgeInsets.only(top: 0),
                      child: Column(
                        spacing: 10,
                        children: [
                          Divider(
                            color: colors.textColor.withOpacity(0.2),
                          ),
                          Row(
                            spacing: 10,
                            children: [
                              Text(
                                "Name :",
                                style: textTheme.bodyMedium?.copyWith(
                                    fontSize: fontSizeOf(14),
                                    color: colors.textColor.withOpacity(0.5)),
                              ),
                              Text(
                                tokenFoundedData.name,
                                style: textTheme.bodyMedium?.copyWith(
                                    color: colors.textColor.withOpacity(0.8),
                                    fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          Row(
                            spacing: 10,
                            children: [
                              Text(
                                "Symbol :",
                                style: textTheme.bodyMedium?.copyWith(
                                    fontSize: fontSizeOf(14),
                                    color: colors.textColor.withOpacity(0.5)),
                              ),
                              Text(
                                tokenFoundedData.symbol,
                                style: textTheme.bodyMedium?.copyWith(
                                    color: colors.textColor.withOpacity(0.8),
                                    fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          Row(
                            spacing: 10,
                            children: [
                              Text(
                                "Decimals :",
                                style: textTheme.bodyMedium?.copyWith(
                                    fontSize: fontSizeOf(14),
                                    color: colors.textColor.withOpacity(0.5)),
                              ),
                              Text(
                                "${tokenFoundedData.decimals}",
                                style: textTheme.bodyMedium?.copyWith(
                                    fontSize: fontSizeOf(14),
                                    color: colors.textColor.withOpacity(0.8),
                                    fontWeight: FontWeight.bold),
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
                                                BorderRadius.circular(30)),
                                        backgroundColor: colors.themeColor),
                                    onPressed: () =>
                                        Navigator.pop(context, true),
                                    child: Text(
                                      "Add Token",
                                      style: textTheme.bodyLarge?.copyWith(
                                          fontSize: fontSizeOf(16),
                                          color: colors.primaryColor),
                                    ),
                                  )),
                              SizedBox(
                                  width: width * 0.9,
                                  child: OutlinedButton(
                                    style: OutlinedButton.styleFrom(
                                        side:
                                            BorderSide(color: colors.redColor),
                                        shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                                roundedOf(30)))),
                                    child: Text(
                                      "Cancel",
                                      style: textTheme.bodyLarge
                                          ?.copyWith(color: colors.redColor),
                                    ),
                                    onPressed: () {
                                      Navigator.pop(btx);
                                    },
                                  ))
                            ],
                          )
                        ],
                      ))),
            ));
      });

  return response ?? false;
}
