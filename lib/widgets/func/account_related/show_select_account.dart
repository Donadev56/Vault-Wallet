// ignore_for_file: deprecated_member_use

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:moonwallet/types/account_related_types.dart';
import 'package:moonwallet/types/types.dart';
import 'package:moonwallet/widgets/barre.dart';

selectAnAccount(
    {required AppColors colors,
    required Crypto crypto,
    required BuildContext context,
    required List<PublicAccount> accounts,
    required PublicAccount currentAccount,
    required void Function(PublicAccount wallet) onTap}) {
  showModalBottomSheet(
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
              topLeft: Radius.circular(30), topRight: Radius.circular(30))),
      context: context,
      builder: (ctx) {
        final textTheme = Theme.of(context).textTheme;

        return DraggableScrollableSheet(
            initialChildSize: 0.3,
            minChildSize: 0.2,
            maxChildSize: 0.9,
            expand: false,
            builder: (ctx, cr) {
              return BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
                  child: Container(
                    height: MediaQuery.of(context).size.height * 0.7,
                    decoration: BoxDecoration(
                        color: colors.primaryColor,
                        borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(30),
                            topRight: Radius.circular(30))),
                    child: Column(
                      children: [
                        DraggableBar(colors: colors),
                        Expanded(
                            child: ListView.builder(
                                controller: cr,
                                itemCount: accounts.length,
                                itemBuilder: (ctx, i) {
                                  final w = accounts[i];
                                  return Material(
                                    color: Colors.transparent,
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 5, horizontal: 10),
                                      child: ListTile(
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(10)),
                                        visualDensity: VisualDensity(
                                            horizontal: 0, vertical: -4),
                                        tileColor: w.keyId ==
                                                currentAccount.keyId
                                            ? colors.themeColor.withOpacity(0.2)
                                            : Colors.transparent,
                                        onTap: () {
                                          onTap(w);
                                          Navigator.pop(context);
                                        },
                                        leading: Icon(
                                          w.walletIcon ??
                                              LucideIcons.walletCards,
                                          color: colors.textColor,
                                        ),
                                        title: Text(
                                          w.walletName,
                                          style: textTheme.bodyMedium,
                                        ),
                                        subtitle: Text(
                                          w.addressByToken(crypto),
                                          overflow: TextOverflow.ellipsis,
                                          maxLines: 1,
                                          style: textTheme.bodySmall?.copyWith(
                                              fontSize: 12,
                                              color: colors.textColor
                                                  .withOpacity(0.5)),
                                        ),
                                      ),
                                    ),
                                  );
                                })),
                      ],
                    ),
                  ));
            });
      });
}
