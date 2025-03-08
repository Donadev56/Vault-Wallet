import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class BottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int>? onTap;
  final Color primaryColor;
  final Color textColor;
  final Color secondaryColor;

  const BottomNav({
    Key? key,
    required this.currentIndex,
    this.onTap,
    required this.primaryColor,
    required this.textColor,
    required this.secondaryColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> navItems = [
      {'icon': Icons.home, 'label': 'Home'},
      {'icon': Icons.explore, 'label': 'Discover'},
    ];

    return Container(
      decoration: BoxDecoration(
          border: Border(
              top: BorderSide(width: 1, color: textColor.withOpacity(0.1)))),
      child: BottomNavigationBar(
        backgroundColor: primaryColor,
        currentIndex: currentIndex,
        onTap: onTap,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: secondaryColor,
        unselectedItemColor: textColor,
        selectedLabelStyle: GoogleFonts.exo2(fontSize: 12),
        unselectedLabelStyle: GoogleFonts.exo2(),
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
                  item['icon'] as IconData,
                  size: 30,
                ),
              ),
            ),
            label: isSelected ? item['label'] as String : "",
          );
        }),
      ),
    );
  }
}
