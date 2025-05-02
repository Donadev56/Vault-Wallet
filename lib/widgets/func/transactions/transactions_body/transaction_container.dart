import 'package:flutter/material.dart';
import 'package:moonwallet/types/types.dart';
import 'package:moonwallet/widgets/dialogs/standard_container.dart';

class TransactionContainer extends StatelessWidget {
  final AppColors colors;
  final Widget? child;
  const TransactionContainer({super.key, required this.colors, this.child});

  @override
  Widget build(BuildContext context) {
    return StandardContainer(colors: colors, child: child);
  }
}
