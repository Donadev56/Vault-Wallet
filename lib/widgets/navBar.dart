// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:moonwallet/types/types.dart';

class BottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int>? onTap;
  final Color primaryColor;
  final Color textColor;
  final Color secondaryColor;
  final DoubleFactor roundedOf;
  final DoubleFactor fontSizeOf;
  final DoubleFactor iconSizeOf;

  const BottomNav({
    super.key,
    required this.currentIndex,
    this.onTap,
    required this.primaryColor,
    required this.textColor,
    required this.secondaryColor,
    required this.fontSizeOf,
    required this.iconSizeOf,
    required this.roundedOf
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    final List<Map<String, dynamic>> navItems = [
      {'icon': Icons.home_filled, "filled": Icons.home_filled, 'label': 'Home'},
      {
        'icon': Icons.sync_alt,
        "filled": Icons.sync_alt_rounded,
        'label': 'Swap'
      },
      {
        'icon': LucideIcons.chartNoAxesCombined,
        "filled": LucideIcons.chartNoAxesCombined,
        'label': 'Trending'
      },
      {
        'icon': Icons.explore_outlined,
        "filled": Icons.explore,
        'label': 'Discover'
      },
    ];

    return Container(
      decoration: BoxDecoration(
          border: Border(
              top: BorderSide(color: textColor.withOpacity(0.2), width: 0.1))),
      child: Theme(
        data: Theme.of(context).copyWith(
          splashFactory: InkRipple.splashFactory,
        ),
        child: BottomNavigationBar(
          enableFeedback: true,
          elevation: 0,
          backgroundColor: primaryColor,
          currentIndex: currentIndex,
          onTap: onTap,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: secondaryColor,
          unselectedItemColor: textColor,
          selectedLabelStyle: textTheme.bodySmall?.copyWith(fontSize: fontSizeOf (10)),
          unselectedLabelStyle: textTheme.bodySmall?.copyWith(
            fontSize: fontSizeOf(10),
            color: textColor.withOpacity(0.5),
          ),
          items: List.generate(navItems.length, (index) {
            final item = navItems[index];
            final bool isSelected = index == currentIndex;

            return BottomNavigationBarItem(
              backgroundColor: primaryColor,
              activeIcon: Icon(
                item['filled'] as IconData,
                size: iconSizeOf(25),
              ),
              icon: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.all(5),
                child: AnimatedScale(
                  scale: 1,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  child: Icon(
                    item['icon'] as IconData,
                    size: iconSizeOf(25),
                  ),
                ),
              ),
              label: isSelected ? item['label'] as String : "",
            );
          }),
        ),
      ),
    );
  }
}
