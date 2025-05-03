import 'package:flutter/material.dart';
import 'package:moonwallet/types/types.dart';
import 'package:moonwallet/widgets/dialogs/standard_container.dart';

class TransactionContainer extends StatelessWidget {
  final AppColors colors;
  final Widget? child;
  final EdgeInsetsGeometry? padding;

  const TransactionContainer(
      {super.key, required this.colors, this.child, this.padding});

  @override
  Widget build(BuildContext context) {
    return StandardContainer(
      padding: padding,
      colors: colors,
      backgroundColor: colors.secondaryColor,
      child: child,
    );
  }
}
