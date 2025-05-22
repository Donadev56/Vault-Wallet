import 'package:flutter/material.dart';
import 'package:moonwallet/types/types.dart';

class TransactionParentContainer extends StatelessWidget {
  final AppColors colors;
  final Widget? child;
  const TransactionParentContainer({
    super.key,
    required this.colors,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
          padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 25),
          decoration: BoxDecoration(
            color: colors.primaryColor,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(10),
              topRight: Radius.circular(10),
            ),
          ),
          child: child),
    );
  }
}
