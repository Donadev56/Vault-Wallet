import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:moonwallet/custom/web3_webview/lib/widgets/custom_modal.dart';
import 'package:moonwallet/main.dart';
import 'package:moonwallet/types/types.dart';
import 'package:moonwallet/widgets/text.dart';
import 'package:url_launcher/url_launcher.dart';

final List<Map<String, dynamic>> options = [
  {'icon': LucideIcons.eye, 'name': 'Hide Balance'},
  {'icon': LucideIcons.send, 'name': 'Join Telegram'},
  {'icon': LucideIcons.messageCircle, 'name': 'Join Whatsapp'},
  {'icon': LucideIcons.settings, 'name': 'Settings'},
];
void showHomeOptionsDialog(
    {required BuildContext context,
    required VoidCallback toggleHidden,
    required AppColors colors}) async {
  await showDialogWithBar(
      context: context,
      enableDrag: true,
      builder: (ctx) {
        return ListView.builder(
            shrinkWrap: true,
            itemCount: options.length,
            itemBuilder: (BuildContext lisCryptoCtx, int index) {
              final opt = options[index];
              return Material(
                color: Colors.transparent,
                child: ListTile(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  onTap: () {
                    if (index == options.length - 1) {
                      Navigator.pushNamed(context, Routes.settings);
                    } else if (index == 1) {
                      launchUrl(Uri.parse("https://t.me/eternalprotocol"));
                    } else if (index == 2) {
                      launchUrl(Uri.parse(
                          "https://www.whatsapp.com/channel/0029Vb2TpR9HrDZWVEkhWz21"));
                    } else if (index == 0) {
                      toggleHidden();
                    }
                  },
                  leading: Icon(
                    opt["icon"],
                    color: colors.textColor,
                  ),
                  title: Text(
                    opt["name"],
                    style: customTextStyle(
                        color: colors.textColor, fontWeight: FontWeight.bold),
                  ),
                ),
              );
            });
      },
      colors: colors);
}
