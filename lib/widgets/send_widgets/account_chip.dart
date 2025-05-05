import 'package:flutter/material.dart';
import 'package:moonwallet/types/account_related_types.dart';
import 'package:moonwallet/types/types.dart';

class AccountChip extends StatelessWidget {
  final AppColors colors;
  final DoubleFactor roundedOf;
  final PublicAccount currentAccount;
  final DoubleFactor fontSizeOf;
  const AccountChip({
    super.key,
    required this.colors,
    required this.currentAccount,
    required this.fontSizeOf,
    required this.roundedOf,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = TextTheme.of(context);
    return Container(
        padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
        decoration: BoxDecoration(
          color: colors.secondaryColor,
          borderRadius: BorderRadius.circular(roundedOf(15)),
        ),
        child: Center(
          child: Text(
            currentAccount.walletName,
            style: textTheme.bodyMedium
                ?.copyWith(color: colors.textColor, fontSize: fontSizeOf(14)),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ));
  }
}
