import 'package:flutter/material.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';

Future<T> showStandardModalBottomSheet<T>({
  required Widget Function(BuildContext) builder,
  required BuildContext context,
}) async {
  final T result = await showCupertinoModalBottomSheet(
      barrierColor: Colors.black.withOpacity(0.9),
      topRadius: const Radius.circular(30),
      backgroundColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
      ),
      context: context,
      builder: builder);

  return result;
}
