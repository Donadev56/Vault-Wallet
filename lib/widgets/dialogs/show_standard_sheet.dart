import 'package:flutter/material.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';

Future<T> showStandardModalBottomSheet<T>(
    {required BuildContext context,
    required Widget Function(BuildContext) builder,
    bool? isDismissible,
    bool? enableDarg,
    double rounded = 20,
    Color? barrierColor}) async {
  final T result = await showCupertinoModalBottomSheet(
      enableDrag: enableDarg ?? false,
      isDismissible: isDismissible,
      barrierColor: barrierColor ?? Colors.black.withOpacity(0.9),
      topRadius: Radius.circular(rounded),
      backgroundColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(rounded),
          topRight: Radius.circular(rounded),
        ),
      ),
      context: context,
      builder: builder);

  return result;
}
