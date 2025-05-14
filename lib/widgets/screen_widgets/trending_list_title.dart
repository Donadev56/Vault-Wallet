import 'package:flutter/material.dart';
import 'package:moonwallet/types/types.dart';

class TrendingListTitle extends StatelessWidget {
  final String name;
  final String volume;
  final Widget icon;
  final String price;
  final double percent;
  final AppColors colors;
  final void Function()? onTap;
  final DoubleFactor roundedOf;
  final DoubleFactor fontSizeOf;

  const TrendingListTitle(
      {super.key,
      required this.icon,
      required this.name,
      required this.percent,
      required this.price,
      required this.volume,
      required this.colors,
      this.onTap,
      required this.fontSizeOf,
      required this.roundedOf});

  @override
  Widget build(BuildContext context) {
    final textTheme = TextTheme.of(context);
    final isPositive = percent > 0;
    return ListTile(
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(roundedOf(30))),
      onTap: onTap,
      visualDensity: VisualDensity(vertical: -4, horizontal: -2),
      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
      leading: icon,
      title: Text(
        name,
        style: textTheme.bodyMedium?.copyWith(
            fontSize: fontSizeOf(15),
            color: colors.textColor,
            fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        volume,
        style: textTheme.bodySmall?.copyWith(
            fontSize: fontSizeOf(12),
            color: colors.textColor.withValues(alpha: 0.7)),
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            price,
            style: textTheme.bodyMedium
                ?.copyWith(color: colors.textColor, fontSize: fontSizeOf(15)),
          ),
          Text(
            isPositive ? "+$percent%" : "$percent%",
            style: textTheme.bodyMedium?.copyWith(
                fontSize: fontSizeOf(12),
                color: isPositive ? colors.greenColor : colors.redColor),
          )
        ],
      ),
    );
  }
}
