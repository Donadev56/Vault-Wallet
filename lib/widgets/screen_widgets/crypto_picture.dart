import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:moonwallet/types/account_related_types.dart';
import 'package:moonwallet/types/types.dart';

class CryptoPicture extends HookConsumerWidget {
  final Crypto crypto;
  final double size;
  final AppColors colors;
  final Color? primaryColor;
  final double radius;

  const CryptoPicture(
      {super.key,
      this.primaryColor,
      required this.crypto,
      required this.size,
      this.radius = 50,
      required this.colors});

  @override
  Widget build(BuildContext context, ref) {
    final cryptoSymbolStart = useMemoized(() {
      return crypto.symbol.length > 1
          ? crypto.symbol.substring(0, 1)
          : crypto.symbol;
    });

    errorBuilder(double targetSize) => useMemoized(() {
          return ((context, obj, trace) {
            return buildPlaceHolder(
                cryptoSymbolStart, size, radius, colors, context);
          });
        });

    bool isSvg(String path) {
      return path.toLowerCase().endsWith('.svg');
    }

    return Stack(
      children: [
        ClipRRect(
            borderRadius: BorderRadius.circular(radius),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(radius),
              child: SizedBox(
                  width: size,
                  height: size,
                  child: crypto.icon != null && !isSvg(crypto.icon ?? "")
                      ? Image.network(
                          errorBuilder: errorBuilder(size),
                          crypto.icon ?? "",
                          width: size,
                          height: size,
                          fit: BoxFit.cover,
                        )
                      : crypto.icon == null
                          ? buildPlaceHolder(
                              cryptoSymbolStart, size, radius, colors, context)
                          : SvgPicture.network(
                              crypto.icon ?? "",
                              errorBuilder: errorBuilder(size),
                              width: size,
                              height: size,
                              fit: BoxFit.cover,
                            )),
            )),
        if (!crypto.isNative)
          Positioned(
              top: size / 1.8,
              left: size / 1.8,
              child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(radius),
                    color: primaryColor ?? colors.primaryColor,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(radius),
                    child: crypto.network?.icon == null
                        ? buildPlaceHolder(
                            "", size / 2.75, radius, colors, context)
                        : !isSvg(crypto.network?.icon ?? "")
                            ? Image.network(
                                crypto.network?.icon ?? "",
                                width: size / 2.75,
                                height: size / 2.75,
                                errorBuilder: errorBuilder(size / 2.75),
                              )
                            : SvgPicture.network(
                                crypto.network?.icon ?? "",
                                width: size / 2.75,
                                height: size / 2.75,
                                errorBuilder: errorBuilder(size / 2.75),
                              ),
                  )))
      ],
    );
  }
}

Widget buildPlaceHolder(
  String symbol,
  double size,
  double radius,
  AppColors colors,
  BuildContext context,
) {
  return Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
        color: colors.textColor.withOpacity(0.6),
        borderRadius: BorderRadius.circular(radius)),
    child: Center(
      child: Text(
        symbol,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: colors.primaryColor,
            fontWeight: FontWeight.bold,
            fontSize: 18),
      ),
    ),
  );
}
