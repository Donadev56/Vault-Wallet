import 'package:flutter/material.dart';
import 'package:moonwallet/types/types.dart';

class CustomPopMenuDivider extends PopupMenuEntry {
  final AppColors colors;
  final Color? color;
  final double? width;
  final double height;
  final BorderRadiusGeometry? borderRadius;

  const CustomPopMenuDivider({
    super.key,
    required this.colors,
    this.width,
    this.height = 5,
    this.borderRadius,
    this.color,
  });

  @override
  State<PopupMenuEntry> createState() => _CustomDividerState();

  @override
  bool represents(dynamic value) {
    return value == this;
  }
}

class _CustomDividerState extends State<CustomPopMenuDivider> {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        borderRadius: widget.borderRadius,
        color: widget.color ?? widget.colors.textColor.withOpacity(0.1),
      ),
    );
  }
}
