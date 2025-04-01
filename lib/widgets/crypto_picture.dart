import 'package:fast_cached_network_image/fast_cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:moonwallet/types/types.dart';
import 'package:moonwallet/widgets/text.dart';

class CryptoPicture extends StatelessWidget {
  final Crypto crypto;
  final double size;
  final AppColors colors;
  final Color? primaryColor;

  const CryptoPicture(
      {super.key,
      this.primaryColor,
      required this.crypto,
      required this.size,
      required this.colors});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(50),
          child: crypto.icon != null &&
                  crypto.icon!.toLowerCase().startsWith("http")
              ?  FastCachedImage(
                  url: crypto.icon ?? "",
                  width: size,
                  height: size,
                  loadingBuilder: (ctx , data ) {
                    return  CircularProgressIndicator(color: colors.themeColor,);
                  },

              ) 
              : crypto.icon == null
                  ? Container(
                      width: size,
                      height: size,
                      decoration: BoxDecoration(
                          // ignore: deprecated_member_use
                          color: colors.textColor.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(50)),
                      child: Center(
                        child: Text(
                          crypto.symbol.length > 2
                              ? crypto.symbol.substring(0, 2)
                              : crypto.symbol,
                          style: customTextStyle(
                              color: colors.primaryColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 18),
                        ),
                      ),
                    )
                  : Image.asset(
                      crypto.icon ?? "",
                      width: size,
                      height: size,
                    ),
        ),
        if (crypto.type == CryptoType.token)
          Positioned(
              top: size / 1.8,
              left: size / 1.8,
              child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: primaryColor ?? colors.primaryColor,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Image.asset(
                      crypto.network?.icon ?? "",
                      width: size / 2.75,
                      height: size / 2.75,
                    ),
                  )))
      ],
    );
  }
}
