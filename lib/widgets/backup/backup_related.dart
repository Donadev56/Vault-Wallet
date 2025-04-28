import 'package:flutter/material.dart';
import 'package:moonwallet/types/types.dart';

class MnemonicChip extends StatelessWidget {
  final AppColors colors;
  final Color? bgColor;
  final Color? sideColor;
  final Color? textColor;
  final VisualDensity? density;

  final String word;
  final int index;
  final bool withIndex;
  final double margin;

  const MnemonicChip(
      {super.key,
      required this.colors,
      required this.index,
      required this.word,
      this.withIndex = true,
      this.bgColor,
      this.sideColor,
      this.textColor,
      this.density,
      this.margin = 5.00});

  @override
  Widget build(BuildContext context) {
    final textTheme = TextTheme.of(context);
    return Padding(
      padding: EdgeInsets.all(margin),
      child: Chip(
        visualDensity: density,
        side: BorderSide(
            width: 1,
            color: sideColor ?? colors.textColor.withValues(alpha: .8)),
        label: Text(
          word,
          style: textTheme.bodyMedium?.copyWith(
              color: textColor ?? colors.textColor.withValues(alpha: 0.8),
              fontSize: 14),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        backgroundColor: bgColor ?? colors.primaryColor,
        avatar: withIndex
            ? Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                    border: Border.all(width: 1, color: colors.textColor),
                    borderRadius: BorderRadius.circular(50)),
                child: Center(
                  child: Text(
                    (index + 1).toString(),
                    style: textTheme.bodySmall
                        ?.copyWith(fontSize: 12, color: colors.textColor),
                  ),
                ),
              )
            : null,
      ),
    );
  }
}

class SpaceWithBottomButton extends StatelessWidget {
  final List<Widget> children;
  final double spacing;

  const SpaceWithBottomButton(
      {super.key, required this.children, this.spacing = 0});

  @override
  Widget build(BuildContext context) {
    return Column(
      spacing: spacing,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: children,
    );
  }
}
