// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';

class BottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int>? onTap;
  final Color primaryColor;
  final Color textColor;
  final Color secondaryColor;

  const BottomNav({
    super.key,
    required this.currentIndex,
    this.onTap,
    required this.primaryColor,
    required this.textColor,
    required this.secondaryColor,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    final List<Map<String, dynamic>> navItems = [
      {'icon': Icons.home_filled, "filled": Icons.home_filled, 'label': 'Home'},
      {
        'icon': Icons.explore_outlined,
        "filled": Icons.explore,
        'label': 'Discover'
      },
    ];

    return Container(
      decoration: BoxDecoration(
          border: Border(
              top: BorderSide(color: textColor.withOpacity(0.1), width: 0.1))),
      child: Theme(
        data: Theme.of(context).copyWith(
          splashFactory: InkRipple.splashFactory,
        ),
        child: BottomNavigationBar(
          elevation: 20,
          backgroundColor: primaryColor,
          currentIndex: currentIndex,
          onTap: onTap,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: secondaryColor,
          unselectedItemColor: textColor,
          selectedLabelStyle: textTheme.bodySmall?.copyWith(fontSize: 12),
          unselectedLabelStyle: textTheme.bodySmall?.copyWith(
            fontSize: 12,
            color: textColor.withOpacity(0.5),
          ),
          items: List.generate(navItems.length, (index) {
            final item = navItems[index];
            final bool isSelected = index == currentIndex;

            return BottomNavigationBarItem(
              backgroundColor: primaryColor,
              icon: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.all(5),
                child: AnimatedScale(
                  scale: 1,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  child: Icon(
                    isSelected ? item['filled'] : item['icon'] as IconData,
                    size: 30,
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
