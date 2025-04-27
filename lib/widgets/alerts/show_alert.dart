import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:moonwallet/types/types.dart';

showWarning(
    {required BuildContext context,
    required AppColors colors,
    required Widget content,
    required List<Widget> actions,
    Color? titleColor,
    required String title,
    bool isDismissible = false,
    bool useBlur = true}) {
  showDialog(
      barrierDismissible: isDismissible,
      context: context,
      builder: (BuildContext ctx) {
        final textTheme = Theme.of(context).textTheme;
        return BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: useBlur ? 8.0 : 0,
            sigmaY: useBlur ? 8.0 : 0,
          ),
          child: AlertDialog(
            backgroundColor: colors.primaryColor,
            title: Text(
              title,
              style: textTheme.headlineMedium
                  ?.copyWith(color: Colors.orange, fontSize: 20),
            ),
            content: content,
            actions: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: actions,
              )
            ],
          ),
        );
      });
}
