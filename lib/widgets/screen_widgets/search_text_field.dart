import 'package:flutter/material.dart';
import 'package:moonwallet/types/types.dart';
import 'package:moonwallet/widgets/custom_filled_text_field.dart';

class SearchTextField extends StatelessWidget {
  final void Function(String)? onSearch;
  final TextEditingController? controller;
  final DoubleFactor fontSizeOf;
  final AppColors colors;
  final DoubleFactor roundedOf;
  final String hintText;
  final double radius;
  final EdgeInsetsGeometry? contentPadding;
  final void Function(String)? onSubmitted;
  final FocusNode? focusNode;
  final void Function(String)? onFormSubmitted;

  const SearchTextField(
      {super.key,
      this.onSearch,
      this.controller,
      required this.fontSizeOf,
      required this.colors,
      required this.roundedOf,
      this.hintText = "Search",
      this.radius = 40,
      this.contentPadding,
      this.onSubmitted,
      this.focusNode,
      this.onFormSubmitted});

  @override
  Widget build(BuildContext context) {
    return CustomFilledTextFormField(
        focusNode: focusNode,
        onSubmitted: onSubmitted,
        onFieldSubmitted: onFormSubmitted,
        controller: controller,
        onChanged: onSearch,
        rounded: radius,
        prefixIcon: Icon(
          Icons.search,
          color: colors.textColor.withValues(alpha: 0.8),
        ),
        contentPadding: contentPadding ??
            const EdgeInsets.symmetric(horizontal: 15, vertical: 0),
        hintText: hintText,
        colors: colors,
        fontSizeOf: fontSizeOf,
        iconSizeOf: (v) => v,
        roundedOf: roundedOf);
  }
}
