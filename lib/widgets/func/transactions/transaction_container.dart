import 'package:flutter/material.dart';
import 'package:moonwallet/types/types.dart';

class TransactionContainer extends StatelessWidget {
  final AppColors colors;
  final Widget? child;
  const TransactionContainer({super.key, required this.colors, this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
        margin: const EdgeInsets.all(10),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: colors.secondaryColor,
        ),
        child: child);
  }
}
