import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

typedef OnTapType = void Function();

class WalletViewButtonAction extends StatelessWidget {
  final Color textColor;
  final OnTapType onTap;
  final String bottomText;
  final IconData icon;
  const WalletViewButtonAction(
      {super.key,
      required this.textColor,
      required this.onTap,
      required this.bottomText,
      required this.icon});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(50),
            onTap: onTap,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(50),
                color: textColor.withOpacity(0.1),
              ),
              padding: const EdgeInsets.all(12),
              child: Center(
                child: Icon(
                  icon,
                  color: textColor,
                ),
              ),
            ),
          ),
        ),
        SizedBox(
          height: 5,
        ),
        Text(
          bottomText,
          style: GoogleFonts.roboto(color: textColor, fontSize: 17),
        )
      ],
    );
  }
}
