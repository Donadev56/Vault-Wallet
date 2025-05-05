// ignore_for_file: deprecated_member_use, use_build_context_synchronously

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:moonwallet/screens/dashboard/settings/settings.dart';
import 'package:moonwallet/screens/dashboard/wallet_actions/private/private_key_screen.dart';
import 'package:moonwallet/types/account_related_types.dart';
import 'package:moonwallet/utils/number_formatter.dart';
import 'package:moonwallet/types/types.dart';
import 'package:moonwallet/widgets/avatar_modal.dart';
import 'package:moonwallet/widgets/screen_widgets/crypto_picture.dart';
import 'package:moonwallet/widgets/custom_options.dart';
import 'package:moonwallet/widgets/func/security/ask_password.dart';
import 'package:moonwallet/widgets/func/security/show_change_password_procedure.dart';
import 'package:moonwallet/widgets/func/appearance/show_profile_image_picker.dart';
import 'package:moonwallet/widgets/func/account_related/show_watch_only_warning.dart';
import 'package:moonwallet/widgets/func/snackbar.dart';
import 'package:moonwallet/widgets/profile_placeholder.dart';
import 'package:simple_gesture_detector/simple_gesture_detector.dart';

typedef DoubleFactor = double Function(double size);

void showCustomDrawer({
  required BuildContext context,
  File? profileImage,
  required Future<bool> Function(File) changeProfileImage,
  required AppColors colors,
  required List<Crypto> availableCryptos,
  required String totalBalanceUsd,
  required PublicAccount account,
  required Future<void> Function(PublicAccount account) deleteWallet,
  required bool canUseBio,
  required Future<bool> Function(bool state) toggleCanUseBio,
  required bool isHidden,
  required DoubleFactor roundedOf,
  required DoubleFactor fontSizeOf,
  required DoubleFactor iconSizeOf,
  required DoubleFactor imageSizeOf,
  required DoubleFactor listTitleHorizontalOf,
  required DoubleFactor listTitleVerticalOf,
  required Future Function(
          {required PublicAccount account,
          String? name,
          IconData? icon,
          Color? color})
      editWallet,
}) {
  bool canEditWalletName = false;
  TextEditingController textController = TextEditingController();
  String walletName = account.walletName;
  File? currentImage = profileImage;
  bool useBio = canUseBio;
  double bigRadius = 10;
  double smallRadius = 10;

  final BorderRadius borderRadiusTop = BorderRadius.only(
      topLeft: Radius.circular(roundedOf(bigRadius)),
      topRight: Radius.circular(roundedOf(bigRadius)),
      bottomLeft: Radius.circular(
        roundedOf(smallRadius),
      ),
      bottomRight: Radius.circular(roundedOf(smallRadius)));
  final BorderRadius borderRadiusBottom = BorderRadius.only(
      topLeft: Radius.circular(roundedOf(smallRadius)),
      topRight: Radius.circular(roundedOf(smallRadius)),
      bottomLeft: Radius.circular(
        roundedOf(bigRadius),
      ),
      bottomRight: Radius.circular(roundedOf(bigRadius)));

  showAvatarModalBottomSheet(
      avatarChild: currentImage != null
          ? Image.file(
              currentImage,
              width: imageSizeOf(70),
              height: imageSizeOf(70),
              fit: BoxFit.cover,
            )
          : ProfilePlaceholder(colors: colors),
      colors: colors,
      context: context,
      profileImage: currentImage,
      builder: (context) {
        final textTheme = Theme.of(context).textTheme;

        notifySuccess(String message) => showCustomSnackBar(
            context: context,
            message: message,
            colors: colors,
            type: MessageType.success);
        notifyError(String message) => showCustomSnackBar(
            context: context,
            message: message,
            colors: colors,
            type: MessageType.error);

        return StatefulBuilder(builder: (context, st) {
          return SimpleGestureDetector(
              onHorizontalSwipe: (direction) {
                if (direction == SwipeDirection.left) {
                  Navigator.pop(context);
                }
              },
              swipeConfig: SimpleSwipeConfig(
                verticalThreshold: 40.0,
                horizontalThreshold: 40.0,
                swipeDetectionBehavior:
                    SwipeDetectionBehavior.continuousDistinct,
              ),
              child: Material(
                  color: colors.primaryColor,
                  child: Padding(
                    padding: const EdgeInsets.all(15),
                    child: ListView(
                      shrinkWrap: true,
                      physics: BouncingScrollPhysics(),
                      children: [
                        canEditWalletName == false
                            ? Row(
                                spacing: 8,
                                children: [
                                  Text(
                                    walletName,
                                    style: textTheme.bodySmall?.copyWith(
                                        color:
                                            colors.textColor.withOpacity(0.7),
                                        fontSize: fontSizeOf(17),
                                        fontWeight: FontWeight.bold),
                                  ),
                                  IconButton(
                                      onPressed: () {
                                        st(() {
                                          textController.text = walletName;
                                          canEditWalletName = true;
                                        });
                                      },
                                      icon: Icon(
                                        LucideIcons.pencilLine,
                                        color:
                                            colors.textColor.withOpacity(0.7),
                                      ))
                                ],
                              )
                            : LayoutBuilder(builder: (ctx, c) {
                                final maxWidth = c.maxWidth;
                                return Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    SizedBox(
                                      width: maxWidth * 0.6,
                                      child: TextField(
                                        style: textTheme.bodySmall?.copyWith(
                                            color: colors.textColor
                                                .withOpacity(0.8)),
                                        controller: textController,
                                      ),
                                    ),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        IconButton(
                                          onPressed: () async {
                                            final res = await editWallet(
                                                account: account,
                                                name: textController.text);
                                            if (res) {
                                              st(() {
                                                canEditWalletName = false;
                                                walletName =
                                                    textController.text;
                                              });
                                            } else {
                                              showCustomSnackBar(
                                                  context: context,
                                                  message:
                                                      "Can't edit the wallet",
                                                  type: MessageType.error,
                                                  colors: colors);
                                            }
                                          },
                                          icon: Icon(
                                            Icons.check,
                                            color: colors.textColor,
                                          ),
                                        ),
                                        IconButton(
                                          icon: Icon(
                                            LucideIcons.x,
                                            color: colors.redColor,
                                          ),
                                          onPressed: () {
                                            st(() {
                                              textController.clear();
                                              canEditWalletName = false;
                                            });
                                          },
                                        )
                                      ],
                                    )
                                  ],
                                );
                              }),
                        Align(
                            alignment: Alignment.centerLeft,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              spacing: 6,
                              children: [
                                Text(
                                  !isHidden
                                      ? "\$${(NumberFormatter().formatDecimal(totalBalanceUsd, maxDecimals: 2))}"
                                      : "***",
                                  style: textTheme.bodySmall?.copyWith(
                                      color: colors.textColor,
                                      fontSize: fontSizeOf(25),
                                      fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  "Balance",
                                  style: textTheme.bodySmall?.copyWith(
                                    color: colors.textColor.withOpacity(0.6),
                                    fontSize: fontSizeOf(14),
                                  ),
                                ),
                              ],
                            )),
                        SizedBox(
                          height: 10,
                        ),
                        SingleChildScrollView(
                          physics: BouncingScrollPhysics(),
                          scrollDirection: Axis.horizontal,
                          child: SizedBox(
                            height: 50,
                            width: MediaQuery.of(context).size.width,
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
                                              size: imageSizeOf(24),
                                              colors: colors),
                                        ));
                                  })
                                  .toList()
                                  .reversed
                                  .toList(),
                            ),
                          ),
                        ),
                        SizedBox(
                          height: 10,
                        ),
                        Divider(
                          color: colors.textColor.withOpacity(0.05),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                "Preferences",
                                style: textTheme.bodySmall?.copyWith(
                                    color: colors.textColor.withOpacity(0.8),
                                    fontSize: fontSizeOf(20),
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(
                          height: 10,
                        ),
                        CustomOptionWidget(
                            colors: colors,
                            splashColor: colors.themeColor.withOpacity(0.1),
                            containerRadius:
                                BorderRadius.circular(roundedOf(10)),
                            spaceName: "Appearance",
                            internalElementSpacing: 10,
                            shapeBorder: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(roundedOf(10))),
                            backgroundColor: Colors.transparent,
                            spaceNameStyle: textTheme.bodySmall?.copyWith(
                                  color: colors.textColor,
                                ) ??
                                GoogleFonts.roboto(color: colors.textColor),
                            options: [
                              Option(
                                  shape: RoundedRectangleBorder(
                                      borderRadius: borderRadiusTop),
                                  tileColor: colors.secondaryColor,
                                  title: "Edit profile picture",
                                  icon: Icon(
                                    LucideIcons.user,
                                    color: colors.textColor.withOpacity(0.7),
                                    size: iconSizeOf(20),
                                  ),
                                  trailing: Icon(
                                    Icons.chevron_right,
                                    color: colors.textColor.withOpacity(0.5),
                                  ),
                                  color: colors.secondaryColor,
                                  titleStyle: textTheme.bodySmall?.copyWith(
                                      color: colors.textColor,
                                      fontSize: fontSizeOf(14))),
                              Option(
                                  shape: RoundedRectangleBorder(
                                      borderRadius: borderRadiusBottom),
                                  tileColor: colors.secondaryColor,
                                  title: "More Settings",
                                  icon: Icon(
                                    LucideIcons.settings,
                                    color: colors.textColor.withOpacity(0.7),
                                    size: iconSizeOf(20),
                                  ),
                                  trailing: Icon(Icons.chevron_right,
                                      color: colors.textColor.withOpacity(0.5)),
                                  color: colors.secondaryColor,
                                  titleStyle: textTheme.bodySmall?.copyWith(
                                      color: colors.textColor,
                                      fontSize: fontSizeOf(14))),
                            ],
                            onTap: (i) async {
                              if (i == 1) {
                                Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => SettingsPage(
                                        colors: colors,
                                      ),
                                    ));
                              } else if (i == 0) {
                                final file = await showProfileImagePicker(
                                    colors: colors,
                                    context: context,
                                    currentImage: currentImage);
                                if (file != null) {
                                  st(() {
                                    currentImage = file;
                                  });
                                  changeProfileImage(file);
                                }
                              }
                            }),
                        SizedBox(
                          height: 10,
                        ),
                        CustomOptionWidget(
                            colors: colors,
                            splashColor: colors.themeColor.withOpacity(0.1),
                            containerRadius:
                                BorderRadius.circular(roundedOf(10)),
                            spaceName: "Security",
                            internalElementSpacing: 10,
                            shapeBorder: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(roundedOf(10))),
                            backgroundColor: Colors.transparent,
                            spaceNameStyle: textTheme.bodySmall?.copyWith(
                                  color: colors.textColor,
                                ) ??
                                GoogleFonts.roboto(color: colors.textColor),
                            options: [
                              Option(
                                  shape: RoundedRectangleBorder(
                                      borderRadius: borderRadiusTop),
                                  tileColor: colors.secondaryColor,
                                  title: "Backup",
                                  icon: Icon(
                                    LucideIcons.key,
                                    color: colors.textColor.withOpacity(0.7),
                                    size: iconSizeOf(20),
                                  ),
                                  trailing: Icon(Icons.chevron_right,
                                      color: colors.textColor.withOpacity(0.5)),
                                  color: colors.secondaryColor,
                                  titleStyle: textTheme.bodySmall?.copyWith(
                                      color: colors.textColor,
                                      fontSize: fontSizeOf(14))),
                              Option(
                                  shape: RoundedRectangleBorder(
                                      borderRadius: borderRadiusBottom),
                                  tileColor: colors.secondaryColor,
                                  title: "Change password",
                                  icon: Icon(
                                    LucideIcons.keySquare,
                                    color: colors.textColor.withOpacity(0.7),
                                    size: iconSizeOf(20),
                                  ),
                                  trailing: Icon(
                                    Icons.chevron_right,
                                    color: colors.textColor.withOpacity(0.5),
                                  ),
                                  color: colors.secondaryColor,
                                  titleStyle: textTheme.bodySmall?.copyWith(
                                      color: colors.textColor,
                                      fontSize: fontSizeOf(14)))
                            ],
                            onTap: (i) async {
                              if (i == 0) {
                                if (account.isWatchOnly) {
                                  showWatchOnlyWaring(
                                      colors: colors, context: context);
                                  return;
                                }
                                final password = await askUserPassword(
                                    context: context, colors: colors);

                                if (password != null && password.isNotEmpty) {
                                  Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) =>
                                              PrivateKeyScreen(
                                                password: password,
                                                account: account,
                                                colors: colors,
                                              )));
                                }
                              } else if (i == 1) {
                                showChangePasswordProcedure(
                                    context: context, colors: colors);
                              }
                            }),
                        CustomOptionWidget(
                            colors: colors,
                            splashColor: colors.redColor.withOpacity(0.1),
                            containerRadius:
                                BorderRadius.circular(roundedOf(10)),
                            spaceName: "Others",
                            internalElementSpacing: 10,
                            shapeBorder: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(roundedOf(10))),
                            backgroundColor: Colors.transparent,
                            spaceNameStyle: textTheme.bodyMedium?.copyWith(
                                  color: colors.textColor,
                                ) ??
                                GoogleFonts.roboto(color: colors.textColor),
                            options: [
                              Option(
                                  splashColor:
                                      colors.themeColor.withOpacity(0.1),
                                  title: "Enable biometric",
                                  icon: Icon(
                                    LucideIcons.fingerprint,
                                    color: colors.textColor.withOpacity(0.7),
                                    size: iconSizeOf(20),
                                  ),
                                  trailing: Switch(
                                      value: useBio,
                                      onChanged: (v) async {
                                        final result = await toggleCanUseBio(v);

                                        if (result) {
                                          notifySuccess(
                                              v ? "Enabled" : "Disabled");
                                          st(() {
                                            useBio = v;
                                          });
                                          return;
                                        }

                                        notifyError("An error has occurred");
                                      }),
                                  color: colors.textColor,
                                  titleStyle: textTheme.bodySmall?.copyWith(
                                      color: colors.textColor,
                                      fontSize: fontSizeOf(14))),
                              Option(
                                  tileColor: colors.redColor.withOpacity(0.1),
                                  title: "Delete wallet",
                                  icon: Icon(
                                    LucideIcons.trash,
                                    color: colors.redColor.withOpacity(0.7),
                                    size: iconSizeOf(20),
                                  ),
                                  trailing: Icon(
                                    Icons.chevron_right,
                                    color: colors.redColor,
                                  ),
                                  color: colors.redColor,
                                  titleStyle: textTheme.bodySmall?.copyWith(
                                      color: colors.redColor,
                                      fontSize: fontSizeOf(14)))
                            ],
                            onTap: (i) {
                              if (i == 1) {
                                deleteWallet(account);
                              }
                            })
                      ],
                    ),
                  )));
        });
      });
}
