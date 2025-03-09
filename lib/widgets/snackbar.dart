import 'package:flutter/material.dart';

void showCustomSnackBar(
    {required BuildContext context,
    required String message,
    required Color primaryColor,
    IconData icon = Icons.info,
        Color iconColor = Colors.white}) {

  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    backgroundColor: primaryColor,
    content: ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.8,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: iconColor),
          Text(
            message,
            style: TextStyle(color: Colors.white),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ),
  ));
}
