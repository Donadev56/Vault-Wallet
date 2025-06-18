import 'package:flutter/material.dart';
import 'package:moonwallet/types/types.dart';

class CustomElevatedButton extends StatelessWidget {
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
  final double rounded;
  final Color? backgroundColor;

  const CustomElevatedButton(
      {super.key,
      required this.onPressed,
      this.child,
      this.enabled = true,
      required this.colors,
      this.text,
      this.icon,
      this.opacity = 1,
      this.textStyle,
      this.textColor,
      this.rounded = 50,
      this.backgroundColor,
      this.padding});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final style = ElevatedButton.styleFrom(
      elevation: 0,
      backgroundColor: backgroundColor ??
          (enabled
              ? colors.themeColor.withOpacity(opacity)
              : colors.themeColor.withOpacity(0.4)),
      foregroundColor: colors.primaryColor,
      padding:
          padding ?? const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(rounded),
      ),
    );
    final onPressedFunc = enabled ? onPressed : () => ();
    final label = child ??
        Text(
          text ?? "",
          style: textStyle ??
              textTheme.bodyMedium?.copyWith(
                color: textColor ?? colors.primaryColor,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
        );

    return icon != null
        ? TextButton.icon(
            onPressed: onPressedFunc,
            label: label,
            icon: icon,
            style: style,
          )
        : TextButton(style: style, onPressed: onPressedFunc, child: label);
  }
}
