import 'package:flutter/material.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:moonwallet/types/types.dart';
import 'package:moonwallet/widgets/func/transactions/transactions_body/transaction_app_bar.dart';

class StandardSendAppBar extends StatelessWidget {
  final AppColors colors;
  const StandardSendAppBar({super.key, required this.colors});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: TransactionAppBar(
          padding: const EdgeInsets.only(bottom: 10),
          colors: colors,
          title: "Transfer",
          actions: [
            IconButton(
              onPressed: () {
                Navigator.pop(
                  context,
                );
              },
              icon: Icon(FeatherIcons.x, color: colors.textColor),
            )
          ]),
    );
  }
}
