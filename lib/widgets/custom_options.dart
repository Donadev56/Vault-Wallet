import 'package:flutter/material.dart';
import 'package:moonwallet/service/vibration.dart';
import 'package:moonwallet/types/types.dart';

typedef OnTapWithIndex = void Function(int index);

class CustomOptionWidget extends StatelessWidget {
  final String spaceName;
  final AppColors colors;
  final TextStyle spaceNameStyle;
  final Color? backgroundColor;
  final String? description;
  final TextStyle? descriptionStyle;
  final BoxBorder? containerBorder;
  final BorderRadiusGeometry? containerRadius;
  final ShapeBorder? shapeBorder;
  final List<Option> options;
  final Alignment alignment;
  final Alignment textAlignment;
  final OnTapWithIndex? onTap;
  final Color? splashColor;
  final Color tileColor;
  final double internalElementSpacing;
  final MainAxisAlignment mainAxisAlignment;
  final CrossAxisAlignment crossAxisAlignment;
  final EdgeInsets listTitlePadding;

  const CustomOptionWidget(
      {super.key,
      required this.colors,
      required this.spaceName,
      required this.spaceNameStyle,
      required this.options,
      this.alignment = Alignment.center,
      this.textAlignment = Alignment.topLeft,
      this.onTap,
      this.splashColor,
      this.backgroundColor,
      this.containerBorder,
      this.containerRadius,
      this.shapeBorder,
      this.tileColor = Colors.transparent,
      this.internalElementSpacing = 0.0,
      this.mainAxisAlignment = MainAxisAlignment.start,
      this.crossAxisAlignment = CrossAxisAlignment.center,
      this.description,
      this.descriptionStyle,
      this.listTitlePadding =
          const EdgeInsets.symmetric(vertical: 0, horizontal: 10)});

  @override
  Widget build(BuildContext context) {
    final textTheme = TextTheme.of(context);
    return Align(
        alignment: alignment,
        child: SizedBox(
          width: MediaQuery.of(context).size.width * 0.9,
          child: Column(
            spacing: 15,
            children: [
              Align(
                alignment: textAlignment,
                child: Text(
                  spaceName,
                  style: spaceNameStyle,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (description != null)
                Align(
                  alignment: textAlignment,
                  child: Text(
                    description!,
                    style: descriptionStyle ??
                        textTheme.bodySmall?.copyWith(
                          color: colors.textColor.withValues(alpha: 0.4),
                          fontSize: 14,
                        ),
                  ),
                ),
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                    color: backgroundColor ?? colors.secondaryColor,
                    borderRadius: containerRadius,
                    border: containerBorder),
                child: Column(
                    mainAxisAlignment: mainAxisAlignment,
                    crossAxisAlignment: crossAxisAlignment,
                    spacing: internalElementSpacing,
                    children: List.generate(
                      options.length,
                      (i) {
                        final option = options[i];
                        return Material(
                          color: Colors.transparent,
                          child: ListTile(
                            minVerticalPadding: 0,
                            contentPadding: listTitlePadding,
                            tileColor: option.tileColor ?? tileColor,
                            splashColor: splashColor ?? option.splashColor,
                            shape: shapeBorder,
                            onTap: () {
                              vibrate();
                              if (onTap != null) {
                               onTap!(i);
                              } else  if (option.onPressed != null){
                                option.onPressed!();
                              }

                            },
                            subtitle: option.subtitle,
                            leading: option.icon,
                            title: Text(option.title, style: option.titleStyle),
                            trailing: option.trailing,
                          ),
                        );
                      },
                    )),
              )
            ],
          ),
        ));
  }
}
