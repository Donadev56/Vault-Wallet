import 'package:flutter/material.dart';

class LabeledCheckbox extends StatelessWidget {
  const LabeledCheckbox({
    super.key,
    required this.label,
    this.padding,
    required this.value,
    required this.onChanged,
  });

  final Widget label;
  final EdgeInsets? padding;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () {
            onChanged(!value);
          },
          child: Padding(
            padding: padding ?? const EdgeInsets.all(0),
            child: Row(
              children: <Widget>[
                Checkbox(
                  visualDensity: VisualDensity.compact,
                  value: value,
                  onChanged: (bool? newValue) {
                    onChanged(newValue!);
                  },
                ),
                Expanded(child: label),
              ],
            ),
          ),
        ));
  }
}
