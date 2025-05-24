import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:moonwallet/custom/scale_tape/scale.dart';
import 'package:moonwallet/notifiers/providers.dart';
import 'package:moonwallet/types/types.dart';

class CustomListTitleButton extends HookConsumerWidget {
  final String text;
  final IconData icon;
  final VoidCallback onTap;
  final DoubleFactor roundedOf;
  final DoubleFactor fontSizeOf;
  final DoubleFactor iconSizeOf;
  final double radius;
  final AppColors colors;

  const CustomListTitleButton(
      {super.key,
      this.radius = 10,
      required this.colors,
      required this.text,
      required this.icon,
      required this.onTap,
      required this.iconSizeOf,
      required this.fontSizeOf,
      required this.roundedOf});

  @override
  Widget build(BuildContext context, ref) {
    final textTheme = Theme.of(context).textTheme;

    return ScaleTap(
      onPressed: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(roundedOf(radius)),
        ),
        child: Material(
          color: colors.secondaryColor,
          borderRadius: BorderRadius.circular(radius),
          child: ListTile(
            visualDensity: VisualDensity(horizontal: 0, vertical: 0),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(roundedOf(radius))),
            leading: Icon(
              size: iconSizeOf(20),
              icon,
              color: colors.textColor,
            ),
            title: Text(
              text,
              style: textTheme.bodyMedium
                  ?.copyWith(color: colors.textColor, fontSize: fontSizeOf(14)),
            ),
          ),
        ),
      ),
    );
  }
}
