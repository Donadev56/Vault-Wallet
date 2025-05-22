import 'package:flutter/material.dart';
import 'package:moonwallet/types/types.dart';

import '../models/button_config.dart';

enum ButtonMode {
  confirm,
  reject,
}

class PrimaryButton extends StatelessWidget {
  final VoidCallback onPressed;
  final String text;
  final ButtonMode mode;
  final double? width;
  final double height;
  final ButtonConfig? style;
  final AppColors colors;

  // Màu mặc định
  static const defaultConfirmColor = Color(0xFF4CAF50); // Xanh lá
  static const defaultRejectColor = Color(0xFFf44336); // Đỏ
  static const defaultTextColor = Colors.white;
  static const defaultBorderColor = Colors.transparent;
  static const defaultBorderWidth = 0.0;
  static const defaultBorderRadius = 5.0;
  static const defaultPadding = EdgeInsets.all(10);

  const PrimaryButton(
      {super.key,
      required this.onPressed,
      required this.text,
      this.mode = ButtonMode.confirm,
      this.width,
      this.height = 45,
      this.style,
      required this.colors});

  ButtonConfig _getConfigForMode(ButtonMode mode) {
    switch (mode) {
      case ButtonMode.confirm:
        return ButtonConfig(
          backgroundColor: style?.backgroundColor ?? colors.themeColor,
          textColor: style?.textColor ?? colors.primaryColor,
          borderRadius: style?.borderRadius ?? 10.0,
          padding: style?.padding ?? const EdgeInsets.all(10),
          fontSize: style?.fontSize ?? 16.0,
          borderColor: style?.borderColor,
          borderWidth: style?.borderWidth,
        );

      case ButtonMode.reject:
        return ButtonConfig(
          backgroundColor: style?.backgroundColor ?? colors.redColor,
          textColor: style?.textColor ?? colors.textColor,
          borderRadius: style?.borderRadius ?? 10.0,
          padding: style?.padding ?? const EdgeInsets.all(10),
          fontSize: style?.fontSize ?? 16.0,
          borderColor: style?.borderColor,
          borderWidth: style?.borderWidth,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final config = _getConfigForMode(mode);
    final bool isReject = mode == ButtonMode.reject;

    return SizedBox(
      width: width,
      height: height,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius:
              BorderRadius.circular(config.borderRadius ?? defaultBorderRadius),
          child: Ink(
            decoration: BoxDecoration(
              color: isReject ? Colors.transparent : config.backgroundColor,
              border: isReject
                  ? Border.all(
                      width: 1,
                      color: config.backgroundColor ?? colors.redColor)
                  : Border.all(width: 0, color: Colors.transparent),
              borderRadius: BorderRadius.circular(
                  config.borderRadius ?? defaultBorderRadius),
            ),
            child: Padding(
              padding: config.padding ?? defaultPadding,
              child: Center(
                child: Text(
                  text,
                  style: TextStyle(
                    color: isReject ? colors.redColor : config.textColor,
                    fontSize: config.fontSize,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
