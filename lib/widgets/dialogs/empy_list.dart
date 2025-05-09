import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:moonwallet/types/types.dart';

class EmptyList extends StatelessWidget {
  final AppColors colors;
  final String title;
  const EmptyList(
    this.title, {
    super.key,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = TextTheme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(
            LucideIcons.rabbit,
            color: colors.textColor,
            size: 50,
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: textTheme.bodyMedium?.copyWith(color: colors.textColor),
          )
        ],
      ),
    );
  }
}
