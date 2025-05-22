import 'package:flutter/material.dart';
import 'package:moonwallet/types/types.dart';

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
    return Image.network(
      url,
      width: size,
      height: size,
      fit: cover ? BoxFit.cover : null,
      errorBuilder: (ctx, widget, error) {
        return SizedBox(
          width: imageSizeOf(placeholderSize),
          height: imageSizeOf(placeholderSize),
          child: ColoredBox(color: colors.themeColor),
        );
      },
    );
  }
}
