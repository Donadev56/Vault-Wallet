import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moonwallet/logger/logger.dart';
import 'package:moonwallet/service/db/image_storage.dart';

class ProfileImageNotifier extends AsyncNotifier<File?> {
  final profileName = "userProfile";
  @override
  Future<File?> build() async {
    try {
      final ImageStorageManager storageManager = ImageStorageManager();

      final profileImageFile =
          await storageManager.getProfileImage(fileName: profileName);
      if ((await profileImageFile?.exists()) == true) {
        return profileImageFile;
      }

      return null;
    } catch (e) {
      log("Error loading data: $e");
      return null;
    }
  }

  Future<bool> saveImage(File image) async {
    try {
      final ImageStorageManager storageManager = ImageStorageManager();
      final res =
          await storageManager.saveImage(image: image, fileName: profileName);
      if (res) {
        state = AsyncData(image);
        return true;
      }
      return false;
    } catch (e) {
      logError(e.toString());
      return false;
    }
  }
}
