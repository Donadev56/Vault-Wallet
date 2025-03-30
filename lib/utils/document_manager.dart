/*import 'dart:io';

import 'package:moonwallet/logger/logger.dart';
import 'package:path_provider/path_provider.dart';

class DocumentManager {
  Future<String> getDocAppDir() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      return directory.path;
    } catch (e) {
      logError(e.toString());
      return "";
    }
  }

  Future<File?> getFile({required String filePath}) async {
    try {
      final path = await getDocAppDir();
      return File('$path/$filePath');
    } catch (e) {
      logError(e.toString());
      return null;
    }
  }

  Future<bool> writeInAFile(
      {required String data, required String filePath}) async {
    try {
      final file = await getFile(filePath: filePath);
      if (file != null) {
        return true;
      } else {
        logError("An error occurred while getting the file");
        return false;
      }
    } catch (e) {
      logError(e.toString());
      return false;
    }
  }

  Future<String?> readData({required String filePath}) async {
    try {
      final file = await getFile(filePath: filePath);
      if (file != null) {
        String contents = await file.readAsString();
        return contents;
      }
      return null;
    } catch (e) {
      logError(e.toString());
      return null;
    }
  }

  Future<File?> saveFile(
      {required String data, required String filePath}) async {
    try {
      final file = await getFile(filePath: filePath);
      if (file != null) {
        if (!await file.exists()) {
          await file.create(recursive: true);
        }

        return await file.writeAsString(data);
      }
      logError("An error occurred while saving the file");
      return null;
    } catch (e) {
      logError(e.toString());
      return null;
    }
  }
}
*/
