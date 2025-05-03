import 'package:flutter/material.dart';
import 'package:moonwallet/types/types.dart';

class CustomElevatedButton extends StatelessWidget {
  final void Function()? onPressed;
  final Widget? child;
  final String? text;
  final bool enabled;
  final AppColors colors;
  final Widget? icon;

  const CustomElevatedButton({
    super.key,
    required this.onPressed,
    this.child,
    this.enabled = true,
    required this.colors,
    this.text,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final style = ElevatedButton.styleFrom(
      elevation: 0,
      backgroundColor:
          enabled ? colors.themeColor : colors.themeColor.withOpacity(0.4),
      foregroundColor: colors.primaryColor,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(50),
      ),
    );
    final onPressedFunc = enabled ? onPressed : () => ();
    final label = child ??
        Text(
          text ?? "",
          style: textTheme.bodyMedium?.copyWith(
            color: colors.primaryColor,
            fontSize: 16,
            fontWeight: FontWeight.w900,
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
