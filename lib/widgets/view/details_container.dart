import 'package:flutter/material.dart';
import 'package:moonwallet/types/types.dart';

class DetailsContainer extends StatelessWidget {
  final Widget child;
  final AppColors colors;
  const DetailsContainer(
      {super.key, required this.colors, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
        margin: const EdgeInsets.only(top: 10),
        padding: const EdgeInsets.only(left: 20, right: 20),
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: colors.secondaryColor),
        child: child);
  }
}
