// ignore_for_file: deprecated_member_use

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:moonwallet/screens/dashboard/settings/change_colors.dart';
import 'package:moonwallet/types/types.dart';
import 'package:moonwallet/widgets/avatar_modal.dart';
import 'package:moonwallet/widgets/crypto_picture.dart';
import 'package:moonwallet/widgets/custom_options.dart';

void showCustomDrawer(
    {required BuildContext context,
    File? profileImage,
    required AppColors colors,
    required List<Crypto> availableCryptos,
    required double totalBalanceUsd,
    required PublicData account}) {
  bool canEditWalletName = false;
  TextEditingController _textController = TextEditingController();

  showAvatarModalBottomSheet(
      avatarChild: profileImage != null
          ? Image.file(
              profileImage,
              width: 70,
              height: 70,
              fit: BoxFit.cover,
            )
          : Image.asset(
              "assets/pro/image.png",
              width: 70,
              height: 70,
              fit: BoxFit.cover,
            ),
      colors: colors,
      context: context,
      profileImage: profileImage,
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx, st) {
          return Material(
              color: colors.primaryColor,
              child: Padding(
                padding: const EdgeInsets.all(15),
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    canEditWalletName == false
                        ? Row(
                            spacing: 8,
                            children: [
                              Text(
                                account.walletName,
                                style: GoogleFonts.roboto(
                                    color: colors.textColor.withOpacity(0.7),
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold),
                              ),
                              IconButton(
                                  onPressed: () {
                                    st(() {
                                      _textController.text = account.walletName;
                                      canEditWalletName = true;
                                    });
                                  },
                                  icon: Icon(
                                    LucideIcons.pencilLine,
                                    color: colors.textColor.withOpacity(0.7),
                                  ))
                            ],
                          )
                        : LayoutBuilder(builder: (ctx, c) {
                            final maxWidth = c.maxWidth;
                            return Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                SizedBox(
                                  width: maxWidth * 0.6,
                                  child: TextField(
                                    controller: _textController,
                                  ),
                                ),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    SizedBox(
                                      width: maxWidth * 0.15,
                                      child: ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                              backgroundColor:
                                                  colors.textColor),
                                          onPressed: () {},
                                          child: Icon(
                                            LucideIcons.check,
                                            color: colors.textColor,
                                          )),
                                    ),
                                    SizedBox(
                                      width: maxWidth * 0.15,
                                      child: ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                              backgroundColor:
                                                  Colors.transparent,
                                              side: BorderSide(
                                                  width: 2,
                                                  color: colors.redColor)),
                                          onPressed: () {
                                            st(() {
                                              canEditWalletName = false;
                                              _textController.clear();
                                            });
                                          },
                                          child: Icon(
                                            LucideIcons.x,
                                            color: colors.textColor,
                                          )),
                                    )
                                  ],
                                )
                              ],
                            );
                          }),
                    SizedBox(
                      height: 10,
                    ),
                    SizedBox(
                      height: 50,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: availableCryptos
                            .asMap()
                            .entries
                            .map((entry) {
                              int index = entry.key;
                              var crypto = entry.value;
                              return Positioned(
                                  left: index * 18.0,
                                  child: Container(
                                    padding: const EdgeInsets.all(3),
                                    decoration: BoxDecoration(
                                        color: colors.primaryColor,
                                        borderRadius:
                                            BorderRadius.circular(20)),
                                    child: CryptoPicture(
                                        crypto: crypto,
                                        size: 24,
                                        colors: colors),
                                  ));
                            })
                            .toList()
                            .reversed
                            .toList(),
                      ),
                    ),
                    Align(
                        alignment: Alignment.centerLeft,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "\$${totalBalanceUsd.toStringAsFixed(2)}",
                              style: GoogleFonts.roboto(
                                  color: colors.textColor,
                                  fontSize: 30,
                                  fontWeight: FontWeight.bold),
                            ),
                            Text(
                              "Balance",
                              style: GoogleFonts.robotoMono(
                                color: colors.textColor.withOpacity(0.6),
                                fontSize: 16,
                              ),
                            ),
                          ],
                        )),
                    SizedBox(
                      height: 10,
                    ),
                    Divider(
                      color: colors.textColor.withOpacity(0.05),
                    ),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "Settings",
                        style: GoogleFonts.roboto(
                            color: colors.textColor.withOpacity(0.8),
                            fontSize: 20,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                    SizedBox(
                      height: 10,
                    ),
                    CustomOptionWidget(
                        splashColor: colors.themeColor.withOpacity(0.1),
                        containerRadius: BorderRadius.circular(10),
                        spaceName: "Appearance",
                        internalElementSpacing: 10,
                        shapeBorder: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        backgroundColor: Colors.transparent,
                        spaceNameStyle: GoogleFonts.roboto(
                          color: colors.textColor,
                        ),
                        options: [
                          Option(
                              tileColor: colors.secondaryColor.withOpacity(0.5),
                              title: "Change App Theme",
                              icon: Icon(
                                LucideIcons.palette,
                                color: colors.textColor.withOpacity(0.7),
                                size: 20,
                              ),
                              trailing: Icon(Icons.chevron_right,
                                  color: colors.textColor.withOpacity(0.5)),
                              color: colors.secondaryColor,
                              titleStyle: GoogleFonts.roboto(
                                  color: colors.textColor, fontSize: 14)),
                          Option(
                              tileColor: colors.secondaryColor.withOpacity(0.5),
                              title: "Edit profile picture",
                              icon: Icon(
                                LucideIcons.user,
                                color: colors.textColor.withOpacity(0.7),
                                size: 20,
                              ),
                              trailing: Icon(
                                Icons.chevron_right,
                                color: colors.textColor.withOpacity(0.5),
                              ),
                              color: colors.secondaryColor,
                              titleStyle: GoogleFonts.roboto(
                                  color: colors.textColor, fontSize: 14))
                        ],
                        onTap: (i) {
                          if (i == 0) {
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ChangeThemeView(),
                                ));
                          }
                        }),
                    SizedBox(
                      height: 10,
                    ),
                    CustomOptionWidget(
                        splashColor: colors.themeColor.withOpacity(0.1),
                        containerRadius: BorderRadius.circular(10),
                        spaceName: "Security",
                        internalElementSpacing: 10,
                        shapeBorder: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        backgroundColor: Colors.transparent,
                        spaceNameStyle: GoogleFonts.roboto(
                          color: colors.textColor,
                        ),
                        options: [
                          Option(
                              tileColor: colors.secondaryColor.withOpacity(0.5),
                              title: "View private data",
                              icon: Icon(
                                LucideIcons.key,
                                color: colors.textColor.withOpacity(0.7),
                                size: 20,
                              ),
                              trailing: Icon(Icons.chevron_right,
                                  color: colors.textColor.withOpacity(0.5)),
                              color: colors.secondaryColor,
                              titleStyle: GoogleFonts.roboto(
                                  color: colors.textColor, fontSize: 14)),
                          Option(
                              tileColor: colors.secondaryColor.withOpacity(0.5),
                              title: "Change password",
                              icon: Icon(
                                LucideIcons.keySquare,
                                color: colors.textColor.withOpacity(0.7),
                                size: 20,
                              ),
                              trailing: Icon(
                                Icons.chevron_right,
                                color: colors.textColor.withOpacity(0.5),
                              ),
                              color: colors.secondaryColor,
                              titleStyle: GoogleFonts.roboto(
                                  color: colors.textColor, fontSize: 14))
                        ],
                        onTap: (i) {}),
                    CustomOptionWidget(
                        splashColor: colors.redColor.withOpacity(0.1),
                        containerRadius: BorderRadius.circular(10),
                        spaceName: "Others",
                        internalElementSpacing: 10,
                        shapeBorder: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        backgroundColor: Colors.transparent,
                        spaceNameStyle: GoogleFonts.roboto(
                          color: colors.textColor,
                        ),
                        options: [
                          Option(
                              tileColor: colors.redColor.withOpacity(0.1),
                              title: "Delete wallet",
                              icon: Icon(
                                LucideIcons.trash,
                                color: colors.redColor.withOpacity(0.7),
                                size: 20,
                              ),
                              trailing: Icon(
                                Icons.chevron_right,
                                color: colors.redColor,
                              ),
                              color: colors.redColor,
                              titleStyle: GoogleFonts.roboto(
                                  color: colors.redColor, fontSize: 14))
                        ],
                        onTap: (i) {})
                  ],
                ),
              ));
        });
      });
}
