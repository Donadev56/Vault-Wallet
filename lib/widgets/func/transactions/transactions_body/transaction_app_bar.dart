import 'package:flutter/material.dart';
import 'package:moonwallet/types/types.dart';

class TransactionAppBar extends StatelessWidget {
  final AppColors colors;
  final String title;
  final List<Widget> actions;
  final EdgeInsetsGeometry? padding;
  const TransactionAppBar(
      {super.key,
      required this.colors,
      required this.title,
      required this.actions,
      this.padding});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: padding ?? EdgeInsets.all(0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            maxLines: 1,
            style: textTheme.headlineMedium?.copyWith(
                overflow: TextOverflow.ellipsis,
                color: colors.textColor,
                fontWeight: FontWeight.bold,
                fontSize: 22),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            spacing: 10,
            children: actions,
          )
        ],
      ),
    );
  }
}
