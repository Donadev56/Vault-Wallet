import 'package:flutter/material.dart';
import 'package:moonwallet/types/account_related_types.dart';
import 'package:moonwallet/types/types.dart';
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
    return TransactionContainer(
      backgroundColor: colors.secondaryColor,
      colors: colors,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "From ",
                style: textTheme.bodyMedium
                    ?.copyWith(color: colors.textColor, fontSize: 14),
              ),
              Text(
                "${from.substring(0, 6)}...${from.substring(from.length - 6)}",
                style: textTheme.bodyMedium
                    ?.copyWith(color: colors.textColor, fontSize: 14),
              ),
            ],
          ),
          Divider(
            color: colors.textColor.withValues(alpha: 0.1),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "To",
                style: textTheme.bodyMedium?.copyWith(
                    color: colors.textColor,
                    fontSize: 14,
                    fontWeight: FontWeight.normal),
              ),
              Text(
                "${to.substring(0, 6)}...${to.substring(to.length - 6)}",
                style: textTheme.bodyMedium?.copyWith(
                    color: colors.textColor,
                    fontSize: 14,
                    fontWeight: FontWeight.normal),
              ),
            ],
          )
        ],
      ),
    );
  }
}
