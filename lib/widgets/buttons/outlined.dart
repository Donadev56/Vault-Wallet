import 'package:flutter/material.dart';
import 'package:moonwallet/types/types.dart';

class CustomOutlinedButton extends StatelessWidget {
  final void Function()? onPressed;
  final Widget? icon;
  final AppColors colors;
  final String text;

  const CustomOutlinedButton(
      {super.key,
      this.icon,
      required this.colors,
      this.onPressed,
      required this.text});

  @override
  Widget build(BuildContext context) {
    final textTheme = TextTheme.of(context);
    final onPressFunction = onPressed;
    final label = Text(
      text,
      style: textTheme.bodyMedium?.copyWith(
        fontSize: 16,
        color: colors.themeColor,
      ),
    );
    final style = OutlinedButton.styleFrom(
      padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 30),
      side: BorderSide(color: colors.themeColor),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(30),
      ),
    );

    return icon != null
        ? OutlinedButton.icon(
            onPressed: onPressFunction,
            icon: icon,
            style: style,
            label: label,
          )
        : OutlinedButton(
            onPressed: onPressFunction,
            style: style,
            child: label,
          );
  }
}
