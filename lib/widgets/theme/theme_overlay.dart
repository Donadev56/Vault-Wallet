import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:moonwallet/types/types.dart';

class ThemedOverlay extends StatelessWidget {
  final Widget child;
  final AppColors colors;

  const ThemedOverlay({super.key, required this.child, required this.colors});

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        systemNavigationBarColor: colors.primaryColor,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: child,
    );
  }
}
