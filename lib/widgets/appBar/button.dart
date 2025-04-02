import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AddWalletButton extends StatelessWidget {
  final Color textColor;
  final String text;
  final IconData icon;
  final VoidCallback onTap;

  const AddWalletButton(
      {super.key,
      required this.textColor,
      required this.text,
      required this.icon,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(10),
      child: ListTile(
        visualDensity: VisualDensity(horizontal: 0, vertical: 0),
        tileColor: textColor.withOpacity(0.05),
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        leading: Icon(
          icon,
          color: textColor,
        ),
        title: Text(
          text,
          style: GoogleFonts.roboto(color: textColor),
        ),
      ),
    );
  }
}
