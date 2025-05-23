import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:moonwallet/types/account_related_types.dart';
import 'package:moonwallet/types/types.dart';
import 'package:moonwallet/widgets/screen_widgets/crypto_picture.dart';
import 'package:moonwallet/widgets/flowting_modat.dart';
import 'package:url_launcher/url_launcher.dart';

void showOtherOptions(
    {required BuildContext context,
    required DoubleFactor fontSizeOf,
    required DoubleFactor roundedOf,
    required AppColors colors,
    required Crypto currentCrypto}) async {
  showFloatingModalBottomSheet(
      backgroundColor: Colors.transparent,
      context: context,
      builder: (ctx) {
        final textTheme = Theme.of(context).textTheme;

        return Material(
            color: Colors.transparent,
            child: Container(
              decoration: BoxDecoration(
                color: colors.primaryColor,
                borderRadius: BorderRadius.all(Radius.circular(roundedOf(15))),
              ),
              child: ListView(
                shrinkWrap: true,
                children: [
                  ListTile(
                    leading: CryptoPicture(
                        crypto: currentCrypto, size: (40), colors: colors),
                    title: Text(
                      currentCrypto.symbol,
                      style: textTheme.bodyMedium?.copyWith(
                          color: colors.textColor, fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      currentCrypto.name,
                      style: textTheme.bodyMedium
                          ?.copyWith(color: colors.textColor.withOpacity(0.5)),
                    ),
                    trailing: IconButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        icon: Icon(
                          LucideIcons.x,
                          color: colors.grayColor,
                        )),
                  ),
                  Divider(
                    color: colors.textColor.withOpacity(0.1),
                  ),
                  SizedBox(
                    height: 15,
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    child: Column(
                      spacing: 20,
                      children: [
                        Align(
                          alignment: Alignment.center,
                          child: Container(
                              decoration: BoxDecoration(
                                  borderRadius:
                                      BorderRadius.circular(roundedOf(5)),
                                  color: colors.grayColor.withOpacity(0.25)),
                              child: Column(
                                children: [
                                  ListTile(
                                    onTap: () {},
                                    leading: Icon(
                                      LucideIcons.network,
                                      color: colors.textColor,
                                    ),
                                    title: Text(
                                      "Network",
                                      style: textTheme.bodyMedium?.copyWith(
                                          color: colors.textColor,
                                          fontSize: fontSizeOf(14)),
                                    ),
                                    trailing: Text(
                                      "${currentCrypto.isNative ? currentCrypto.name : currentCrypto.network?.name}",
                                      style: textTheme.bodyMedium?.copyWith(
                                          fontSize: fontSizeOf(15),
                                          color: colors.textColor
                                              .withOpacity(0.5)),
                                    ),
                                  ),
                                  ListTile(
                                    onTap: () {
                                      if (currentCrypto.isNative) return;
                                      Clipboard.setData(ClipboardData(
                                          text: currentCrypto.contractAddress ??
                                              ""));
                                    },
                                    leading: Icon(
                                      LucideIcons.scrollText,
                                      color: colors.textColor,
                                    ),
                                    title: Text(
                                      "Contract",
                                      style: textTheme.bodyMedium?.copyWith(
                                          color: colors.textColor,
                                          fontSize: fontSizeOf(14)),
                                    ),
                                    trailing: Text(
                                      "${currentCrypto.contractAddress != null ? currentCrypto.contractAddress!.length > 10 ? currentCrypto.contractAddress?.substring(0, 10) : "" : ""}...",
                                      style: textTheme.bodyMedium?.copyWith(
                                          fontSize: fontSizeOf(14),
                                          color: colors.textColor
                                              .withOpacity(0.5)),
                                    ),
                                  ),
                                ],
                              )),
                        ),
                        Align(
                          alignment: Alignment.center,
                          child: Container(
                              decoration: BoxDecoration(
                                  borderRadius:
                                      BorderRadius.circular(roundedOf(5)),
                                  color: colors.grayColor.withOpacity(0.25)),
                              child: Column(
                                children: [
                                  ListTile(
                                      onTap: () {
                                        if (!currentCrypto.isNative) {
                                          launchUrl(Uri.parse(
                                              '${currentCrypto.network?.explorers![0]}/address/${currentCrypto.contractAddress}'));
                                        } else {
                                          launchUrl(Uri.parse(
                                              currentCrypto.explorers![0]));
                                        }
                                      },
                                      leading: Icon(
                                        LucideIcons.scrollText,
                                        color: colors.textColor,
                                      ),
                                      title: Text(
                                        "View on Explorer",
                                        style: textTheme.bodyMedium?.copyWith(
                                            color: colors.textColor,
                                            fontSize: fontSizeOf(14)),
                                      ),
                                      trailing: Icon(
                                        Icons.chevron_right,
                                        color:
                                            colors.textColor.withOpacity(0.5),
                                      )),
                                ],
                              )),
                        ),
                        SizedBox(
                          height: 15,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    height: 10,
                  )
                ],
              ),
            ));
      });
}
