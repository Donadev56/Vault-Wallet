import 'package:flutter/material.dart';
import 'package:moonwallet/types/types.dart';

/// Top toolbar button widget.
class ToolBarAction extends StatelessWidget {
  final void Function() onPressed;
  final Widget child;
  final double width;
  final AppColors colors;

  const ToolBarAction({
    super.key,
    required this.child,
    required this.onPressed,
    this.width = 30,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: 30,
      child: RawMaterialButton(
        elevation: 0,
        fillColor: colors.primaryColor,
        onPressed: onPressed,
        child: Center(child: child),
      ),
    );
  }
}
