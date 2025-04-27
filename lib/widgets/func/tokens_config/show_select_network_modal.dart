import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:moonwallet/types/types.dart';
import 'package:moonwallet/widgets/screen_widgets/crypto_picture.dart';

Future<Crypto?> showSelectNetworkModal(
    {required BuildContext context,
    required AppColors colors,
    required DoubleFactor roundedOf,
    required DoubleFactor fontSizeOf,
    required DoubleFactor iconSizeOf,
    required List<Crypto> networks}) {
  final response = showBarModalBottomSheet<Crypto>(
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
              topLeft: Radius.circular((30)), topRight: Radius.circular((30)))),
      backgroundColor: colors.primaryColor,
      context: context,
      builder: (ctx) {
        final textTheme = TextTheme.of(ctx);
        return Material(
            color: Colors.transparent,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: networks.where((crypto) => crypto.isNative).length,
              itemBuilder: (ctx, i) {
                final crypto =
                    networks.where((crypto) => crypto.isNative).toList()[i];
                return ListTile(
                  leading: CryptoPicture(
                      crypto: crypto, size: iconSizeOf(30), colors: colors),
                  title: Text(crypto.name,
                      style: textTheme.bodyMedium
                          ?.copyWith(color: colors.textColor)),
                  onTap: () {
                    Navigator.pop(context, crypto);
                  },
                  trailing: Icon(
                    LucideIcons.chevronRight,
                    color: colors.textColor,
                  ),
                );
              },
            ));
      });

  return response;
}
