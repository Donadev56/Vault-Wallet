import 'package:flutter/material.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';

Future<T> showStandardModalBottomSheet<T>(
    {required BuildContext context,
    required Widget Function(BuildContext) builder,
    Color? barrierColor}) async {
  final T result = await showCupertinoModalBottomSheet(
      barrierColor: barrierColor ?? Colors.black.withOpacity(0.9),
      topRadius: const Radius.circular(20),
      backgroundColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      context: context,
      builder: builder);

  return result;
}
