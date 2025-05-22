import 'package:flutter/material.dart';
import 'package:moonwallet/types/types.dart';

class TransactionAppBar extends StatelessWidget {
  final AppColors colors;
  final String title;
  final List<Widget> actions;
  final EdgeInsetsGeometry? padding;
  final TextStyle? titleStyle;
  const TransactionAppBar(
      {super.key,
      required this.colors,
      required this.title,
      required this.actions,
      this.titleStyle,
      this.padding});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        LayoutBuilder(builder: (ctx, c) {
          return ConstrainedBox(
            constraints: BoxConstraints(maxWidth: c.maxWidth * 0.8),
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: titleStyle?.copyWith(overflow: TextOverflow.ellipsis) ??
                  textTheme.headlineMedium?.copyWith(
                      overflow: TextOverflow.ellipsis,
                      color: colors.textColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 18),
            ),
          );
        }),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.end,
          spacing: 10,
          children: actions,
        )
      ],
    );
  }
}
