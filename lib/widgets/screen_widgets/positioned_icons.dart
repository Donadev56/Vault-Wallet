import 'package:flutter/material.dart';
import 'package:moonwallet/types/account_related_types.dart';
import 'package:moonwallet/types/types.dart';
import 'package:moonwallet/widgets/screen_widgets/crypto_picture.dart';
import 'package:moonwallet/widgets/screen_widgets/positioned_icon_container.dart';

class PositionedCryptos extends StatelessWidget {
  final List<Crypto> cryptos;
  final AppColors colors;
  final DoubleFactor imageSizeOf;
  const PositionedCryptos(
      {super.key,
      required this.cryptos,
      required this.colors,
      required this.imageSizeOf});

  @override
  Widget build(BuildContext context) {
    final elements = cryptos
        .map((e) => CryptoPicture(crypto: e, size: 25, colors: colors))
        .toList();
    return PositionedIcons(
      colors: colors,
      imageSizeOf: imageSizeOf,
      children: elements,
    );
  }
}
