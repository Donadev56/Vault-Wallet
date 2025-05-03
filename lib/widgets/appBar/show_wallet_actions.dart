import 'package:flutter/material.dart';
import 'package:moonwallet/types/types.dart';
import 'package:moonwallet/widgets/dialogs/show_standard_sheet.dart';
import 'package:moonwallet/widgets/dialogs/standard_container.dart';

void showAppBarWalletActions(
    {required BuildContext context,
    required List<Widget> children,
    required AppColors colors}) {
  showStandardModalBottomSheet(
      context: context,
      builder: (BuildContext btnCtx) {
        return Material(
          color: colors.primaryColor,
          child: StandardContainer(
              child: Padding(
            padding: const EdgeInsets.all(15),
            child: ListView(
              shrinkWrap: true,
              children: children,
            ),
          )),
        );
      });
}
