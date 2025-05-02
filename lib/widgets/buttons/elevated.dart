import 'package:flutter/material.dart';
import 'package:moonwallet/types/types.dart';

class CustomElevatedButton extends StatelessWidget {
  final void Function()? onPressed;
  final Widget? child;
  final String? text;
  final bool enabled;
  final AppColors colors;

  const CustomElevatedButton({
    super.key,
    required this.onPressed,
    this.child,
    this.enabled = true,
    required this.colors,
    this.text,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return TextButton(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor:
              enabled ? colors.themeColor : colors.themeColor.withOpacity(0.4),
          foregroundColor: colors.primaryColor,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(50),
          ),
        ),
        onPressed: enabled ? onPressed : () => (),
        child: child ??
            Text(
              text ?? "",
              style: textTheme.bodyMedium?.copyWith(
                color: colors.primaryColor,
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ));
  }
}
