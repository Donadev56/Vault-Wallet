import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:moonwallet/logger/logger.dart';
import 'package:moonwallet/types/types.dart';
import 'package:moonwallet/widgets/flowting_modat.dart';
import 'package:moonwallet/widgets/profile_placeholder.dart';

Future<File>? showProfileImagePicker({
  required AppColors colors,
  required BuildContext context,
  required File? currentImage,
}) {
  File? image = currentImage;

  Future<File?> pickImage() async {
    final ImagePicker picker = ImagePicker();

    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      return File(image.path);
    } else {
      return null;
    }
  }

  Future<File?> pickProfileImage() async {
    log("Picking profile image");
    final File? img = await pickImage();
    return img;
  }

  final file = showFloatingModalBottomSheet<File>(
      backgroundColor: colors.primaryColor,
      context: context,
      builder: (ctx) {
        final textTheme = TextTheme.of(context);
        return StatefulBuilder(builder: (ctx, setFState) {
          return ListView(
            shrinkWrap: true,
            children: [
              Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () async {
                      final pickedImage = await pickProfileImage();
                      if (pickedImage == null) {
                        return;
                      }
                      setFState(() {
                        image = pickedImage;
                      });
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: Align(
                          alignment: Alignment.center,
                          child: Stack(
                            children: [
                              ClipRRect(
                                  borderRadius: BorderRadius.circular(50),
                                  child: image != null
                                      ? Image.file(
                                          image ?? File(""),
                                          width: 70,
                                          height: 70,
                                          fit: BoxFit.cover,
                                        )
                                      : ProfilePlaceholder(colors: colors)),
                              Positioned(
                                  left: 16,
                                  top: 16,
                                  child: SizedBox(
                                    width: 40,
                                    height: 40,
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(50),
                                      child: BackdropFilter(
                                        filter: ImageFilter.blur(
                                            sigmaX: 8, sigmaY: 8),
                                        child: Icon(
                                          LucideIcons.camera,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ))
                            ],
                          )),
                    ),
                  )),
              LayoutBuilder(builder: (ctx, c) {
                return Align(
                  alignment: Alignment.center,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    spacing: 5,
                    children: [
                      SizedBox(
                        width: c.maxWidth * 0.55,
                        child: ElevatedButton(
                            onPressed: () async {
                              if (image != null) {
                                Navigator.pop(context, image);
                                setFState(() {});
                              }
                            },
                            style: ElevatedButton.styleFrom(
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8)),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 0),
                                backgroundColor: colors.themeColor),
                            child: Text(
                              "Save",
                              style: textTheme.bodySmall
                                  ?.copyWith(color: colors.primaryColor),
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
                                    borderRadius: BorderRadius.circular(8)),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 0),
                                elevation: 0,
                                backgroundColor: Colors.transparent,
                                side: BorderSide(
                                    width: 2, color: colors.redColor)),
                            child: Text(
                              "Cancel",
                              style: textTheme.bodySmall
                                  ?.copyWith(color: colors.redColor),
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

  return file;
}
