import 'package:flutter/material.dart';
import 'package:moonwallet/types/types.dart';
import 'package:moonwallet/widgets/custom_filled_text_field.dart';

class SearchModalAppBar extends StatelessWidget {
  final String title;
  final String? description;
  final AppColors colors;
  final void Function(String)? onChanged;
  final TextEditingController? controller;
  final TextStyle? titleStyle;
  final TextStyle? descriptionStyle;
  final List<Widget>? children;

  final String? hint;
  final DoubleFactor roundedOf;
  final DoubleFactor fontSizeOf;
  final DoubleFactor iconSizeOf;

  const SearchModalAppBar(
      {super.key,
      required this.colors,
      required this.title,
      this.onChanged,
      this.controller,
      this.hint,
      this.description,
      this.descriptionStyle,
      required this.fontSizeOf,
      required this.iconSizeOf,
      required this.roundedOf,
      this.children,
      this.titleStyle});

  @override
  Widget build(BuildContext context) {
    final listChildren = [
      Header(title: title, colors: colors),
      if (description != null)
        LayoutBuilder(builder: (ctx, c) {
          return Align(
              alignment: Alignment.centerLeft,
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: c.maxWidth * 0.9),
                child: Text(
                  description!,
                  style: descriptionStyle ??
                      TextTheme.of(context).bodyMedium?.copyWith(
                          fontSize: 14,
                          color: colors.textColor.withValues(alpha: 0.6)),
                ),
              ));
        }),
      CustomFilledTextFormField(
        onChanged: onChanged,
        controller: controller,
        prefixIcon: Icon(
          Icons.search,
          color: colors.grayColor,
        ),
        colors: colors,
        fontSizeOf: fontSizeOf,
        iconSizeOf: iconSizeOf,
        roundedOf: roundedOf,
        hintText: hint,
        contentPadding: const EdgeInsets.all(0),
      ),
    ];
    if (children != null) {
      listChildren.addAll(children!);
    }
    return Column(
      spacing: 15,
      children: listChildren,
    );
  }
}

class Header extends StatelessWidget {
  final String title;
  final AppColors colors;
  final TextStyle? titleStyle;
  const Header(
      {super.key, required this.title, required this.colors, this.titleStyle});

  @override
  Widget build(BuildContext context) {
    final textTheme = TextTheme.of(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Align(
          alignment: Alignment.topLeft,
          child: Text(
            title,
            style: titleStyle ??
                textTheme.headlineMedium?.copyWith(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: colors.textColor.withValues(alpha: 0.7),
                ),
          ),
        ),
        IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: Icon(
              Icons.keyboard_arrow_down,
              size: 30,
              color: colors.textColor.withValues(alpha: 0.7),
            ))
      ],
    );
  }
}
