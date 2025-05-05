import 'package:flutter/material.dart';

class StandardContainer extends StatelessWidget {
  final Color? backgroundColor;
  final Widget? child;
  final EdgeInsetsGeometry? padding;
  const StandardContainer(
      {super.key, this.child, this.backgroundColor, this.padding});

  @override
  Widget build(BuildContext context) {
    return Container(
        padding: padding ?? const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(10),
        ),
        child: child);
  }
}
