import 'package:flutter/material.dart';
import 'package:moonwallet/types/types.dart';

class PositionedIcons extends StatelessWidget {
  final List<Widget> children;
  final AppColors colors;
  final DoubleFactor imageSizeOf;
  final AlignmentGeometry? alignment;
  final double gap;
  final Decoration? boxDecoration;
  final EdgeInsetsGeometry? padding;
  final double rounded;
  final double? maxWidth;

  const PositionedIcons(
      {super.key,
      this.maxWidth,
      this.alignment,
      this.gap = 18,
      this.rounded = 50,
      this.padding,
      required this.children,
      this.boxDecoration,
      required this.colors,
      required this.imageSizeOf});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
        width: maxWidth,
        child: Stack(
          alignment: alignment ?? AlignmentDirectional.topStart,
          clipBehavior: Clip.none,
          children: children
              .asMap()
              .entries
              .map((entry) {
                int index = entry.key;
                var element = entry.value;
                return Positioned(
                    left: index * gap,
                    child: Container(
                      padding: padding ?? const EdgeInsets.all(3),
                      decoration: boxDecoration ??
                          BoxDecoration(
                              color: colors.primaryColor,
                              borderRadius: BorderRadius.circular(rounded)),
                      child: element,
                    ));
              })
              .toList()
              .reversed
              .toList(),
        ));
  }
}
