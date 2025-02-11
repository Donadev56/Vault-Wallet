import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:moonwallet/logger/logger.dart';

class ActionsWidgets extends StatelessWidget {
  final Color actionsColor;
  final Color textColor;
  final String text;
  final IconData? actIcon;
  const ActionsWidgets(
      {super.key,
      required this.actionsColor,
      required this.textColor,
      required this.text,
      this.actIcon});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(10),
      child: Column(
        children: [
          Container(
              margin: const EdgeInsets.all(5),
              width: 45,
              height: 45,
              decoration: BoxDecoration(
                  color: actionsColor, borderRadius: BorderRadius.circular(50)),
              child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(50),
                    onTap: () {
                      log("taped");
                    },
                    child: Align(
                      alignment: Alignment.center,
                      child: Icon(
                        actIcon,
                        color: textColor,
                        size: 15,
                      ),
                    ),
                  ))),
          Text(
            text,
            style: GoogleFonts.roboto(color: textColor, fontSize: 12),
          )
        ],
      ),
    );
  }
}
