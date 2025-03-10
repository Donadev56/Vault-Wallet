import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:moonwallet/types/types.dart';
import 'package:moonwallet/widgets/barre.dart';

selectAnAccount(
    {required AppColors colors,
    required BuildContext context,
    required List<PublicData> accounts,
    required void Function(PublicData w) onTap}) {
  showModalBottomSheet(
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
              topLeft: Radius.circular(30), topRight: Radius.circular(30))),
      context: context,
      builder: (ctx) {
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
                                  return ListTile(
                                    onTap: () {
                                      onTap(w);
                                      Navigator.pop(context);
                                    },
                                    leading: Icon(
                                      w.walletIcon ?? LucideIcons.walletCards,
                                      color: colors.textColor,
                                    ),
                                    title: Text(
                                      w.walletName,
                                      style: GoogleFonts.roboto(
                                          color: colors.textColor),
                                    ),
                                    subtitle: Text(
                                      w.address,
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                      style: GoogleFonts.roboto(
                                          color:
                                              colors.textColor.withOpacity(0.5),
                                          fontSize: 12),
                                    ),
                                  );
                                })),
                      ],
                    ),
                  ));
            });
      });
}
