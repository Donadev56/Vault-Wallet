import 'package:flutter/material.dart';
import 'package:moonwallet/types/types.dart';

class StandardContainer extends StatelessWidget {
  final AppColors colors;
  final Widget? child;
  const StandardContainer({
    super.key,
    required this.colors,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: colors.secondaryColor,
        ),
        child: child);
  }
}
