// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';

import 'package:moonwallet/types/account_related_types.dart';
import 'package:moonwallet/types/types.dart';

class AccountListTitleWidget extends StatelessWidget {
  final PublicAccount wallet;
  final Function() onTap;
  final Function() onMoreTap;
  final bool showMore;
  final bool isCurrent;

  final DoubleFactor roundedOf;
  final DoubleFactor fontSizeOf;
  final DoubleFactor iconSizeOf;
  final DoubleFactor imageSizeOf;

  final AppColors colors;
  const AccountListTitleWidget(
      {super.key,
      this.showMore = true,
      this.isCurrent = false,
      required this.colors,
      required this.wallet,
      required this.onTap,
      required this.onMoreTap,
      required this.fontSizeOf,
      required this.iconSizeOf,
      required this.imageSizeOf,
      required this.roundedOf});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    final subtileStyle = textTheme.bodySmall?.copyWith(
        color: colors.textColor.withOpacity(0.4), fontSize: fontSizeOf(12));
    Widget? icon;

    Widget? subtitle;
    if (wallet.origin.isMnemonic) {
      subtitle = Text(
        "Mnemonic",
        style: subtileStyle,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      );
      icon = AccountTypeIconContainer(
          account: wallet,
          colors: colors,
          imageSizeOf: imageSizeOf,
          icon: Icon(
            Icons.wallet,
            color: colors.textColor.withValues(alpha: 0.8),
          ));
    } else {
      final publicAddress =
          wallet.addresses.isNotEmpty ? wallet.addresses.first : null;
      final address = publicAddress?.address;
      if (address != null) {
        subtitle = Text(
          "${address.substring(0, 9)}...${address.substring(address.length - 6, address.length)}",
          style: subtileStyle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        );
        icon = AccountTypeIconContainer(
            account: wallet,
            colors: colors,
            imageSizeOf: imageSizeOf,
            icon: Icon(
              wallet.origin.isPrivateKey ? Icons.key : Icons.remove_red_eye,
              color: colors.textColor.withValues(alpha: 0.8),
            ));
      } else {
        subtitle = null;
        icon = null;
      }
    }

    return ListTile(
        visualDensity: VisualDensity(horizontal: (0), vertical: (-4)),
        contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 10),
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        leading: icon,
        title: Row(
          spacing: 5,
          children: [
            LayoutBuilder(builder: (ctx, c) {
              return ConstrainedBox(
                constraints: BoxConstraints(
                    maxWidth: wallet.isWatchOnly
                        ? MediaQuery.of(ctx).size.width * 0.16
                        : MediaQuery.of(ctx).size.width * 0.4),
                child: Text(
                  wallet.walletName,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.bodyMedium?.copyWith(
                      color: colors.textColor,
                      fontWeight: FontWeight.w500,
                      fontSize: fontSizeOf(14)),
                ),
              );
            }),
            if (wallet.isWatchOnly)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 6),
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(roundedOf(20)),
                    color: colors.secondaryColor.withOpacity(0.2),
                    border: Border.all(color: colors.secondaryColor)),
                child: Text(
                  "Watch Only",
                  style: textTheme.bodySmall?.copyWith(
                      color: colors.textColor.withOpacity(0.8),
                      fontSize: fontSizeOf(10)),
                ),
              ),
            if (!wallet.isBackup && wallet.createdLocally)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 6),
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(roundedOf(20)),
                    color: colors.secondaryColor.withOpacity(0.2),
                    border: Border.all(color: Colors.orange)),
                child: Text(
                  "No Backup",
                  style: textTheme.bodySmall?.copyWith(
                      color: Colors.orange.withOpacity(0.8),
                      fontSize: fontSizeOf(10)),
                ),
              )
          ],
        ),
        subtitle: subtitle,
        trailing: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 80),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (isCurrent)
                Icon(
                  Icons.check,
                  color: colors.greenColor,
                ),
              if (showMore)
                IconButton(
                    onPressed: onMoreTap,
                    icon: Icon(
                      Icons.more_vert,
                      color: colors.textColor,
                    ))
            ],
          ),
        ));
  }
}

class AccountTypeIconContainer extends StatelessWidget {
  final DoubleFactor imageSizeOf;
  final AppColors colors;
  final PublicAccount account;
  final Widget icon;
  const AccountTypeIconContainer(
      {super.key,
      required this.colors,
      required this.imageSizeOf,
      required this.icon,
      required this.account});

  @override
  Widget build(BuildContext context) {
    Color color;
    if (account.walletColor == null) {
      color = colors.secondaryColor;
    } else if (account.walletColor?.value == 0x00000000) {
      color = colors.secondaryColor;
    } else {
      color = account.walletColor!;
    }

    return Container(
        width: imageSizeOf(40),
        height: imageSizeOf(40),
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(50), color: color),
        child: Center(
          child: icon,
        ));
  }
}
