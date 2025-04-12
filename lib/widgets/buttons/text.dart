import 'package:flutter/material.dart';

class GhostButton extends StatelessWidget {
  final void Function() onPressed;
  final String text;
  final Widget child;
  final void Function()? onLongPress;
  final Function(bool)? onHover;
  final Function(bool)? onFocusChange;

  const GhostButton(
      {super.key,
      required this.onPressed,
      required this.text,
      required this.child,
      this.onLongPress,
      this.onHover,
      this.onFocusChange});

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onLongPress: onLongPress,
      onHover: onHover,
      onFocusChange: onFocusChange,
      onPressed: onPressed,
      child: child,
    );
  }
}
