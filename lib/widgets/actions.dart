import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';


typedef OnTap = void Function(int index);

class ActionsWidgets extends StatelessWidget {
  final Color actionsColor;
  final Color textColor;
  final String text;
  final IconData? actIcon;
  final VoidCallback onTap;
  const ActionsWidgets(
      {super.key,
      required this.actionsColor,
      required this.textColor,
      required this.text,
      required this.onTap,
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
                    onTap: onTap,
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
