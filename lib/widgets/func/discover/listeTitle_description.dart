import 'package:flutter/material.dart';
import 'package:moonwallet/types/types.dart';
import 'package:moonwallet/widgets/func/discover/network_image.dart';

class ListTitleDescription extends StatelessWidget {
  final String imageUrl;
  final String title;
  final String description;
  final DoubleFactor fontSizeOf;
  final DoubleFactor imageSizeOf;

  final void Function()? onTap;
  final AppColors colors;

  const ListTitleDescription(
      {super.key,
      required this.description,
      required this.imageUrl,
      required this.title,
      required this.fontSizeOf,
      this.onTap,
      required this.colors,
      required this.imageSizeOf});

  @override
  Widget build(BuildContext context) {
    final textTheme = TextTheme.of(context);

    return ListTile(
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      visualDensity: VisualDensity.compact,
      leading: ClipRRect(
          borderRadius: BorderRadius.circular(50),
          child: CustomNetworkImage(
              url: imageUrl,
              size: 30,
              imageSizeOf: imageSizeOf,
              colors: colors)),
      title: Text(
        title,
        style: textTheme.bodyMedium
            ?.copyWith(fontSize: fontSizeOf(17), fontWeight: FontWeight.w500),
      ),
      subtitle: Text(
        description,
        overflow: TextOverflow.ellipsis,
        style: textTheme.bodyMedium?.copyWith(
          fontSize: fontSizeOf(12),
          color: colors.textColor.withValues(alpha: 0.7),
        ),
      ),
    );
  }
}
