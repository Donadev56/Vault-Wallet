import 'package:flutter/material.dart';
import 'package:moonwallet/types/types.dart';

class ProfilePlaceholder extends StatelessWidget {
  final AppColors colors;
  final double size;
  final double radius;
  const ProfilePlaceholder(
      {super.key, this.size = 70, required this.colors, this.radius = 50});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
          color: colors.secondaryColor,
          borderRadius: BorderRadius.circular(radius)),
      width: size,
      height: size,
      child: Center(
        child: Icon(
          Icons.person,
          color: colors.textColor,
        ),
      ),
    );
  }
}
