import 'package:flutter/material.dart';
import 'package:moonwallet/types/types.dart';

class CustomSwitchListTitle extends StatelessWidget {
  final AppColors colors;
  final void Function()? onTap;
  final Widget? leading;
  final String title;
  final void Function(bool)? onChanged;
  final bool value;
  final DoubleFactor fontSizeOf;
  final double rounded;
  final VisualDensity? density;
  final EdgeInsetsGeometry? padding;
  const CustomSwitchListTitle(
      {super.key,
      required this.onTap,
      required this.colors,
      this.leading,
      this.rounded = 0,
      required this.title,
      this.onChanged,
      required this.fontSizeOf,
      this.density,
      this.padding,
      required this.value});

  @override
  Widget build(BuildContext context) {
    final textTheme = TextTheme.of(context);
    return ListTile(
      visualDensity: density,
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(rounded)),
      contentPadding:
          padding ?? const EdgeInsets.symmetric(vertical: 8, horizontal: 20),
      onTap: onTap,
      leading: leading,
      title: Text(
        title,
        style: textTheme.bodyMedium?.copyWith(
            color: colors.textColor,
            fontSize: fontSizeOf(16),
            fontWeight: FontWeight.w500),
      ),
      trailing: Switch(value: value, onChanged: onChanged),
    );
  }
}
