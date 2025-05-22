import 'package:flutter/material.dart';

class StandardContainer extends StatelessWidget {
  final Color? backgroundColor;
  final Widget? child;
  final EdgeInsetsGeometry? padding;
  final double rounded;
  const StandardContainer(
      {super.key,
      this.child,
      this.backgroundColor,
      this.rounded = 10,
      this.padding});

  @override
  Widget build(BuildContext context) {
    return Container(
        padding: padding ?? const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(rounded),
        ),
        child: child);
  }
}
