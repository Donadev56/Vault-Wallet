import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:moonwallet/main.dart';
import 'package:moonwallet/types/types.dart';
import 'package:moonwallet/widgets/appBar/button.dart';

void showAppBarWalletActions(
    {required BuildContext context,
    required double height,
    required double width,
    required AppColors colors}) {
  showMaterialModalBottomSheet(
      backgroundColor: Colors.transparent,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
              topLeft: Radius.circular(15), topRight: Radius.circular(15))),
      context: context,
      builder: (BuildContext btnCtx) {
        return Container(
          height: height * 0.95,
          width: width,
          decoration: BoxDecoration(
              color: colors.primaryColor,
              borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(15), topRight: Radius.circular(15))),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                margin: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    AddWalletButton(
                        textColor: colors.textColor,
                        text: "Create a new wallet",
                        icon: Icons.add,
                        onTap: () {
                          Navigator.pushNamed(
                              context, Routes.createPrivateKeyMain);
                        }),
                    SizedBox(
                      height: 20,
                    ),
                    AddWalletButton(
                        textColor: colors.textColor,
                        text: "Import Mnemonic phrases",
                        icon: LucideIcons.fileText,
                        onTap: () {
                          Navigator.pushNamed(
                              context, Routes.createAccountFromSed);
                        }),
                    SizedBox(
                      height: 20,
                    ),
                    AddWalletButton(
                        textColor: colors.textColor,
                        text: "Import private key",
                        icon: LucideIcons.key,
                        onTap: () {
                          Navigator.pushNamed(context, Routes.importWalletMain);
                        }),
                    SizedBox(
                      height: 20,
                    ),
                    AddWalletButton(
                        textColor: colors.textColor,
                        text: "Observation wallet",
                        icon: LucideIcons.eye,
                        onTap: () {
                          Navigator.pushNamed(
                              context, Routes.addObservationWallet);
                        })
                  ],
                ),
              )
            ],
          ),
        );
      });
}
