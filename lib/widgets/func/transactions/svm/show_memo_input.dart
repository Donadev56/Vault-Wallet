import 'package:flutter/material.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:moonwallet/logger/logger.dart';
import 'package:moonwallet/types/types.dart';
import 'package:moonwallet/widgets/custom_filled_text_field.dart';
import 'package:moonwallet/widgets/func/transactions/transactions_body/customization_parent_container.dart';
import 'package:moonwallet/widgets/func/transactions/transactions_body/expended_button.dart';
import 'package:moonwallet/widgets/func/transactions/transactions_body/label_text.dart';

Future<String?> showMemoInput(
    {required BuildContext context,
    required AppColors colors,
    String? initialText}) async {
  try {
    bool isInit = false;
    TextEditingController memoController = TextEditingController();

    final memo = await showCupertinoModalBottomSheet<String?>(
      context: context,
      builder: (BuildContext context) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!isInit) {
            isInit = true;
            if (initialText != null && initialText.isNotEmpty) {
              memoController.text = initialText;
            }
          }
        });
        return CustomizationParentContainer(
          bottom: ExpendedElevatedButton(
            icon: Icon(
              Icons.add,
              color: colors.primaryColor,
            ),
            onPressed: () => Navigator.pop(context, memoController.text),
            colors: colors,
            text: "Add Memo",
          ),
          colors: colors,
          title: "Add Memo",
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
          children: [
            Align(
                alignment: Alignment.centerLeft,
                child: LabelText(colors: colors, text: "Memo")),
            SizedBox(
              height: 10,
            ),
            CustomFilledTextFormField(
                controller: memoController,
                suffixIcon: Icon(
                  Icons.article,
                  color: colors.textColor,
                  size: 20,
                ),
                colors: colors,
                fontSizeOf: (v) => v,
                iconSizeOf: (v) => v,
                roundedOf: (v) => v)
          ],
        );
      },
    );

    return memo;
  } catch (e) {
    logError(e.toString());
    return null;
  }
}
