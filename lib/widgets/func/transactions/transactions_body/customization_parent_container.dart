import 'package:flutter/material.dart';
import 'package:moonwallet/types/types.dart';
import 'package:moonwallet/widgets/backup/backup_related.dart';
import 'package:moonwallet/widgets/func/transactions/transactions_body/transaction_app_bar.dart';
import 'package:moonwallet/widgets/func/transactions/transactions_body/transaction_container.dart';

class CustomizationParentContainer extends StatelessWidget {
  final AppColors colors;
  final String title;
  final List<Widget> actions;
  final List<Widget> children;
  final Widget bottom;
  const CustomizationParentContainer({
    super.key,
    required this.colors,
    required this.title,
    required this.actions,
    required this.children,
    required this.bottom,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Material(
          color: colors.primaryColor,
          child: TransactionContainer(
            padding: const EdgeInsets.all(30),
            colors: colors,
            child: SpaceWithFixedBottom(
                body: Column(
                  children: [
                    TransactionAppBar(
                      padding: const EdgeInsets.only(bottom: 10),
                      colors: colors,
                      title: title,
                      actions: actions,
                    ),
                    ...children,
                  ],
                ),
                bottom: bottom),
          )),
    );
  }
}
