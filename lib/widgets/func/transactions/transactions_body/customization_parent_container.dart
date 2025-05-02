import 'package:flutter/material.dart';
import 'package:moonwallet/types/types.dart';
import 'package:moonwallet/widgets/dialogs/standard_container.dart';
import 'package:moonwallet/widgets/func/transactions/transactions_body/transaction_app_bar.dart';

class CustomizationParentContainer extends StatelessWidget {
  final AppColors colors;
  final String title;
  final List<Widget> actions;
  final List<Widget> children;
  const CustomizationParentContainer({
    super.key,
    required this.colors,
    required this.title,
    required this.actions,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Material(
          color: Colors.transparent,
          child: StandardContainer(
              colors: colors,
              child: ListView(
                children: [
                  TransactionAppBar(
                    colors: colors,
                    title: title,
                    actions: actions,
                  ),
                  ...children,
                ],
              ))),
    );
  }
}
