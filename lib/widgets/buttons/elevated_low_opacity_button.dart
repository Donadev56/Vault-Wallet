import 'package:flutter/material.dart';
import 'package:moonwallet/types/types.dart';
import 'package:moonwallet/widgets/buttons/elevated.dart';

class ElevatedLowOpacityButton extends StatelessWidget {
  final void Function()? onPressed;
  final Widget? child;
  final String? text;
  final bool enabled;
  final AppColors colors;
  final Widget? icon;
  final double opacity;
  final TextStyle? textStyle;
  final Color? textColor;
  final EdgeInsetsGeometry? padding;
  const ElevatedLowOpacityButton(
      {super.key,
      this.enabled = true,
      required this.colors,
      this.child,
      this.icon,
      this.opacity = 0.4,
      this.onPressed,
      this.text,
      this.textColor,
      this.textStyle,
      this.padding});

  @override
  Widget build(BuildContext context) {
    return CustomElevatedButton(
      padding: padding,
      onPressed: onPressed,
      colors: colors,
      textColor: textColor ?? colors.themeColor,
      opacity: opacity,
      icon: icon,
      text: text,
      textStyle: textStyle,
      child: child,
    );
  }
}
