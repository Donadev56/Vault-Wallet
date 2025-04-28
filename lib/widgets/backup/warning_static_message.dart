import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:moonwallet/types/types.dart';

class WarningStaticMessage extends StatelessWidget {
  final AppColors colors;
  final String title;
  final String content;

  const WarningStaticMessage(
      {super.key,
      required this.colors,
      required this.title,
      required this.content});

  @override
  Widget build(BuildContext context) {
    final textTheme = TextTheme.of(context);

    return Padding(
      padding: const EdgeInsets.all(20),
      child: RichText(
        text: TextSpan(children: [
          WidgetSpan(
              child: Row(
            children: [
              Icon(
                LucideIcons.circleAlert,
                color: colors.redColor,
              ),
              SizedBox(
                width: 5,
              ),
              Text(title,
                  style: textTheme.bodyMedium?.copyWith(
                      fontSize: 16,
                      color: colors.textColor,
                      decoration: TextDecoration.none)),
            ],
          )),
          WidgetSpan(
            child: Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text(
                content,
                style: textTheme.bodyMedium?.copyWith(
                    fontSize: 16,
                    color: colors.textColor.withOpacity(0.5),
                    decoration: TextDecoration.none),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}
