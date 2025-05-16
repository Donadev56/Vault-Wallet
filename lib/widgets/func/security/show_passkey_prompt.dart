import 'package:flutter/material.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:moonwallet/types/types.dart';
import 'package:moonwallet/widgets/secure_check_view.dart';

Future<String?> showPassKeyPromptScreen(
    BuildContext context, AppColors colors) async {
  return await showMaterialModalBottomSheet<String?>(
    enableDrag: false,
    isDismissible: false,
    context: context,
    builder: (ctx) => SecureCheckView(colors: colors),
  );
}
