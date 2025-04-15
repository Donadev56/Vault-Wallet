// ignore_for_file: deprecated_member_use, use_build_context_synchronously

import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:local_auth/local_auth.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:moonwallet/custom/web3_webview/lib/utils/loading.dart';
import 'package:moonwallet/notifiers/providers.dart';
import 'package:moonwallet/screens/dashboard/wallet_actions/private/private_key_screen.dart';
import 'package:moonwallet/screens/dashboard/settings/change_colors.dart';
import 'package:moonwallet/service/number_formatter.dart';
import 'package:moonwallet/service/profile_image_manager.dart';
import 'package:moonwallet/service/wallet_saver.dart';
import 'package:moonwallet/service/web3.dart';
import 'package:moonwallet/types/types.dart';
import 'package:moonwallet/utils/prefs.dart';
import 'package:moonwallet/widgets/avatar_modal.dart';
import 'package:moonwallet/widgets/bottom_pin_copy.dart';
import 'package:moonwallet/widgets/crypto_picture.dart';
import 'package:moonwallet/widgets/custom_options.dart';
import 'package:moonwallet/widgets/flowting_modat.dart';
import 'package:moonwallet/widgets/func/ask_password.dart';
import 'package:moonwallet/widgets/func/snackbar.dart';
import 'package:simple_gesture_detector/simple_gesture_detector.dart';

import '../../logger/logger.dart';

void showCustomDrawer(
    {required BuildContext context,
    File? profileImage,
    required AppColors colors,
    required List<Crypto> availableCryptos,
    required double totalBalanceUsd,
    required bool canUseBio,
    required void Function(bool state) updateBioState,
    required bool isHidden,
    required void Function(File file) refreshProfile}) {
  bool canEditWalletName = false;

  TextEditingController textController = TextEditingController();
  File? currentImage = profileImage;
  final ImagePicker picker = ImagePicker();
  final ImageStorageManager storageManager = ImageStorageManager();
  List<PublicData> accounts = [];
  PublicData? account;

  String newPassword = "";
  String confirmPassword = "";

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
        notifySuccess(String message) => showCustomSnackBar(
            context: ctx,
            message: message,
            colors: colors,
            type: MessageType.success);
        notifyError(String message) => showCustomSnackBar(
            context: ctx,
            message: message,
            colors: colors,
            type: MessageType.error);

        final textTheme = Theme.of(ctx).textTheme;

        return StatefulBuilder(builder: (ctx, st) {
          return Consumer(
            builder: (ctx, ref, child) {
              final accountAsync = ref.watch(currentAccountProvider);
              accountAsync.whenData((data) {
                st(() {
                  account = data;
                });
              });
              final accountsProvider =
                  ref.watch(accountsNotifierProvider.notifier);
              final accountsAsync = ref.watch(accountsNotifierProvider);

              accountsAsync.whenData((data) {
                st(() {
                  accounts = data;
                });
              });

              Future<bool> deleteWallet(String walletId) async {
                try {
                  if (accounts.isEmpty) {
                    throw ("No account found");
                  }
                  final password =
                      await askPassword(context: ctx, colors: colors);
                  final accountToRemove =
                      accounts.where((acc) => acc.keyId == walletId).first;
                  if (password.isNotEmpty) {
                    // validateThePassword
                    final result = await accountsProvider.walletSaver
                        .getDecryptedData(password);
                    if (result == null) {
                      throw ("Invalid password");
                    }
                    final deleteResult = await accountsProvider
                        .deleteWallet(accountToRemove)
                        .withLoading(ctx, colors);
                    if (deleteResult) {
                      notifySuccess("Account deleted successfully");
                      Navigator.pop(ctx);
                      return true;
                    } else {
                      throw ("Failed to delete account");
                    }
                  } else {
                    throw ("Password is required");
                  }
                } catch (e) {
                  logError(e.toString());
                  notifyError(e.toString());
                  return false;
                }
              }

              Future<bool> editWallet(
                  {required PublicData account,
                  Color? color,
                  IconData? icon,
                  String? name}) async {
                try {
                  final result = await accountsProvider
                      .editWallet(
                        account: account,
                        name: name,
                        icon: icon,
                        color: color,
                      )
                      .withLoading(ctx, colors);
                  if (result) {
                    log("Account updated successfully");

                    return true;
                  } else {
                    throw ("Failed to update account");
                  }
                } catch (e) {
                  logError(e.toString());
                  notifyError(e.toString());
                  return false;
                }
              }

              return SimpleGestureDetector(
                  onHorizontalSwipe: (direction) {
                    if (direction == SwipeDirection.left) {
                      Navigator.pop(ctx);
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
                                        account?.walletName ?? "Not found",
                                        style: textTheme.bodySmall?.copyWith(
                                            color: colors.textColor
                                                .withOpacity(0.7),
                                            fontSize: 17,
                                            fontWeight: FontWeight.bold),
                                      ),
                                      IconButton(
                                          onPressed: () {
                                            st(() {
                                              textController.text =
                                                  account?.walletName ?? "";
                                              canEditWalletName = true;
                                            });
                                          },
                                          icon: Icon(
                                            LucideIcons.pencilLine,
                                            color: colors.textColor
                                                .withOpacity(0.7),
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
                                            style: textTheme.bodySmall
                                                ?.copyWith(
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
                                                    account: account!,
                                                    name: textController.text);
                                                if (res) {
                                                  st(() {
                                                    canEditWalletName = false;
                                                    //   walletName =
                                                    //    textController.text;
                                                  });
                                                } else {
                                                  notifyError(
                                                      "Can't edit the wallet");
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
                                      !isHidden
                                          ? "\$${(formatUsd(totalBalanceUsd.toString()))}"
                                          : "***",
                                      style: textTheme.bodySmall?.copyWith(
                                          color: colors.textColor,
                                          fontSize: 30,
                                          fontWeight: FontWeight.bold),
                                    ),
                                    Text(
                                      "Balance",
                                      style: textTheme.bodySmall?.copyWith(
                                        color:
                                            colors.textColor.withOpacity(0.6),
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
                                style: textTheme.bodySmall?.copyWith(
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
                                spaceNameStyle: textTheme.bodySmall?.copyWith(
                                      color: colors.textColor,
                                    ) ??
                                    GoogleFonts.roboto(color: colors.textColor),
                                options: [
                                  Option(
                                      tileColor: colors.secondaryColor
                                          .withOpacity(0.5),
                                      title: "Change App Theme",
                                      icon: Icon(
                                        LucideIcons.palette,
                                        color:
                                            colors.textColor.withOpacity(0.7),
                                        size: 20,
                                      ),
                                      trailing: Icon(Icons.chevron_right,
                                          color: colors.textColor
                                              .withOpacity(0.5)),
                                      color: colors.secondaryColor,
                                      titleStyle: textTheme.bodySmall?.copyWith(
                                          color: colors.textColor,
                                          fontSize: 14)),
                                  Option(
                                      tileColor: colors.secondaryColor
                                          .withOpacity(0.5),
                                      title: "Edit profile picture",
                                      icon: Icon(
                                        LucideIcons.user,
                                        color:
                                            colors.textColor.withOpacity(0.7),
                                        size: 20,
                                      ),
                                      trailing: Icon(
                                        Icons.chevron_right,
                                        color:
                                            colors.textColor.withOpacity(0.5),
                                      ),
                                      color: colors.secondaryColor,
                                      titleStyle: textTheme.bodySmall?.copyWith(
                                          color: colors.textColor,
                                          fontSize: 14))
                                ],
                                onTap: (i) {
                                  if (i == 0) {
                                    Navigator.push(
                                        ctx,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              ChangeThemeView(),
                                        ));
                                  } else if (i == 1) {
                                    showFloatingModalBottomSheet(
                                        backgroundColor: colors.primaryColor,
                                        context: ctx,
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
                                                        refreshProfile(
                                                            currentImage!);
                                                      },
                                                      child: Padding(
                                                        padding:
                                                            const EdgeInsets
                                                                .all(10),
                                                        child: Align(
                                                            alignment: Alignment
                                                                .center,
                                                            child: Stack(
                                                              children: [
                                                                ClipRRect(
                                                                  borderRadius:
                                                                      BorderRadius
                                                                          .circular(
                                                                              50),
                                                                  child: currentImage !=
                                                                          null
                                                                      ? Image
                                                                          .file(
                                                                          currentImage ??
                                                                              File(""),
                                                                          width:
                                                                              70,
                                                                          height:
                                                                              70,
                                                                          fit: BoxFit
                                                                              .cover,
                                                                        )
                                                                      : Image
                                                                          .asset(
                                                                          "assets/pro/image.png",
                                                                          width:
                                                                              70,
                                                                          height:
                                                                              70,
                                                                          fit: BoxFit
                                                                              .cover,
                                                                        ),
                                                                ),
                                                                Positioned(
                                                                    left: 16,
                                                                    top: 16,
                                                                    child:
                                                                        SizedBox(
                                                                      width: 40,
                                                                      height:
                                                                          40,
                                                                      child:
                                                                          ClipRRect(
                                                                        borderRadius:
                                                                            BorderRadius.circular(50),
                                                                        child:
                                                                            BackdropFilter(
                                                                          filter: ImageFilter.blur(
                                                                              sigmaX: 8,
                                                                              sigmaY: 8),
                                                                          child:
                                                                              Icon(
                                                                            LucideIcons.camera,
                                                                            color:
                                                                                Colors.white,
                                                                          ),
                                                                        ),
                                                                      ),
                                                                    ))
                                                              ],
                                                            )),
                                                      ),
                                                    )),
                                                LayoutBuilder(
                                                    builder: (ctx, c) {
                                                  return Align(
                                                    alignment: Alignment.center,
                                                    child: Row(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .center,
                                                      spacing: 5,
                                                      children: [
                                                        SizedBox(
                                                          width:
                                                              c.maxWidth * 0.55,
                                                          child: ElevatedButton(
                                                              onPressed:
                                                                  () async {
                                                                if (currentImage !=
                                                                    null) {
                                                                  final res = await storageManager
                                                                      .saveData(
                                                                          image:
                                                                              currentImage!);
                                                                  if (res) {
                                                                    setFState(
                                                                        () {});
                                                                    st(() {});
                                                                    Navigator
                                                                        .pop(
                                                                            ctx);
                                                                  }
                                                                }
                                                              },
                                                              style: ElevatedButton.styleFrom(
                                                                  shape: RoundedRectangleBorder(
                                                                      borderRadius:
                                                                          BorderRadius.circular(
                                                                              8)),
                                                                  padding: const EdgeInsets
                                                                      .symmetric(
                                                                      vertical:
                                                                          0),
                                                                  backgroundColor:
                                                                      colors
                                                                          .themeColor),
                                                              child: Text(
                                                                "Save",
                                                                style: textTheme
                                                                    .bodySmall
                                                                    ?.copyWith(
                                                                        color: colors
                                                                            .primaryColor),
                                                              )),
                                                        ),
                                                        SizedBox(
                                                          width:
                                                              c.maxWidth * 0.3,
                                                          child: ElevatedButton(
                                                              onPressed: () {
                                                                Navigator.pop(
                                                                    ctx);
                                                              },
                                                              style: ElevatedButton.styleFrom(
                                                                  shape: RoundedRectangleBorder(
                                                                      borderRadius:
                                                                          BorderRadius.circular(
                                                                              8)),
                                                                  padding: const EdgeInsets
                                                                      .symmetric(
                                                                      vertical:
                                                                          0),
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
                                                                style: textTheme
                                                                    .bodySmall
                                                                    ?.copyWith(
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
                                spaceNameStyle: textTheme.bodySmall?.copyWith(
                                      color: colors.textColor,
                                    ) ??
                                    GoogleFonts.roboto(color: colors.textColor),
                                options: [
                                  Option(
                                      tileColor: colors.secondaryColor
                                          .withOpacity(0.5),
                                      title: "View private data",
                                      icon: Icon(
                                        LucideIcons.key,
                                        color:
                                            colors.textColor.withOpacity(0.7),
                                        size: 20,
                                      ),
                                      trailing: Icon(Icons.chevron_right,
                                          color: colors.textColor
                                              .withOpacity(0.5)),
                                      color: colors.secondaryColor,
                                      titleStyle: textTheme.bodySmall?.copyWith(
                                          color: colors.textColor,
                                          fontSize: 14)),
                                  Option(
                                      tileColor: colors.secondaryColor
                                          .withOpacity(0.5),
                                      title: "Change password",
                                      icon: Icon(
                                        LucideIcons.keySquare,
                                        color:
                                            colors.textColor.withOpacity(0.7),
                                        size: 20,
                                      ),
                                      trailing: Icon(
                                        Icons.chevron_right,
                                        color:
                                            colors.textColor.withOpacity(0.5),
                                      ),
                                      color: colors.secondaryColor,
                                      titleStyle: textTheme.bodySmall?.copyWith(
                                          color: colors.textColor,
                                          fontSize: 14))
                                ],
                                onTap: (i) async {
                                  if (i == 0) {
                                    if (account!.isWatchOnly) {
                                      notifyError(
                                          "A watch-only wallet does not store private data");

                                      return;
                                    }
                                    final password = await askPassword(
                                        context: ctx, colors: colors);
                                    if (password.isNotEmpty) {
                                      Navigator.push(
                                          ctx,
                                          MaterialPageRoute(
                                              builder: (context) =>
                                                  PrivateKeyScreen(
                                                    password: password,
                                                    walletId: account!.keyId,
                                                  )));
                                    }
                                  } else if (i == 1) {
                                    final password = await askPassword(
                                        context: ctx,
                                        colors: colors,
                                        title: "Old Password");
                                    if (password.isEmpty) {
                                      notifyError("Incorrect password");
                                      return;
                                    }

                                    final res = await showPinModalBottomSheet(
                                        canApplyBlur: true,
                                        context: ctx,
                                        handleSubmit: (password) async {
                                          if (newPassword.isEmpty) {
                                            newPassword = password;
                                            return PinSubmitResult(
                                                success: true,
                                                repeat: true,
                                                newTitle: "Repeat Password");
                                          } else {
                                            if (newPassword.trim() !=
                                                password.trim()) {
                                              newPassword = "";
                                              return PinSubmitResult(
                                                  success: false,
                                                  repeat: true,
                                                  newTitle: "New password",
                                                  error:
                                                      "Password does not match");
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
                                        notifyError(
                                            "The old password and the new one are the same");

                                        newPassword = "";
                                        confirmPassword = "";
                                      } else {
                                        final walletManager = WalletSaver();
                                        final result =
                                            await walletManager.changePassword(
                                                password, confirmPassword);
                                        if (!result) {
                                          notifyError(
                                              "Failed to change password");
                                          newPassword = "";
                                          confirmPassword = "";
                                        } else {
                                          notifySuccess(
                                              "Password changed successfully");
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
                                spaceNameStyle: textTheme.bodyMedium?.copyWith(
                                      color: colors.textColor,
                                    ) ??
                                    GoogleFonts.roboto(color: colors.textColor),
                                options: [
                                  Option(
                                      title: "Enable biometric",
                                      icon: Icon(
                                        LucideIcons.fingerprint,
                                        color:
                                            colors.textColor.withOpacity(0.7),
                                        size: 20,
                                      ),
                                      trailing: Switch(
                                          value: canUseBio,
                                          onChanged: (v) async {
                                            if (v) {
                                              final LocalAuthentication auth =
                                                  LocalAuthentication();
                                              final bool
                                                  canAuthenticateWithBiometrics =
                                                  await auth.canCheckBiometrics;
                                              final bool canAuthenticate =
                                                  canAuthenticateWithBiometrics ||
                                                      await auth
                                                          .isDeviceSupported();

                                              if (canAuthenticate) {
                                                try {
                                                  final web3manager =
                                                      Web3Manager();

                                                  String userPassword = "";
                                                  int attempts = 0;

                                                  final result =
                                                      await showPinModalBottomSheet(
                                                          colors: colors,
                                                          context: ctx,
                                                          handleSubmit:
                                                              (password) async {
                                                            final savedPassword =
                                                                await web3manager
                                                                    .getSavedPassword();
                                                            if (password
                                                                    .trim() !=
                                                                savedPassword) {
                                                              attempts++;
                                                              if (attempts >=
                                                                  3) {
                                                                notifyError(
                                                                    "Too many attempts");
                                                                attempts = 0;
                                                                return PinSubmitResult(
                                                                  success:
                                                                      false,
                                                                  repeat: false,
                                                                );
                                                              }
                                                              return PinSubmitResult(
                                                                  success:
                                                                      false,
                                                                  repeat: true,
                                                                  error:
                                                                      "Invalid password",
                                                                  newTitle:
                                                                      "Try again");
                                                            } else {
                                                              userPassword =
                                                                  password
                                                                      .trim();

                                                              return PinSubmitResult(
                                                                  success: true,
                                                                  repeat:
                                                                      false);
                                                            }
                                                          },
                                                          title:
                                                              "Enter Password");
                                                  if (result) {
                                                    final data =
                                                        await WalletSaver()
                                                            .getDecryptedData(
                                                                userPassword);
                                                    if (data == null ||
                                                        data.isEmpty) {
                                                      throw Exception(
                                                          "Wrong password");
                                                    }
                                                    final bool didAuthenticate =
                                                        await auth.authenticate(
                                                            localizedReason:
                                                                "Enabled to use biometric authentication");

                                                    if (didAuthenticate) {
                                                      final res =
                                                          await PublicDataManager()
                                                              .saveDataInPrefs(
                                                                  data: v
                                                                      ? "on"
                                                                      : "off",
                                                                  key:
                                                                      "BioStatus");
                                                      notifySuccess("Enabled");

                                                      if (res) {
                                                        st(() {
                                                          canUseBio = v;
                                                        });
                                                        updateBioState(v);
                                                      }
                                                    }
                                                  }
                                                } catch (e) {
                                                  notifyError("Failed : $e");

                                                  logError(e.toString());
                                                }
                                              }
                                            } else {
                                              final res =
                                                  await PublicDataManager()
                                                      .saveDataInPrefs(
                                                          data: "off",
                                                          key: "BioStatus");
                                              if (res) {
                                                st(() {
                                                  canUseBio = v;
                                                });

                                                updateBioState(v);
                                              }
                                            }
                                          }),
                                      color: colors.textColor,
                                      titleStyle: textTheme.bodySmall?.copyWith(
                                          color: colors.textColor,
                                          fontSize: 14)),
                                  Option(
                                      tileColor:
                                          colors.redColor.withOpacity(0.1),
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
                                      titleStyle: textTheme.bodySmall?.copyWith(
                                          color: colors.redColor, fontSize: 14))
                                ],
                                onTap: (i) {
                                  if (i == 1) {
                                    deleteWallet(account!.keyId);
                                  }
                                })
                          ],
                        ),
                      )));
            },
          );
        });
      });
}
