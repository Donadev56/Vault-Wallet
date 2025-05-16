import 'package:flutter/material.dart';
import 'package:moonwallet/types/types.dart';

class StandardAppBar extends StatelessWidget implements PreferredSizeWidget {
  final AppColors colors;
  final String title;
  final DoubleFactor fontSizeOf;
  final void Function()? onBackPressed;
  final List<Widget>? actions;
  const StandardAppBar(
      {super.key,
      required this.title,
      this.onBackPressed,
      required this.colors,
      required this.fontSizeOf,
      this.actions});

  @override
  Widget build(BuildContext context) {
    final textTheme = TextTheme.of(context);
    return AppBar(
      backgroundColor: colors.primaryColor,
      surfaceTintColor: colors.primaryColor,
      leading: IconButton(
          onPressed: onBackPressed ?? () => Navigator.pop(context),
          icon: Icon(
            Icons.chevron_left,
            color: colors.textColor.withValues(alpha: 0.7),
          )),
      centerTitle: true,
      title: Text(
        title,
        style: textTheme.bodyMedium?.copyWith(
            fontSize: fontSizeOf(18),
            fontWeight: FontWeight.w600,
            color: colors.textColor),
      ),
      actions: actions,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(60);
}
