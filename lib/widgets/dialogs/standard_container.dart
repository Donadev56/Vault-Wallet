import 'package:flutter/material.dart';
import 'package:moonwallet/types/types.dart';

class StandardContainer extends StatelessWidget {
  final AppColors colors;
  final Color? backgroundColor;
  final Widget? child;
  final EdgeInsetsGeometry? padding;
  const StandardContainer(
      {super.key,
      required this.colors,
      this.child,
      this.backgroundColor,
      this.padding});

  @override
  Widget build(BuildContext context) {
    return Container(
        padding: padding ?? const EdgeInsets.all(10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
        ),
        child: child);
  }
}
