import 'package:flutter/material.dart';
import 'package:moonwallet/types/types.dart';

class ColumnDetails extends StatelessWidget {
  final String title;
  final Widget value;
  final TextStyle? titleStyle;
  final AppColors colors;
  final DoubleFactor fontSizeOf;
  final double spacing;
  const ColumnDetails(
      {super.key,
      required this.title,
      required this.value,
      this.titleStyle,
      required this.colors,
      required this.fontSizeOf,
      this.spacing = 10});

  @override
  Widget build(BuildContext context) {
    final textTheme = TextTheme.of(context);

    return Column(
      spacing: spacing,
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: titleStyle ??
              textTheme.bodyMedium?.copyWith(
                  fontSize: fontSizeOf(14),
                  fontWeight: FontWeight.w600,
                  color: colors.textColor),
        ),
        value,
      ],
    );
  }
}
