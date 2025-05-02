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

class SpaceWithFixedBottom extends StatelessWidget {
  final Widget body;
  final Widget bottom;

  const SpaceWithFixedBottom(
      {super.key, required this.body, required this.bottom});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (ctx, c) {
      return SingleChildScrollView(
          child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: c.maxHeight),
              child: IntrinsicHeight(
                  child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  body,
                  const Spacer(),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10, top: 10),
                    child: bottom,
                  )
                ],
              ))));
    });
  }
}
