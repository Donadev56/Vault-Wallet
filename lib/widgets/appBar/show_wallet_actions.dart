import 'package:flutter/material.dart';
import 'package:moonwallet/types/types.dart';
import 'package:moonwallet/widgets/dialogs/show_standard_sheet.dart';
import 'package:moonwallet/widgets/dialogs/standard_container.dart';

void showAppBarWalletActions(
    {required BuildContext context,
    required List<Widget> children,
    required AppColors colors}) {
  showStandardModalBottomSheet(
      rounded: 10,
      context: context,
      builder: (BuildContext btnCtx) {
        return Material(
          color: colors.primaryColor,
          child: StandardContainer(
              rounded: 10,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    Align(
                      alignment: Alignment.center,
                      child: Container(
                        margin: const EdgeInsets.all(5),
                        height: 5,
                        width: 50,
                        decoration: BoxDecoration(
                            color: colors.secondaryColor,
                            borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                    SizedBox(
                      height: 12,
                    ),
                    ...children
                  ],
                ),
              )),
        );
      });
}
