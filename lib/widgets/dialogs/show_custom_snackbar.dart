import 'package:flutter/material.dart';
import 'package:moonwallet/types/types.dart';

void showCustomSnackBar(
    {required BuildContext context,
    required String message,
    IconData icon = Icons.info,
    MessageType? type,
    Color? iconColor}) {
  final title = Text(message, style: TextStyle(color: Colors.black87));
  // final shadowColor = const Color.fromARGB(18, 21, 21, 21);
  // final double borderRadius = 20;
  //final duration = Duration(milliseconds: 500);

  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    backgroundColor: Colors.white,
    content: title,
    margin: const EdgeInsets.all(20),
    behavior: SnackBarBehavior.floating,
    dismissDirection: DismissDirection.horizontal,
  ));
}

notifySuccess(String message, BuildContext context) => showCustomSnackBar(
    context: context, message: message, type: MessageType.success);
notifyError(String message, BuildContext context) => showCustomSnackBar(
    context: context, message: message, type: MessageType.error);
