import 'package:flutter/material.dart';
import 'package:moonwallet/types/types.dart';
import 'package:moonwallet/utils/number_formatter.dart';
import 'package:moonwallet/widgets/screen_widgets/crypto_picture.dart';

class TransactionTokenDetails extends StatelessWidget {
  final AppColors colors;
  final Crypto crypto;
  final String value;
  const TransactionTokenDetails({
    super.key,
    required this.colors,
    required this.crypto,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final formatter = NumberFormatter();
    return Align(
      alignment: Alignment.center,
      child: Material(
        color: Colors.transparent,
        child: ListTile(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          tileColor: colors.secondaryColor,
          leading: CryptoPicture(
            crypto: crypto,
            size: 40,
            colors: colors,
            primaryColor: colors.secondaryColor,
          ),
          title: Text(
            "${formatter.formatValue(str: (formatter.formatDecimal(value)))} ${crypto.symbol}",
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
            style: textTheme.bodyMedium?.copyWith(
                color: colors.textColor,
                fontWeight: FontWeight.w900,
                overflow: TextOverflow.ellipsis,
                fontSize: 17),
          ),
          subtitle: Text(
              "${crypto.isNative ? crypto.name : crypto.network?.name}",
              style: textTheme.bodyMedium?.copyWith(
                  color: colors.textColor.withOpacity(0.5),
                  fontWeight: FontWeight.w900,
                  fontSize: 15)),
        ),
      ),
    );
  }
}
