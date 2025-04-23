import 'package:flutter/material.dart';
import 'package:moonwallet/types/types.dart';

class CustomFilledTextFormField extends StatelessWidget {
  final TextEditingController? controller;
  final AppColors colors;
  final String? hintText;
  final String? labelText;

  final bool readOnly;
  final TextInputType? keyboardType;
  final void Function(String value)? onChanged;
  final void Function(String value)? onSubmitted;
  final String? Function(String?)? validator;

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
      this.onSubmitted});

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
      style: textTheme.bodyMedium?.copyWith(
        color: colors.textColor,
      ),
      decoration: InputDecoration(
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(width: 0, color: Colors.transparent)),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(width: 0, color: Colors.transparent)),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(width: 0, color: Colors.transparent)),
          fillColor: colors.secondaryColor.withOpacity(0.5),
          filled: true,
          hintText: hintText,
          hintStyle: textTheme.bodyMedium
              ?.copyWith(color: colors.textColor.withValues(alpha: 0.2)),
          labelText: labelText,
          labelStyle: textTheme.bodySmall
              ?.copyWith(color: colors.textColor.withOpacity(0.8))),
    );
  }
}
