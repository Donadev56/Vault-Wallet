import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_svg/svg.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:moonwallet/logger/logger.dart';
import 'package:moonwallet/service/db/image_storage.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import 'package:path/path.dart' as p;

class CustomLocalImage extends HookConsumerWidget {
  final String url;
  final BoxFit? fit;
  final double? width;
  final double? height;
  final Alignment alignment;
  final Widget Function(BuildContext, Object, StackTrace?)? errorBuilder;
  final Widget errorWidget;
  final bool? isSvgImage;

  const CustomLocalImage(this.url,
      {super.key,
      this.fit,
      this.height,
      this.width,
      this.alignment = Alignment.center,
      this.errorBuilder,
      this.isSvgImage,
      required this.errorWidget});

  get path => null;

  @override
  Widget build(BuildContext context, ref) {
    final imageFile = useState<File?>(null);

    Future<void> loadImage() async {
      try {
        final imageStorage = ImageStorageManager();
        final savedImage = await imageStorage.getSavedImage(fileName: url);
        if (savedImage == null) {
          final imageResponse = await http.get(Uri.parse(url));
          if (imageResponse.statusCode == 200) {
            final imageBytes = imageResponse.bodyBytes;
            final directory = await getTemporaryDirectory();
            log("Url $url");
            final ext = p.extension(Uri.parse(url).path);

            final filename = '${Uuid().v4()}$ext';
            final filePath = p.join(directory.path, filename);

            final file = File(filePath);
            await file.writeAsBytes(imageBytes);
            imageStorage.saveImage(image: file, fileName: url);
            imageFile.value = file;
          }
        }

        imageFile.value = savedImage;
      } catch (e) {
        logError(e.toString());
      }
    }

    useEffect(() {
      loadImage();
      return null;
    }, []);
    if (imageFile.value == null) {
      return errorWidget;
    }

    return isSvgImage == true
        ? SvgPicture.file(
            imageFile.value!,
            fit: fit ?? BoxFit.contain,
            width: width,
            height: width,
            alignment: alignment,
            errorBuilder: errorBuilder,
          )
        : Image.file(imageFile.value!,
            fit: fit,
            width: width,
            height: height,
            alignment: alignment,
            errorBuilder: errorBuilder);
  }
}
