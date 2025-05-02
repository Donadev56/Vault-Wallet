import 'package:flutter/material.dart';
import 'package:moonwallet/types/types.dart';

class TransactionAppBar extends StatelessWidget {
  final AppColors colors;
  final String title;
  final List<Widget> actions;
  const TransactionAppBar({
    super.key,
    required this.colors,
    required this.title,
    required this.actions,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.all(10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Padding(
            padding: const EdgeInsets.all(10),
            child: Text(
              title,
              style: textTheme.headlineMedium?.copyWith(
                  color: colors.textColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 22),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            spacing: 10,
            children: actions,
          )
        ],
      ),
    );
  }
}
