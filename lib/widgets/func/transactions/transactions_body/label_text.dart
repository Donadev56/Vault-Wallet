import 'package:flutter/material.dart';
import 'package:moonwallet/types/types.dart';

class LabelText extends StatelessWidget {
  final AppColors colors;
  final String text;
  const LabelText({
    super.key,
    required this.colors,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Text(text,
        style: textTheme.bodyMedium?.copyWith(
            color: colors.textColor,
            fontWeight: FontWeight.bold,
            fontSize: 16));
  }
}
