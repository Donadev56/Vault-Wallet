import 'package:flutter/material.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:moonwallet/types/types.dart';

void showAppBarWalletActions(
    {required BuildContext context,
    required Widget child,
    required AppColors colors}) {
  showBarModalBottomSheet(
      backgroundColor: Colors.transparent,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
              topLeft: Radius.circular(15), topRight: Radius.circular(15))),
      context: context,
      builder: (BuildContext btnCtx) {
        final width = MediaQuery.of(context).size.width;
        return Container(
          width: width,
          decoration: BoxDecoration(
              color: colors.primaryColor,
              borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(15), topRight: Radius.circular(15))),
          child: ListView(
            shrinkWrap: true,
            children: [
              Container(
                margin: const EdgeInsets.all(20),
                child: child,
              )
            ],
          ),
        );
      });
}
