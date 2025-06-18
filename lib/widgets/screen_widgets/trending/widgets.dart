import 'package:flutter/material.dart';
import 'package:moonwallet/custom/scale_tape/scale.dart';
import 'package:moonwallet/types/types.dart';

class TrendingWidgets {
  static Widget buildIntervalChip(String title,
      {required BuildContext context,
      required AppColors colors,
      required bool isSelected,
      void Function()? onTap,
      required DoubleFactor fontSizeOf}) {
    final textTheme = TextTheme.of(context);
    return Container(
      decoration: BoxDecoration(
          color: isSelected ? colors.secondaryColor : Colors.transparent),
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
          decoration: BoxDecoration(),
          child: Text(
            title,
            style: textTheme.bodyMedium?.copyWith(
                color: colors.textColor.withValues(alpha: 0.7),
                fontSize: fontSizeOf(14),
                fontWeight: FontWeight.w500),
          ),
        ),
      ),
    );
  }

  static Widget buildTag(BuildContext context, AppColors colors, String tag,
      {Color? bgColor, bool? selected}) {
    final textTheme = TextTheme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: bgColor ?? colors.primaryColor,
      ),
      child: Text(
        tag,
        style: textTheme.bodySmall?.copyWith(
            color: selected == true ? colors.primaryColor : colors.textColor),
      ),
    );
  }

  static Widget buildTitle(BuildContext context,
      {required AppColors colors,
      required String title,
      double fontSize = 18,
      FontWeight? weight,
      required DoubleFactor fontSizeOf}) {
    final textTheme = TextTheme.of(context);
    return Text(
      title,
      style: textTheme.bodyMedium?.copyWith(
          fontWeight: weight ?? FontWeight.w700,
          fontSize: fontSizeOf(fontSize)),
    );
  }

  static Widget buildListTags(List<String> tags,
      {required BuildContext context,
      required AppColors colors,
      double height = 25,
      Color? color,
      int? selectedIndex,
      void Function(int)? onTap}) {
    return SizedBox(
        height: height,
        child: ListView.separated(
            scrollDirection: Axis.horizontal,
            separatorBuilder: (context, targetIndex) {
              return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 5));
            },
            itemCount: tags.length,
            itemBuilder: (context, tagsIndex) {
              final tag = tags[tagsIndex];
              return ScaleTap(
                  onPressed: () => onTap != null ? onTap(tagsIndex) : null,
                  child: buildTag(context, colors, tag,
                      bgColor: selectedIndex != null
                          ? selectedIndex == tagsIndex
                              ? colors.themeColor
                              : color
                          : color,
                      selected: selectedIndex == tagsIndex));
            }));
  }
}
