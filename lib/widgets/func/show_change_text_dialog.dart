// ignore_for_file: deprecated_member_use

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:moonwallet/types/types.dart';
import 'package:moonwallet/widgets/custom_dialog.dart';

void showChangeTextDialog(
    {required BuildContext context,
    required AppColors colors,
    required TextEditingController textController,
    required Future<void> Function(String) onSubmit}) {
  showDialog(
      barrierColor: const Color.fromARGB(158, 0, 0, 0),
      context: context,
      builder: (BuildContext alertCtx) {
        final textTheme = Theme.of(context).textTheme;

        return BackdropFilter(
          filter: ImageFilter.blur(),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: 500,
            ),
            child: Dialog(
              backgroundColor: colors.primaryColor,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              child: CustomDialog(
                title: "Edit Name".toUpperCase(),
                subtitle: "Easily identify your wallets with unique names.",
                subTitleStyle: textTheme.bodyMedium?.copyWith(
                  fontSize: 12,
                  color: colors.textColor.withOpacity(0.5),
                ),
                colors: colors,
                content: Column(
                  children: [
                    TextField(
                      cursorColor: colors.textColor.withOpacity(0.2),
                      style: textTheme.bodyMedium
                          ?.copyWith(color: colors.textColor),
                      controller: textController,
                      decoration: InputDecoration(
                          filled: true,
                          fillColor: colors.textColor.withOpacity(0.1),
                          enabledBorder: OutlineInputBorder(
                            borderSide:
                                BorderSide(width: 0, color: Colors.transparent),
                          ),
                          focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                  width: 0, color: Colors.transparent))),
                    ),
                    SizedBox(
                      height: 15,
                    ),
                    Column(
                      spacing: 5,
                      children: [
                        SizedBox(
                            width: MediaQuery.of(context).size.width * 0.9,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(5)),
                                  elevation: 0,
                                  backgroundColor: colors.themeColor),
                              onPressed: () {
                                onSubmit(textController.text);
                                Navigator.pop(alertCtx);
                              },
                              child: Text(
                                "Change",
                                style: textTheme.bodyMedium?.copyWith(
                                  color: colors.primaryColor,
                                ),
                              ),
                            )),
                        TextButton(
                          onPressed: () {
                            textController.text = "";
                            Navigator.pop(alertCtx);
                          },
                          child: Text(
                            "Close",
                            style: textTheme.bodyMedium?.copyWith(
                              color: colors.textColor,
                            ),
                          ),
                        ),
                      ],
                    )
                  ],
                ),
              ),
            ),
          ),
        );
      });
}
