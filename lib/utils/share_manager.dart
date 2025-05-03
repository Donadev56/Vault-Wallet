import 'dart:typed_data';
import 'dart:ui';

import 'package:moonwallet/logger/logger.dart';
import 'package:share_plus/share_plus.dart';

class ShareManager {
  Future<void> shareText(
      {required String text,
      required String subject,
      VoidCallback? onError}) async {
    try {
      Share.share(text, subject: subject);
    } catch (e) {
      logError(e.toString());
      if (onError != null) {
        onError();
      }
    }
  }

  Future<void> shareUri({required String url, VoidCallback? onError}) async {
    try {
      final uri = Uri.tryParse(url);
      if (uri == null) {
        throw "Invalid Url";
      }
      await Share.shareUri(uri);
    } catch (e) {
      logError(e.toString());
      if (onError != null) {
        onError();
      }
    }
  }

  Future<void> share(
      {required List<XFile> files,
      String? text,
      String? subject,
      VoidCallback? onError}) async {
    try {
      if (files.isEmpty) {
        throw "Files are required";
      }
      await Share.shareXFiles(files, subject: subject, text: text);
    } catch (e) {
      logError(e.toString());
      if (onError != null) {
        onError();
      }
    }
  }

  Future<void> shareQrImage(ByteData qr) async {
    try {
      final xfile = XFile.fromData(
        qr.buffer.asUint8List(),
        mimeType: 'image/png',
        name: 'image.png',
      );

      await share(files: [xfile]);
    } catch (e) {
      logError(e.toString());
    }
  }
}
