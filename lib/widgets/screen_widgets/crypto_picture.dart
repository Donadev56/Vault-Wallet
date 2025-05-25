import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:moonwallet/types/account_related_types.dart';
import 'package:moonwallet/types/types.dart';
import 'package:moonwallet/widgets/screen_widgets/cached_picture.dart';

class CryptoPicture extends HookConsumerWidget {
  final Crypto crypto;
  final double size;
  final AppColors colors;
  final Color? primaryColor;
  final double radius;
  final double networkRadius;

  const CryptoPicture(
      {super.key,
      this.primaryColor,
      required this.crypto,
      required this.size,
      this.radius = 50,
      this.networkRadius = 5,
      required this.colors});

  @override
  Widget build(BuildContext context, ref) {
    final cryptoSymbolStart = useMemoized(() {
      return crypto.symbol.length > 1
          ? crypto.symbol.substring(0, 1)
          : crypto.symbol;
    });
    return CachedPicture(
      crypto.icon ?? "",
      placeHolderString: cryptoSymbolStart,
      size: size,
      colors: colors,
      secondaryImageUrl: crypto.network?.icon,
      addSecondaryImage: !crypto.isNative,
    );
  }
}
