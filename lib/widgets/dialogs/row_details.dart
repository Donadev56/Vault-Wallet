import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:moonwallet/types/types.dart';

class RowDetailsContent extends StatelessWidget {
  final String name;
  final String value;
  final AppColors colors;
  final bool underline;
  final TextStyle? valueStyle;
  final TextStyle? titleStyle;
  final bool copyOnClick;
  final void Function()? onClick;
  final bool? truncateAddress;
  final double? maxValueSpace;
  final Color? valueColor;

  const RowDetailsContent(
      {super.key,
      required this.colors,
      required this.name,
      this.underline = false,
      this.valueStyle,
      this.titleStyle,
      this.copyOnClick = false,
      this.onClick,
      this.truncateAddress,
      this.maxValueSpace,
      this.valueColor,
      required this.value});

  @override
  Widget build(BuildContext context) {
    if (maxValueSpace != null) {
      if ((maxValueSpace as double) >= 1 || (maxValueSpace as double) <= 0) {
        throw ArgumentError(
            "The max space value  must be less than 1 and greater than 0");
      }
    }
    final textTheme = TextTheme.of(context);

    String truncatedAddress(String value) {
      return "${value.substring(0, 6)}...${value.substring(value.length - 6)}";
    }

    return LayoutBuilder(builder: (ctx, c) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            name,
            style: titleStyle ??
                textTheme.bodyMedium
                    ?.copyWith(fontSize: 14, color: colors.textColor),
          ),
          GestureDetector(
            onTap: () {
              if (onClick != null) {
                onClick!();
                return;
              }
              if (copyOnClick) {
                Clipboard.setData(ClipboardData(text: value));
                return;
              }
            },
            child: ConstrainedBox(
              constraints:
                  BoxConstraints(maxWidth: c.maxWidth * (maxValueSpace ?? 0.5)),
              child: Text(
                truncateAddress == true ? truncatedAddress(value) : value,
                maxLines: 1,
                style: valueStyle ??
                    textTheme.bodyMedium?.copyWith(
                        decoration: underline ? TextDecoration.underline : null,
                        decorationColor:
                            colors.textColor.withValues(alpha: 0.8),
                        overflow: TextOverflow.ellipsis,
                        fontSize: 14,
                        color: valueColor ?? colors.textColor,
                        fontWeight: FontWeight.w500),
              ),
            ),
          )
        ],
      );
    });
  }
}
