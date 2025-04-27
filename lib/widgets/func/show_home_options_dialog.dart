import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:moonwallet/screens/dashboard/main/account_data.dart';
import 'package:moonwallet/types/types.dart';
import 'package:moonwallet/widgets/appBar/button.dart';
import 'package:moonwallet/widgets/appBar/show_wallet_actions.dart';
import 'package:url_launcher/url_launcher.dart';


void showHomeOptionsDialog(
    {required BuildContext context,
    required VoidCallback toggleHidden,
    required AppColors colors,
    required bool isHidden ,
    required DoubleFactor fontSizeOf,
    required DoubleFactor roundedOf,
    required DoubleFactor iconSizeOf,

    }) async {

   

   final List<Map<String, dynamic>> options = [
{'icon': Icons.show_chart, 'name': 'Account Statistics (BETA)'},
  {'icon': isHidden ?  LucideIcons.eye : LucideIcons.eyeClosed, 'name': '${isHidden ? "Show" : "Hide"} Balance'},
  {'icon': LucideIcons.send, 'name': 'Join Telegram'},
  {'icon': LucideIcons.messageCircle, 'name': 'Join Whatsapp'},
];

  showAppBarWalletActions(context: context, colors: colors,
  
  child: Column(
    spacing: 10,
    children: List.generate(options.length, (i) {
     final opt = options[i];

      return  CustomListTitleButton(textColor: colors.textColor, iconSizeOf: iconSizeOf, fontSizeOf: fontSizeOf, roundedOf: roundedOf,
      text: opt["name"], icon: opt["icon"], onTap: () {
                    switch (i) {
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
                  },);
    }),
  )) ;


}
