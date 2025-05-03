import 'package:flutter/material.dart';
import 'package:moonwallet/types/types.dart';
import 'package:moonwallet/widgets/buttons/elevated.dart';

class ExpendedElevatedButton extends StatelessWidget {
  final AppColors colors;
  final void Function()? onPressed;
  final bool enabled;
  final String? text;
  final Widget? icon;

  const ExpendedElevatedButton(
      {super.key,
      required this.colors,
      required this.onPressed,
      this.text,
      this.enabled = true,
      this.icon});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: MediaQuery.of(context).size.height,
      child: CustomElevatedButton(
        onPressed: onPressed,
        colors: colors,
        enabled: enabled,
        text: text,
        icon: icon,
      ),
    );
  }
}
