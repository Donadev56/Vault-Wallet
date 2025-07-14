import 'package:flutter/material.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:moonwallet/types/types.dart';
import 'package:moonwallet/widgets/func/discover/network_image.dart';

class HistoryListTitle extends StatelessWidget {
  final AppColors colors;
  final DoubleFactor roundedOf;
  final DoubleFactor imageSizeOf;
  final DoubleFactor fontSizeOf;
  final String link;

  final String title;
  final void Function()? onDeleteClick;
  final void Function()? onTap;
  const HistoryListTitle(
      {super.key,
      required this.fontSizeOf,
      required this.imageSizeOf,
      required this.roundedOf,
      required this.link,
      required this.title,
      required this.colors,
      this.onDeleteClick,
      this.onTap});

  @override
  Widget build(BuildContext context) {
    final textTheme = TextTheme.of(context);
    return ListTile(
        visualDensity: VisualDensity.compact,
        leading: ClipRRect(
            borderRadius: BorderRadius.circular(roundedOf(50)),
            child: Container(
                decoration: BoxDecoration(
                    color: colors.grayColor.withValues(alpha: 0.5)),
                child: UnCachedNetworkImage(
                    size: 20, url: "$link/favicon.ico", colors: colors))),
        title: Text(
          title,
          style: textTheme.bodyMedium?.copyWith(
            fontSize: fontSizeOf(14),
            fontWeight: FontWeight.w400,
            color: colors.textColor,
          ),
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
        trailing: IconButton(
            onPressed: onDeleteClick,
            icon: Icon(
              FeatherIcons.x,
              color: colors.textColor.withOpacity(0.7),
              size: 20,
            )),
        onTap: onTap);
  }
}
