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

  const RowDetailsContent(
      {super.key,
      required this.colors,
      required this.name,
      this.underline = false,
      this.valueStyle,
      this.titleStyle,
      this.copyOnClick = false,
      this.onClick,
      required this.value});

  @override
  Widget build(BuildContext context) {
    final textTheme = TextTheme.of(context);
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
              constraints: BoxConstraints(maxWidth: c.maxWidth * 0.5),
              child: Text(
                value,
                maxLines: 1,
                style: valueStyle ??
                    textTheme.bodyMedium?.copyWith(
                        decoration: underline ? TextDecoration.underline : null,
                        decorationColor:
                            colors.textColor.withValues(alpha: 0.8),
                        overflow: TextOverflow.ellipsis,
                        fontSize: 14,
                        color: colors.textColor,
                        fontWeight: FontWeight.w500),
              ),
            ),
          )
        ],
      );
    });
  }
}
