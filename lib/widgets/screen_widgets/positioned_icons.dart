import 'package:flutter/material.dart';
import 'package:moonwallet/types/account_related_types.dart';
import 'package:moonwallet/types/types.dart';
import 'package:moonwallet/widgets/screen_widgets/crypto_picture.dart';

class PositionedIcons extends StatelessWidget {
  final List<Crypto> cryptos;
  final AppColors colors;
  final DoubleFactor imageSizeOf;
  const PositionedIcons(
      {super.key,
      required this.cryptos,
      required this.colors,
      required this.imageSizeOf});

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: cryptos
          .asMap()
          .entries
          .map((entry) {
            int index = entry.key;
            var crypto = entry.value;
            return Positioned(
                left: index * 18.0,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                      color: colors.primaryColor,
                      borderRadius: BorderRadius.circular(20)),
                  child: CryptoPicture(
                      crypto: crypto, size: imageSizeOf(24), colors: colors),
                ));
          })
          .toList()
          .reversed
          .toList(),
    );
  }
}
