import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

import '../../logger/logger.dart';

class ImageStorageManager {
  Future<bool> saveImage(
      {required File image, required String fileName}) async {
    try {
      final Directory appDocDir = await getApplicationDocumentsDirectory();

      final String moonImagesPath = path.join(appDocDir.path, "moon", "images");
      final Directory moonImagesDir = Directory(moonImagesPath);

      if (!await moonImagesDir.exists()) {
        await moonImagesDir.create(recursive: true);
      }

      final String profileFilePath = path.join(moonImagesPath, fileName);
      await image.copy(profileFilePath);

      return true;
    } catch (e) {
      log("Error saving images: $e");
      return false;
    }
  }

  Future<File?> getProfileImage({required String fileName}) async {
    try {
      // Retrieve the app's documents directory.
      final Directory appDocDir = await getApplicationDocumentsDirectory();
      final String moonImagesPath = path.join(appDocDir.path, "moon", "images");

      // Define file paths for the profile and background images.
      final String profileFilePath = path.join(moonImagesPath, fileName);

      // Check if the profile image exists and update the state.
      final File profileImageFile = File(profileFilePath);
      if (await profileImageFile.exists()) {
        return profileImageFile;
      }

      return null;
    } catch (e) {
      log("Error loading data: $e");
      return null;
    }
  }
}
