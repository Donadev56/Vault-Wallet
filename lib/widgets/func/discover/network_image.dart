import 'package:flutter/material.dart';
import 'package:moonwallet/types/types.dart';
import 'package:moonwallet/widgets/screen_widgets/cached_picture.dart';

class CustomNetworkImage extends StatelessWidget {
  final String url;
  final double size;
  final double placeholderSize;
  final bool cover;
  final DoubleFactor imageSizeOf;
  final AppColors colors;
  const CustomNetworkImage(
      {super.key,
      required this.url,
      this.placeholderSize = 30,
      required this.size,
      this.cover = false,
      required this.imageSizeOf,
      required this.colors});

  @override
  Widget build(BuildContext context) {
    return CachedPicture(
      url,
      placeHolderString: "",
      size: size,
      colors: colors,
      addSecondaryImage: false,
    );
  }
}
