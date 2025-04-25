
import 'package:flutter/material.dart';
import 'package:moonwallet/types/types.dart';

class CustomListTitleButton extends StatelessWidget {
  final Color textColor;
  final String text;
  final IconData icon;
  final VoidCallback onTap;
  final DoubleFactor roundedOf;
  final DoubleFactor fontSizeOf;
  final DoubleFactor iconSizeOf;

  const CustomListTitleButton(
      {super.key,
      required this.textColor,
      required this.text,
      required this.icon,
      required this.onTap,
      required this.iconSizeOf,
      required this.fontSizeOf,
      required this.roundedOf});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(10),
      child: ListTile(
        visualDensity: VisualDensity(horizontal: 0, vertical: 0),
        tileColor: textColor.withOpacity(0.05),
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(roundedOf(10))),
        leading: Icon(
          size: iconSizeOf(20),
          icon,
          color: textColor,
        ),
        title: Text(
          
          text,
          style: textTheme.bodyMedium?.copyWith(color: textColor, fontSize: fontSizeOf(14)),
        ),
      ),
    );
  }
}
