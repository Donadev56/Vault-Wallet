import 'package:flutter/material.dart';

void showCustomSnackBar(
    {required BuildContext context,
    required String message,
    IconData icon = Icons.info,
    Color backgroundColor = const Color(0XFF0D0D0D),
    Color iconColor = Colors.white}) {
  Color primaryColor = Color(0XFF1B1B1B);

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
