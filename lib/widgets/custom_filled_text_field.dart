import 'package:flutter/material.dart';
import 'package:moonwallet/types/types.dart';

class CustomFilledTextFormField extends StatelessWidget {
  final TextEditingController? controller;
  final AppColors colors;
  final String? hintText;
  final String? labelText;
  final double rounded;
  final DoubleFactor roundedOf;
  final DoubleFactor fontSizeOf;
  final DoubleFactor iconSizeOf;
  final bool readOnly;
  final TextInputType? keyboardType;
  final void Function(String value)? onChanged;
  final void Function(String value)? onSubmitted;
  final String? Function(String?)? validator;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final EdgeInsetsGeometry? contentPadding;
  final int minLines;
  final int maxLines;

  const CustomFilledTextFormField(
      {super.key,
      this.keyboardType,
      this.validator,
      this.readOnly = false,
      this.labelText,
      required this.colors,
      this.hintText,
      this.controller,
      this.onChanged,
      this.onSubmitted,
      required this.fontSizeOf,
      required this.iconSizeOf,
      required this.roundedOf,
      this.prefixIcon,
      this.suffixIcon,
      this.rounded = 10,
      this.maxLines = 1,
      this.minLines = 1,
      this.contentPadding});

  @override
  Widget build(BuildContext context) {
    final textTheme = TextTheme.of(context);
    return TextFormField(
      readOnly: readOnly,
      validator: validator,
      keyboardType: keyboardType,
      cursorColor: colors.themeColor,
      controller: controller,
      onChanged: onChanged,
      minLines: minLines,
      maxLines: maxLines,
      style: textTheme.bodyMedium
          ?.copyWith(color: colors.textColor, fontSize: fontSizeOf(14)),
      decoration: InputDecoration(
          contentPadding: contentPadding,
          prefixIcon: prefixIcon,
          suffixIcon: suffixIcon,
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(roundedOf(rounded)),
              borderSide: BorderSide(width: 0, color: Colors.transparent)),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(roundedOf(rounded)),
              borderSide: BorderSide(width: 0, color: Colors.transparent)),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(roundedOf(rounded)),
              borderSide: BorderSide(width: 0, color: Colors.transparent)),
          fillColor: colors.secondaryColor,
          filled: true,
          hintText: hintText,
          hintStyle: textTheme.bodyMedium?.copyWith(
              color: colors.textColor.withValues(alpha: 0.2),
              fontSize: fontSizeOf(14)),
          labelText: labelText,
          labelStyle: textTheme.bodySmall
              ?.copyWith(color: colors.textColor.withOpacity(0.8))),
    );
  }
}
