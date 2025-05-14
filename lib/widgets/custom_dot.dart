import 'package:flutter/material.dart';
import 'package:moonwallet/types/types.dart';

class CustomDots extends StatelessWidget {
  final EdgeInsetsGeometry padding;
  final double dotSize;
  final Color? color;
  final AppColors colors;
  final double spacing;
  final BorderRadiusGeometry? borderRadius;
  final double opacity;

  const CustomDots({
    super.key,
    this.padding = const EdgeInsets.all(10),
    this.dotSize = 20,
    required this.colors,
    this.color,
    this.spacing = 10,
    this.borderRadius,
    this.opacity = 0.8,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          spacing: spacing,
          children: List.generate(3, (i) {
            return Container(
              width: dotSize,
              height: dotSize,
              decoration: BoxDecoration(
                  color: color ?? colors.textColor.withOpacity(opacity),
                  borderRadius: borderRadius ?? BorderRadius.circular(30)),
            );
          })),
    );
  }
}
