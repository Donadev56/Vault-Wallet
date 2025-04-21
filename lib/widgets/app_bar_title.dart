import 'package:flutter/material.dart';
import 'package:moonwallet/types/types.dart';

class AppBarTitle extends StatelessWidget {
  final String title;
  final AppColors colors;
  final double fontSize;
  const AppBarTitle(
      {super.key,
      this.fontSize = 17,
      required this.title,
      required this.colors});

  @override
  Widget build(BuildContext context) {
    final textTheme = TextTheme.of(context);
    return Text(
      title.toUpperCase(),
      style: textTheme.headlineMedium?.copyWith(
          color: colors.textColor,
          fontWeight: FontWeight.bold,
          fontSize: fontSize),
    );
  }
}
