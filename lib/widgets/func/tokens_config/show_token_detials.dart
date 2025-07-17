import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:moonwallet/logger/logger.dart';
import 'package:moonwallet/service/external_data/price_manager.dart';
import 'package:moonwallet/service/rpc_service.dart';
import 'package:moonwallet/service/web3_interactions/evm/token_manager.dart';
import 'package:moonwallet/types/account_related_types.dart';
import 'package:moonwallet/types/types.dart';
import 'package:moonwallet/utils/constant.dart';
import 'package:moonwallet/utils/number_formatter.dart';
import 'package:moonwallet/widgets/buttons/elevated.dart';
import 'package:moonwallet/widgets/buttons/elevated_low_opacity_button.dart';
import 'package:moonwallet/widgets/dialogs/row_details.dart';
import 'package:moonwallet/widgets/dialogs/show_standard_sheet.dart';
import 'package:moonwallet/widgets/dialogs/standard_container.dart';
import 'package:moonwallet/widgets/screen_widgets/crypto_picture.dart';
import 'package:url_launcher/url_launcher.dart';

void showTokenDetails(
    {required BuildContext context,
    required AppColors colors,
    required Crypto crypto,
    required PublicAccount currentAccount,
    required Nodes nodes}) {
  showStandardModalBottomSheet(
    context: context,
    builder: (context) => TokenDetailsWidget(
        colors: colors, crypto: crypto, account: currentAccount, nodes: nodes),
  );
}

class TokenDetailsWidget extends StatefulHookConsumerWidget {
  final AppColors colors;
  final Crypto crypto;
  final PublicAccount account;
  final Nodes nodes;
  const TokenDetailsWidget({
    super.key,
    required this.colors,
    required this.crypto,
    required this.account,
    required this.nodes,
  });

  @override
  ConsumerState<TokenDetailsWidget> createState() => _TokenDetailsWidgetState();
}

class _TokenDetailsWidgetState extends ConsumerState<TokenDetailsWidget> {
  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final nodes = useMemoized(() => widget.nodes, []);
    final crypto = useMemoized(() => widget.crypto);
    final currentAccount = useMemoized(() => widget.account, []);
    final colors = useMemoized(() => widget.colors, []);
    final tokenInfo = useState<(String, String)>(("0.00", "0.00"));
    final tokenInfoLoading = useState(true);

    void copy(String text) {
      Clipboard.setData(ClipboardData(text: text));
    }

    final priceManager = PriceManager();

    Future<void> getTokenInfo() async {
      try {
        final services = RpcService(nodes.availableNode(crypto.getChainId));
        final [priceData, balance] = await Future.wait([
          priceManager.getPriceDataV2(crypto),
          services.getBalance(crypto, currentAccount)
        ]);
        final price = (priceData as (String, double)).$1;
        tokenInfo.value = (price, balance as String);
      } catch (e) {
        logError(e.toString());
      } finally {
        tokenInfoLoading.value = false;
      }
    }

    useEffect(() {
      getTokenInfo();
      return null;
    }, []);
    return Material(
      color: colors.primaryColor,
      child: SelectableRegion(
          selectionControls: materialTextSelectionControls,
          child: StandardContainer(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 30),
            child: ListView(
              shrinkWrap: true,
              children: [
                SizedBox(
                  height: 15,
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      spacing: 15,
                      children: [
                        CryptoPicture(crypto: crypto, size: 60, colors: colors),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              crypto.symbol,
                              style: textTheme.bodyLarge?.copyWith(
                                  color: colors.textColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20),
                            ),
                            Text(
                              crypto.name,
                              style: textTheme.bodySmall?.copyWith(
                                  color:
                                      colors.textColor.withValues(alpha: 0.8),
                                  fontSize: 12),
                            )
                          ],
                        )
                      ],
                    ),
                    IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: Icon(
                          LucideIcons.x,
                          color: colors.textColor,
                        ))
                  ],
                ),
                SizedBox(
                  height: 10,
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.start,
                  spacing: 10,
                  children: [
                    Text(
                      "Current price",
                      style: textTheme.bodySmall?.copyWith(
                          color: colors.textColor.withValues(alpha: 0.8),
                          fontSize: 14),
                    ),
                    if (tokenInfoLoading.value)
                      SizedBox(
                        width: 25,
                        height: 25,
                        child: CircularProgressIndicator(
                          color: colors.textColor,
                        ),
                      )
                    else
                      Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "\$${NumberFormatter().formatValue(str: tokenInfo.value.$1)}",
                            style: textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w900,
                                fontSize: 25,
                                color: colors.textColor),
                          ),
                        ],
                      )
                  ],
                ),
                SizedBox(
                  height: 10,
                ),
                Column(
                  spacing: 5,
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Contract Address",
                      style: textTheme.bodySmall?.copyWith(
                          color: colors.textColor.withValues(alpha: 0.8),
                          fontSize: 14),
                    ),
                    Row(
                      children: [
                        Text(
                          truncatedValue(
                              (crypto.isNative
                                      ? "0x0000000000000000000000000000000000000000"
                                      : crypto.contractAddress) ??
                                  "Null",
                              max: 5),
                          style: textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: colors.textColor),
                        ),
                        SizedBox(
                          width: 10,
                        ),
                        GestureDetector(
                            onTap: () => copy(crypto.contractAddress ?? "Null"),
                            child: Icon(
                              Icons.content_copy,
                              color: colors.textColor,
                            )),
                        SizedBox(
                          width: 8,
                        ),
                        GestureDetector(
                            onTap: () {
                              if (crypto.isNative) {
                                launchUrl(Uri.parse(
                                    crypto.explorers?.firstOrNull ?? '#'));
                                return;
                              }
                              launchUrl(Uri.parse(
                                  "${crypto.network?.explorers?.firstOrNull}/address/${crypto.contractAddress}"));
                            },
                            child: Icon(
                              Icons.open_in_new,
                              color: colors.textColor,
                            )),
                        SizedBox(
                          width: 8,
                        ),
                        if (!crypto.isNative)
                          GestureDetector(
                            onTap: () => showTokenDetails(
                                context: context,
                                colors: colors,
                                crypto: crypto.network!,
                                currentAccount: currentAccount,
                                nodes: nodes),
                            child: CryptoPicture(
                                crypto: crypto.network!,
                                size: 20,
                                colors: colors),
                          ),
                        SizedBox(
                          width: 5,
                        ),
                      ],
                    )
                  ],
                ),
                SizedBox(
                  height: 15,
                ),
                Column(
                  spacing: 5,
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Balance",
                      style: textTheme.bodySmall?.copyWith(
                          color: colors.textColor.withValues(alpha: 0.8),
                          fontSize: 14),
                    ),
                    Row(
                      children: [
                        Text(
                          "${NumberFormatter().formatValue(str: tokenInfo.value.$2)} ${crypto.symbol}",
                          style: textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: colors.textColor),
                        ),
                      ],
                    )
                  ],
                ),
                SizedBox(
                  height: 15,
                ),
                CustomElevatedButton(
                  colors: colors,
                  text: "Close",
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  textColor: colors.primaryColor,
                  backgroundColor: colors.textColor,
                  rounded: 10,
                ),
              ],
            ),
          )),
    );
  }
}
/*
void showTokenDetails(
    {required BuildContext context,
    required AppColors colors,
    required Crypto crypto}) {
  void copy(String text) {
    Clipboard.setData(ClipboardData(text: text));
  }

  showStandardModalBottomSheet(
    context: context,
    builder: (context) {
      final textTheme = TextTheme.of(context);
      return Material(
        color: colors.primaryColor,
        child: SelectableRegion(
            selectionControls: materialTextSelectionControls,
            child: StandardContainer(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
              child: ListView(
                shrinkWrap: true,
                children: [
                  SizedBox(
                    height: 5,
                  ),
                  Align(
                    alignment: Alignment.center,
                    child:
                        CryptoPicture(crypto: crypto, size: 60, colors: colors),
                  ),
                  SizedBox(
                    height: 10,
                  ),
                  Align(
                    alignment: Alignment.center,
                    child: Text(
                      crypto.symbol,
                      style: textTheme.bodyMedium?.copyWith(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: colors.textColor),
                    ),
                  ),
                  SizedBox(
                    height: 30,
                  ),
                  Column(
                    children: [
                      StandardContainer(
                          padding: const EdgeInsets.symmetric(
                              vertical: 10, horizontal: 20),
                          backgroundColor: colors.secondaryColor,
                          child: Column(
                            children: [
                              RowDetailsContent(
                                  colors: colors,
                                  name: "Name",
                                  value: crypto.name),
                              SizedBox(
                                height: 10,
                              ),
                              RowDetailsContent(
                                  colors: colors,
                                  name: "Symbol",
                                  value: crypto.symbol),
                              SizedBox(
                                height: 10,
                              ),
                              RowDetailsContent(
                                  colors: colors,
                                  name: "Decimals",
                                  value: crypto.decimals.toString()),
                              SizedBox(
                                height: 10,
                              ),
                              RowDetailsContent(
                                  colors: colors,
                                  name: "Type",
                                  value: crypto.isNative ? "Native" : "Token"),
                              SizedBox(
                                height: 10,
                              ),
                            ],
                          )),
                      SizedBox(
                        height: 15,
                      ),
                      StandardContainer(
                          padding: const EdgeInsets.symmetric(
                              vertical: 10, horizontal: 20),
                          backgroundColor: colors.secondaryColor,
                          child: Column(
                            children: [
                              if (crypto.isNative)
                                RowDetailsContent(
                                    onClick: () => copy(crypto.getRpcUrl),
                                    colors: colors,
                                    name: "Rpc Url",
                                    value: (crypto.getRpcUrl)),
                              if (!crypto.isNative)
                                RowDetailsContent(
                                    onClick: () =>
                                        copy(crypto.contractAddress ?? ""),
                                    colors: colors,
                                    name: "Token Address",
                                    value:
                                        "${crypto.contractAddress?.substring(0, 10)}..."),
                              SizedBox(
                                height: 10,
                              ),
                              RowDetailsContent(
                                  underline: !crypto.isNative ? true : false,
                                  colors: colors,
                                  onClick: () {
                                    if (crypto.isNative) {
                                      return;
                                    }
                                    final network = crypto.network;
                                    if (network == null) {
                                      return;
                                    }
                                    showTokenDetails(
                                        context: context,
                                        colors: colors,
                                        crypto: network);
                                  },
                                  name: "Network",
                                  value: (crypto.isNative
                                          ? crypto.name
                                          : crypto.network?.name) ??
                                      "Not Found"),
                            ],
                          ))
                    ],
                  ),
                ],
              ),
            )),
      );
    },
  );
}

*/
