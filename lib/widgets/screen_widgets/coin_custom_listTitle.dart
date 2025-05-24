import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:moonwallet/custom/web3_webview/lib/utils/loading.dart';
import 'package:moonwallet/notifiers/providers.dart';
import 'package:moonwallet/screens/dashboard/main/wallet_overview.dart';
import 'package:moonwallet/types/account_related_types.dart';
import 'package:moonwallet/types/types.dart';
import 'package:moonwallet/utils/number_formatter.dart';
import 'package:moonwallet/widgets/screen_widgets/crypto_picture.dart';

typedef DoubleFactor = double Function(double size);

class CoinCustomListTitle extends HookConsumerWidget {
  final AppColors colors;
  final Crypto crypto;
  final PublicAccount currentAccount;
  final DoubleFactor roundedOf;
  final DoubleFactor fontSizeOf;
  final DoubleFactor iconSizeOf;
  final DoubleFactor imageSizeOf;
  final DoubleFactor listTitleHorizontalOf;
  final DoubleFactor listTitleVerticalOf;
  final String cryptoPrice;
  final String trend;
  final bool isCryptoHidden;
  final String tokenBalance;
  final String usdBalance;

  const CoinCustomListTitle(
      {super.key,
      required this.colors,
      required this.crypto,
      required this.currentAccount,
      required this.cryptoPrice,
      required this.trend,
      required this.isCryptoHidden,
      required this.tokenBalance,
      required this.usdBalance,
      required this.fontSizeOf,
      required this.iconSizeOf,
      required this.imageSizeOf,
      required this.roundedOf,
      required this.listTitleHorizontalOf,
      required this.listTitleVerticalOf});

  @override
  Widget build(BuildContext context, ref) {
    final savedCryptoManager = ref.watch(savedCryptosProviderNotifier.notifier);

    final textTheme = TextTheme.of(context);

    String formatDecimals(String value) {
      return NumberFormatter().formatDecimal(value);
    }

    final width = MediaQuery.of(context).size.width;
    return Slidable(
        endActionPane: ActionPane(
          motion: ScrollMotion(),
          children: [
            SlidableAction(
              backgroundColor: colors.secondaryColor,
              borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(10),
                  bottomLeft: Radius.circular(10)),
              onPressed: (context) async {
                await savedCryptoManager
                    .toggleCanDisplay(crypto, false)
                    .withLoading(context, colors);
              },
              icon: Icons.visibility_off,
              label: "Disable",
            )
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              vertical: 4,
            ),
            child: ListTile(
              textColor: colors.secondaryColor,
              visualDensity: VisualDensity(vertical: -4, horizontal: 2),
              contentPadding: const EdgeInsets.symmetric(horizontal: 15),
              splashColor: colors.textColor.withOpacity(0.05),
              onTap: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => WalletViewScreen(
                                initData: WidgetInitialData(
                              cryptoPrice: cryptoPrice,
                              account: currentAccount,
                              crypto: crypto,
                              colors: colors,
                              initialBalanceUsd: usdBalance,
                              initialBalanceCrypto: tokenBalance,
                            ))));
              },
              leading: CryptoPicture(
                  crypto: crypto, size: imageSizeOf(38), colors: colors),
              title: LayoutBuilder(builder: (ctx, c) {
                final children = [
                  Text(crypto.symbol.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.bodyMedium?.copyWith(
                          fontSize: fontSizeOf(13),
                          fontWeight: FontWeight.w600,
                          color: colors.textColor)),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                        color: colors.secondaryColor.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(20)),
                    child: Text(
                        !crypto.isNative
                            ? "${crypto.network?.name}"
                            : crypto.name,
                        style: textTheme.bodySmall?.copyWith(
                            fontSize: fontSizeOf(10),
                            color: colors.textColor,
                            fontWeight: FontWeight.w500)),
                  )
                ];
                if (c.maxWidth < 140) {
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 8,
                    children: children,
                  );
                }
                return Row(
                  spacing: 8,
                  children: children,
                );
              }),
              subtitle: Row(
                spacing: 2,
                children: [
                  Text(formatDecimals(cryptoPrice.toString()),
                      style: textTheme.bodySmall?.copyWith(
                        color: colors.textColor.withOpacity(0.6),
                        fontSize: fontSizeOf(12.88),
                      )),
                  if (trend != 0)
                    Text(
                      " ${double.parse(trend).toStringAsFixed(2)}%",
                      style: textTheme.bodySmall?.copyWith(
                        color: double.parse(trend) > 0
                            ? colors.greenColor
                            : colors.redColor,
                        fontSize: fontSizeOf(12.88),
                      ),
                    ),
                ],
              ),
              trailing: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: width * 0.37),
                child: Column(
                  spacing: 2,
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                        isCryptoHidden
                            ? "***"
                            : NumberFormatter()
                                .formatValue(str: tokenBalance)
                                .trim(),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                        style: textTheme.bodyMedium?.copyWith(
                            fontSize: fontSizeOf(13),
                            color: colors.textColor,
                            fontWeight: FontWeight.w600)),
                    Text(
                        isCryptoHidden
                            ? "***"
                            : "\$${NumberFormatter().formatValue(
                                  str: usdBalance,
                                  maxDecimals: 2,
                                ).trim()}",
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                        style: textTheme.bodySmall?.copyWith(
                            color: colors.textColor.withOpacity(0.6),
                            fontSize: fontSizeOf(12.88),
                            fontWeight: FontWeight.w500))
                  ],
                ),
              ),
            ),
          ),
        ));
  }
}
