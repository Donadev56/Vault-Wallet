// ignore_for_file: deprecated_member_use, use_build_context_synchronously

import 'dart:io';

import 'package:currency_formatter/currency_formatter.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:local_auth/local_auth.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:moonwallet/screens/dashboard/private/private_key_screen.dart';
import 'package:moonwallet/screens/dashboard/settings/change_colors.dart';
import 'package:moonwallet/service/number_formatter.dart';
import 'package:moonwallet/service/profile_image_manager.dart';
import 'package:moonwallet/service/wallet_saver.dart';
import 'package:moonwallet/types/types.dart';
import 'package:moonwallet/utils/prefs.dart';
import 'package:moonwallet/widgets/avatar_modal.dart';
import 'package:moonwallet/widgets/bottom_pin_copy.dart';
import 'package:moonwallet/widgets/crypto_picture.dart';
import 'package:moonwallet/widgets/custom_options.dart';
import 'package:moonwallet/widgets/flowting_modat.dart';
import 'package:moonwallet/widgets/func/ask_password.dart';
import 'package:moonwallet/widgets/snackbar.dart';

import '../../logger/logger.dart';

void showCustomDrawer(
    {required BuildContext context,
    File? profileImage,
    required AppColors colors,
    required List<Crypto> availableCryptos,
    required double totalBalanceUsd,
    required PublicData account,
    required Future<void> Function(PublicData account) deleteWallet,
    required bool canUseBio,
    required Future<void> Function(bool state) updateBioState,
    required Future Function(
            {required PublicData account,
            String? name,
            IconData? icon,
            Color? color})
        editWallet,
    required Future<void> Function(File file) refreshProfile}) {
  bool canEditWalletName = false;
  TextEditingController textController = TextEditingController();
  String walletName = account.walletName;
  File? currentImage = profileImage;
  final ImagePicker picker = ImagePicker();
  final ImageStorageManager storageManager = ImageStorageManager();
  String newPassword = "";
  String confirmPassword = "";
  bool useBio = canUseBio;

  String formatUsd(String value) {
    return NumberFormatter().formatUsd(value: value);
  }

 
  Future<File?> pickImage() async {
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      return File(image.path);
    } else {
      return null;
    }
  }

  Future<void> pickProfileImage() async {
    log("Picking profile image");
    final File? image = await pickImage();
    if (image != null) {
      currentImage = image;
    }
  }

  showAvatarModalBottomSheet(
      avatarChild: currentImage != null
          ? Image.file(
              currentImage ?? File(""),
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
      profileImage: currentImage,
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
                                walletName,
                                style: GoogleFonts.roboto(
                                    color: colors.textColor.withOpacity(0.7),
                                    fontSize: 17,
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
                                    style: GoogleFonts.roboto(
                                        color:
                                            colors.textColor.withOpacity(0.8)),
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
                                            walletName = textController.text;
                                          });
                                        } else {
                                          showCustomSnackBar(
                                              context: context,
                                              message: "Can't edit the wallet",
                                              primaryColor: colors.primaryColor,
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
                              "\$${(formatUsd(totalBalanceUsd.toString()))}",
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
                          } else if (i == 1) {
                            showFloatingModalBottomSheet(
                                backgroundColor: colors.primaryColor,
                                context: context,
                                builder: (ctx) {
                                  return StatefulBuilder(
                                      builder: (ctx, setFState) {
                                    return ListView(
                                      shrinkWrap: true,
                                      children: [
                                        Material(
                                            color: Colors.transparent,
                                            child: InkWell(
                                              onTap: () async {
                                                await pickProfileImage();
                                                setFState(() {});
                                                st(() {});
                                                await refreshProfile(
                                                    currentImage!);
                                              },
                                              child: Padding(
                                                padding:
                                                    const EdgeInsets.all(10),
                                                child: Align(
                                                    alignment: Alignment.center,
                                                    child: Stack(
                                                      children: [
                                                        ClipRRect(
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(50),
                                                          child: currentImage !=
                                                                  null
                                                              ? Image.file(
                                                                  currentImage ??
                                                                      File(""),
                                                                  width: 70,
                                                                  height: 70,
                                                                  fit: BoxFit
                                                                      .cover,
                                                                )
                                                              : Image.asset(
                                                                  "assets/pro/image.png",
                                                                  width: 70,
                                                                  height: 70,
                                                                  fit: BoxFit
                                                                      .cover,
                                                                ),
                                                        ),
                                                        Positioned(
                                                          left: 25,
                                                          top: 25,
                                                          child: Icon(
                                                            Icons.camera,
                                                            color: Colors.white,
                                                          ),
                                                        )
                                                      ],
                                                    )),
                                              ),
                                            )),
                                        LayoutBuilder(builder: (ctx, c) {
                                          return Align(
                                            alignment: Alignment.center,
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              spacing: 5,
                                              children: [
                                                SizedBox(
                                                  width: c.maxWidth * 0.55,
                                                  child: ElevatedButton(
                                                      onPressed: () async {
                                                        if (currentImage !=
                                                            null) {
                                                          final res =
                                                              await storageManager
                                                                  .saveData(
                                                                      image:
                                                                          currentImage!);
                                                          if (res) {
                                                            setFState(() {});
                                                            st(() {});
                                                            Navigator.pop(ctx);
                                                          }
                                                        }
                                                      },
                                                      style: ElevatedButton.styleFrom(
                                                          shape: RoundedRectangleBorder(
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          8)),
                                                          padding:
                                                              const EdgeInsets
                                                                  .symmetric(
                                                                  vertical: 0),
                                                          backgroundColor:
                                                              colors
                                                                  .themeColor),
                                                      child: Text(
                                                        "Save",
                                                        style: GoogleFonts.roboto(
                                                            color: colors
                                                                .primaryColor),
                                                      )),
                                                ),
                                                SizedBox(
                                                  width: c.maxWidth * 0.3,
                                                  child: ElevatedButton(
                                                      onPressed: () {
                                                        Navigator.pop(ctx);
                                                      },
                                                      style: ElevatedButton.styleFrom(
                                                          shape: RoundedRectangleBorder(
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          8)),
                                                          padding:
                                                              const EdgeInsets
                                                                  .symmetric(
                                                                  vertical: 0),
                                                          elevation: 0,
                                                          backgroundColor:
                                                              Colors
                                                                  .transparent,
                                                          side: BorderSide(
                                                              width: 2,
                                                              color: colors
                                                                  .redColor)),
                                                      child: Text(
                                                        "Cancel",
                                                        style:
                                                            GoogleFonts.roboto(
                                                                color: colors
                                                                    .redColor),
                                                      )),
                                                )
                                              ],
                                            ),
                                          );
                                        })
                                      ],
                                    );
                                  });
                                });
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
                        onTap: (i) async {
                          if (i == 0) {
                            if (account.isWatchOnly) {
                              showCustomSnackBar(
                                  context: context,
                                  message:
                                      "A watch-only wallet does not store private data",
                                  primaryColor: colors.primaryColor,
                                  colors: colors);
                              return;
                            }
                            final password = await askPassword(
                                context: context, colors: colors);
                            if (password.isNotEmpty) {
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => PrivateKeyScreen(
                                            password: password,
                                            walletId: account.keyId,
                                          )));
                            }
                          } else if (i == 1) {
                            final password = await askPassword(
                                context: context,
                                colors: colors,
                                title: "Old Password");
                            if (password.isEmpty) {
                              showCustomSnackBar(
                                  context: context,
                                  message: "Incorrect password",
                                  primaryColor: colors.primaryColor,
                                  colors: colors);
                              return;
                            }

                            final res = await showPinModalBottomSheet(
                                canApplyBlur: true,
                                context: context,
                                handleSubmit: (password) async {
                                  if (newPassword.isEmpty) {
                                    newPassword = password;
                                    return PinSubmitResult(
                                        success: true,
                                        repeat: true,
                                        newTitle: "Repeat Password");
                                  } else {
                                    if (newPassword.trim() != password.trim()) {
                                      newPassword = "";
                                      return PinSubmitResult(
                                          success: false,
                                          repeat: true,
                                          newTitle: "New password",
                                          error: "Password does not match");
                                    } else {
                                      confirmPassword = newPassword;
                                      return PinSubmitResult(
                                          success: true, repeat: false);
                                    }
                                  }
                                },
                                colors: colors,
                                title: "New password");

                            if (res) {
                              if (password == confirmPassword) {
                                showCustomSnackBar(
                                    context: context,
                                    message:
                                        "The old password and the new one are the same",
                                    primaryColor: colors.primaryColor,
                                    colors: colors);
                                newPassword = "";
                                confirmPassword = "";
                              } else {
                                final walletManager = WalletSaver();
                                final result = await walletManager
                                    .changePassword(password, confirmPassword);
                                if (!result) {
                                  showCustomSnackBar(
                                      context: context,
                                      message: "Failed to change password",
                                      primaryColor: colors.primaryColor,
                                      colors: colors);
                                  newPassword = "";
                                  confirmPassword = "";
                                } else {
                                  showCustomSnackBar(
                                      icon: Icons.check,
                                      iconColor: colors.greenColor,
                                      context: context,
                                      message: "Password changed successfully",
                                      primaryColor: colors.primaryColor,
                                      colors: colors);
                                }
                              }
                            }
                          }
                        }),
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
                              title: "Enable biometric",
                              icon: Icon(
                                LucideIcons.fingerprint,
                                color: colors.textColor.withOpacity(0.7),
                                size: 20,
                              ),
                              trailing: Switch(
                                  value: canUseBio,
                                  onChanged: (v) async {
                                    if (v) {
                                      final LocalAuthentication auth =
                                          LocalAuthentication();
                                      final bool canAuthenticateWithBiometrics =
                                          await auth.canCheckBiometrics;
                                      final bool canAuthenticate =
                                          canAuthenticateWithBiometrics ||
                                              await auth.isDeviceSupported();

                                      if (canAuthenticate) {
                                        try {
                                          final bool didAuthenticate =
                                              await auth.authenticate(
                                                  localizedReason:
                                                      "Enabled to use biometric authentication");
                                          if (didAuthenticate) {
                                            final res =
                                                await PublicDataManager()
                                                    .saveDataInPrefs(
                                                        data: v ? "on" : "off",
                                                        key: "BioStatus");
                                          showCustomSnackBar(context: context, message: "Enabled", primaryColor: colors.primaryColor, colors: colors, icon: Icons.check_circle, iconColor: colors.themeColor);

                                            if (res) {

                                              st(() {
                                                canUseBio = v;
                                              });
                                            await  updateBioState(v);

                                            }
                                          }
                                        } catch (e) {
                                          showCustomSnackBar(
                                            colors: colors,
                                            primaryColor: colors.primaryColor,
                                            icon: Icons.error,
                                            iconColor: Colors.red,
                                            context: context,
                                            message: "Failed : $e",
                                          );
                                          logError(e.toString());
                                        }
                                      }
                                    } else {
                                      final res =
                                              await PublicDataManager()
                                                  .saveDataInPrefs(
                                                        data:  "off",
                                                        key: "BioStatus");
                                          if (res) {
                                              st(() {
                                                canUseBio = v;
                                              });

                                            await  updateBioState(v);
                                          }
                                        }
  
                                    
                                  }),
                              color: colors.textColor,
                              titleStyle: GoogleFonts.roboto(
                                  color: colors.textColor, fontSize: 14)),
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
                        onTap: (i) {
                          if (i == 1) {
                            deleteWallet(account);
                          }
                        })
                  ],
                ),
              ));
        });
      });
}
