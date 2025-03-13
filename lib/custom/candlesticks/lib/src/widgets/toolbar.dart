import 'package:flutter/material.dart';
import 'package:moonwallet/custom/candlesticks/lib/candlesticks.dart';
import 'package:moonwallet/types/types.dart';

class ToolBar extends StatelessWidget {
  final AppColors colors;
  const ToolBar({
    super.key,
    required this.onZoomInPressed,
    required this.onZoomOutPressed,
    required this.children,
    required this.colors,
  });

  final void Function() onZoomInPressed;
  final void Function() onZoomOutPressed;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: colors.primaryColor,
      child: Padding(
        padding: const EdgeInsets.all(2.0),
        child: Row(
          children: [
            ToolBarAction(
              colors: colors,
              onPressed: onZoomOutPressed,
              child: Icon(
                Icons.remove,
                color: colors.grayColor,
              ),
            ),
            ToolBarAction(
              colors: colors,
              onPressed: onZoomInPressed,
              child: Icon(
                Icons.add,
                color: colors.grayColor,
              ),
            ),
            ...children
          ],
        ),
      ),
    );
  }
}
