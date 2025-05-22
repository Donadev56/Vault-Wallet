import 'package:flutter/material.dart';
import 'package:moonwallet/types/account_related_types.dart';
import 'package:moonwallet/types/types.dart';
import 'package:moonwallet/widgets/dialogs/row_details.dart';
import 'package:moonwallet/widgets/func/transactions/transactions_body/transaction_container.dart';

class TransactionDestinationDetails extends StatelessWidget {
  final AppColors colors;
  final Crypto crypto;
  final String from;
  final String to;
  const TransactionDestinationDetails({
    super.key,
    required this.colors,
    required this.crypto,
    required this.from,
    required this.to,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      spacing: 10,
      children: [
        TransactionContainer(
            backgroundColor: colors.secondaryColor,
            colors: colors,
            child: RowDetailsContent(
              colors: colors,
              name: "From",
              value: from,
              maxValueSpace: 0.7,
              truncateAddress: true,
            )),
        TransactionContainer(
            backgroundColor: colors.secondaryColor,
            colors: colors,
            child: RowDetailsContent(
              colors: colors,
              name: "To",
              value: to,
              maxValueSpace: 0.7,
              truncateAddress: true,
            ))
      ],
    );
  }
}
