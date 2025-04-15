import 'package:flutter/material.dart';

typedef OnTap = void Function(int index);

class ActionsWidgets extends StatelessWidget {
  final Color color;
  final Color textColor;
  final String text;
  final IconData? actIcon;
  final VoidCallback onTap;
  final double size;
  final double radius;
  final double iconSize;
  final TextStyle? style;
  final bool showName;
  final AlignmentGeometry? alignment;
  const ActionsWidgets(
      {super.key,
      required this.color,
      required this.textColor,
      required this.text,
      required this.onTap,
      this.size = 45,
      this.radius = 10,
      this.iconSize = 18,
      this.style,
      this.showName = true,
      this.alignment,
      this.actIcon});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      margin: const EdgeInsets.all(10),
      child: Column(
        children: [
          Container(
              margin: const EdgeInsets.all(5),
              width: size,
              height: size,
              decoration: BoxDecoration(
                  color: color, borderRadius: BorderRadius.circular(radius)),
              child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(radius),
                    onTap: onTap,
                    child: Align(
                      alignment: alignment ?? Alignment.center,
                      child: Icon(
                        actIcon,
                        color: textColor,
                        size: iconSize,
                      ),
                    ),
                  ))),
          if (showName) Text(text, style: style ?? textTheme.bodySmall)
        ],
      ),
    );
  }
}
