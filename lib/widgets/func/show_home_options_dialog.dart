import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:moonwallet/custom/web3_webview/lib/widgets/custom_modal.dart';
import 'package:moonwallet/screens/dashboard/main/account_data.dart';
import 'package:moonwallet/types/types.dart';
import 'package:url_launcher/url_launcher.dart';

final List<Map<String, dynamic>> options = [
  {'icon': Icons.show_chart, 'name': 'Account Statistics'},
  {'icon': LucideIcons.eye, 'name': 'Hide Balance'},
  {'icon': LucideIcons.send, 'name': 'Join Telegram'},
  {'icon': LucideIcons.messageCircle, 'name': 'Join Whatsapp'},
];
void showHomeOptionsDialog(
    {required BuildContext context,
    required VoidCallback toggleHidden,
    required AppColors colors}) async {
  final textTheme = Theme.of(context).textTheme;

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
                    switch (index) {
                      case 0:
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (ctx) => AccountDataView()));
                      case 1:
                        toggleHidden();
                      case 2:
                        launchUrl(Uri.parse("https://t.me/eternalprotocol"));
                      case 3:
                        launchUrl(Uri.parse(
                            "https://www.whatsapp.com/channel/0029Vb2TpR9HrDZWVEkhWz21"));
                        break;
                      default:
                    }
                  },
                  leading: Icon(
                    opt["icon"],
                    color: colors.textColor,
                  ),
                  title: Text(opt["name"],
                      style: textTheme.bodyMedium?.copyWith(
                        color: colors.textColor.withOpacity(0.8),
                        fontSize: 16,
                      )),
                ),
              );
            });
      },
      colors: colors);
}
