// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:moonwallet/types/types.dart';

class CustomDialog extends StatelessWidget {
  final Widget content;
  final AppColors colors;
  final String title;
  final TextStyle? titleStyle;
  final TextStyle? subTitleStyle;
  final String? subtitle;
  final EdgeInsetsGeometry? padding;
  const CustomDialog(
      {super.key,
      required this.content,
      required this.colors,
      required this.title,
      this.subtitle,
      this.titleStyle,
      this.padding = const EdgeInsets.all(15),
      this.subTitleStyle});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: padding ?? const EdgeInsets.all(15),
      child: ListView(
        shrinkWrap: true,
        children: [
          // the title
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: Align(
              alignment: Alignment.topLeft,
              child: Text(
                title,
                style: titleStyle ??
                    textTheme.bodyMedium?.copyWith(
                      fontSize: 16,
                      color: colors.textColor.withOpacity(0.7),
                    ),
              ),
            ),
          ),
          // the subtitle
          if (subtitle != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Align(
                alignment: Alignment.topLeft,
                child: Text(
                  subtitle!,
                  style: subTitleStyle ??
                      textTheme.bodyMedium?.copyWith(
                        fontSize: 13,
                        color: colors.textColor.withOpacity(0.5),
                      ),
                ),
              ),
            ),
          // the content
          content
        ],
      ),
    );
  }
}
