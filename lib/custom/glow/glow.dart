import 'package:flutter/material.dart';

class _GlowBehavior extends ScrollBehavior {
  final Color color;
  final bool? hideGlow;

  const _GlowBehavior({required this.color, this.hideGlow});

  Widget buildViewportChrome(
      BuildContext context, Widget child, AxisDirection axisDirection) {
    if (hideGlow == true) return child;

    switch (Theme.of(context).platform) {
      case TargetPlatform.iOS:
        return child;
      default:
        return GlowingOverscrollIndicator(
          axisDirection: axisDirection,
          color: color,
          child: child,
        );
    }
  }
}

class ScrollGlowColor extends StatelessWidget {
  final Widget child;
  final Color color;
  final bool hideGlow;

  const ScrollGlowColor({
    super.key,
    required this.child,
    required this.color,
    this.hideGlow = false,
  });

  @override
  Widget build(BuildContext context) {
    return ScrollConfiguration(
      behavior: _GlowBehavior(hideGlow: hideGlow, color: color),
      child: child,
    );
  }
}
