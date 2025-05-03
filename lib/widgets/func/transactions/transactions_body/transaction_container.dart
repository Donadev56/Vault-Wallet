import 'package:flutter/material.dart';
import 'package:moonwallet/types/types.dart';
import 'package:moonwallet/widgets/dialogs/standard_container.dart';

class TransactionContainer extends StatelessWidget {
  final AppColors colors;
  final Widget? child;
  final EdgeInsetsGeometry? padding;
  final Color? backgroundColor;

  const TransactionContainer(
      {super.key,
      required this.colors,
      this.child,
      this.padding,
      this.backgroundColor});

  @override
  Widget build(BuildContext context) {
    return StandardContainer(
      padding: padding,
      backgroundColor: backgroundColor ?? colors.primaryColor,
      child: child,
    );
  }
}
