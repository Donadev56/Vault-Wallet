import 'package:flutter/material.dart';
import 'package:moonwallet/widgets/dialogs/show_standard_sheet.dart';

Future<T?> showTransactionRequest<T>({
  required Widget Function(BuildContext) builder,
  required BuildContext context,
}) async {
  final T result =
      await showStandardModalBottomSheet(context: context, builder: builder);

  return result;
}
