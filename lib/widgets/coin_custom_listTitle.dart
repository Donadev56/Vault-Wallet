import 'package:flutter/material.dart';
import 'package:moonwallet/logger/logger.dart';
import 'package:moonwallet/screens/dashboard/main/wallet_overview.dart';
import 'package:moonwallet/types/types.dart';
import 'package:moonwallet/utils/number_formatter.dart';
import 'package:moonwallet/widgets/crypto_picture.dart';

class CoinCustomListTitle extends StatelessWidget {
  final AppColors colors;
  final Crypto crypto;
  final PublicData currentAccount;

  final double cryptoPrice;
  final double trend;
  final bool isCryptoHidden;
  final double tokenBalance;
  final double usdBalance;

  const CoinCustomListTitle(
      {super.key,
      required this.colors,
      required this.crypto,
      required this.currentAccount,
      required this.cryptoPrice,
      required this.trend,
      required this.isCryptoHidden,
      required this.tokenBalance,
      required this.usdBalance});

  @override
  Widget build(BuildContext context) {
    final textTheme = TextTheme.of(context);

    String formatUsd(String value) {
      return NumberFormatter().formatUsd(value: value);
    }

    String formatCrypto(String value) {
      return NumberFormatter().formatUsd(value: value);
    }

    final width = MediaQuery.of(context).size.width;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Material(
          color: Colors.transparent,
          child: ListTile(
            visualDensity: VisualDensity.compact,
            splashColor: colors.textColor.withOpacity(0.05),
            onTap: () {
              log("Crypto id ${crypto.cryptoId}");
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => WalletViewScreen(
                              initData: WidgetInitialData(
                            account: currentAccount,
                            crypto: crypto,
                            colors: colors,
                            initialBalanceUsd: usdBalance,
                            initialBalanceCrypto: tokenBalance,
                          ))));
            },
            leading: CryptoPicture(crypto: crypto, size: 38, colors: colors),
            title: LayoutBuilder(builder: (ctx, c) {
              return Row(
                spacing: 10,
                children: [
                  ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: c.maxWidth * 0.4),
                    child: Text(crypto.symbol.toUpperCase(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: colors.textColor)),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                    decoration: BoxDecoration(
                        color:
                            colors.grayColor.withOpacity(0.9).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20)),
                    child: Text(
                        crypto.type == CryptoType.token
                            ? "${crypto.network?.name}"
                            : crypto.name,
                        style: textTheme.bodySmall?.copyWith(
                            fontSize: 10,
                            color: colors.textColor,
                            fontWeight: FontWeight.w500)),
                  )
                ],
              );
            }),
            subtitle: Row(
              spacing: 2,
              children: [
                Text(formatUsd(cryptoPrice.toString()),
                    style: textTheme.bodySmall?.copyWith(
                      color: colors.textColor.withOpacity(0.6),
                      fontSize: 14,
                    )),
                if (trend != 0)
                  Text(
                    " ${(trend).toStringAsFixed(2)}%",
                    style: textTheme.bodySmall?.copyWith(
                      color: trend > 0 ? colors.greenColor : colors.redColor,
                      fontSize: 14,
                    ),
                  ),
              ],
            ),
            trailing: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: width * 0.37),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                      isCryptoHidden
                          ? "***"
                          : formatCrypto(tokenBalance.toString()).trim(),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                      style: textTheme.bodyMedium?.copyWith(
                          fontSize: 14,
                          color: colors.textColor,
                          fontWeight: FontWeight.w600)),
                  Text(
                      isCryptoHidden
                          ? "***"
                          : "\$${formatUsd(usdBalance.toString()).trim()}",
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                      style: textTheme.bodySmall?.copyWith(
                          color: colors.textColor.withOpacity(0.6),
                          fontSize: 14,
                          fontWeight: FontWeight.w500))
                ],
              ),
            ),
          )),
    );
  }
}
