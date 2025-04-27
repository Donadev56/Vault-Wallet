// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:jazzicon/jazzicon.dart';
import 'package:jazzicon/jazziconshape.dart';
import 'package:moonwallet/types/types.dart';

class AccountListViewWidget extends StatelessWidget {
  final PublicData wallet;
  final Function() onTap;
  final Function() onMoreTap;
  final Color? tileColor;
  final bool showMore;
  final bool isCurrent;

  final DoubleFactor roundedOf;
  final DoubleFactor fontSizeOf;
  final DoubleFactor iconSizeOf;
  final DoubleFactor imageSizeOf;
  final DoubleFactor listTitleHorizontalOf;
  final DoubleFactor listTitleVerticalOf;

  final AppColors colors;
  const AccountListViewWidget(
      {super.key,
      this.showMore = true,
      this.isCurrent = false,
      required this.colors,
      required this.wallet,
      required this.onTap,
      required this.onMoreTap,
      this.tileColor,
      required this.fontSizeOf,
      required this.iconSizeOf,
      required this.imageSizeOf,
      required this.listTitleHorizontalOf,
      required this.listTitleVerticalOf,
      required this.roundedOf});

  @override
  Widget build(BuildContext context) {
    JazziconData getJazzImage(String address) {
      return Jazzicon.getJazziconData(35, address: address);
    }

    final textTheme = Theme.of(context).textTheme;
    return ListTile(
        tileColor: tileColor,
        visualDensity: VisualDensity(horizontal: (0), vertical: (-4)),
        contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 10),
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        leading: Jazzicon.getIconWidget(getJazzImage(wallet.address),
            size: imageSizeOf(35)),
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
                      fontSize: fontSizeOf(16)),
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
                      fontSize: fontSizeOf(11)),
                ),
              )
          ],
        ),
        subtitle: Text(
          "${wallet.address.substring(0, 9)}...${wallet.address.substring(wallet.address.length - 6, wallet.address.length)}",
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: textTheme.bodySmall?.copyWith(
              color: colors.textColor.withOpacity(0.4),
              fontSize: fontSizeOf(12)),
        ),
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
