import 'package:flutter/material.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:moonwallet/types/types.dart';

void showCustomSnackBar(
    {required BuildContext context,
    required String message,
    IconData icon = Icons.info,
    MessageType? type,
    Color? iconColor}) {
  FToast fToast = FToast();
  fToast.init(context);

  final title = Text(message, style: TextStyle(color: Colors.black87));
  // final shadowColor = const Color.fromARGB(18, 21, 21, 21);
  // final double borderRadius = 20;
  //final duration = Duration(milliseconds: 500);
  fToast.showToast(
      child: LayoutBuilder(builder: (ctx, c) {
        return Container(
          width: c.maxWidth,
          padding: EdgeInsets.symmetric(vertical: 5, horizontal: 20),
          decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.24),
                  offset: Offset(0, 2),
                  blurRadius: 4,
                ),
              ],
              borderRadius: BorderRadius.circular(5)),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            spacing: 10,
            children: [
              ConstrainedBox(
                constraints: BoxConstraints(maxWidth: c.maxWidth * 0.67),
                child: title,
              ),
              IconButton(
                  onPressed: () => fToast.removeCustomToast(),
                  icon: Icon(
                    FeatherIcons.x,
                    color: const Color.fromARGB(226, 0, 0, 0),
                  ))
            ],
          ),
        );
      }),
      gravity: ToastGravity.TOP);
}

notifySuccess(String message, BuildContext context) => showCustomSnackBar(
    context: context, message: message, type: MessageType.success);
notifyError(String message, BuildContext context) => showCustomSnackBar(
    context: context, message: message, type: MessageType.error);
