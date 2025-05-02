import 'package:flutter/material.dart';
import 'package:moonwallet/types/types.dart';

class FirstTimeUseDialogBase extends StatelessWidget {
  final AppColors colors;
  final String title;
  final String content;
  final String imageUrl;
  final String confirmButtonText;
  final String cancelButtonText;
  final void Function()? onConfirm;
  final void Function()? onCancel;
  const FirstTimeUseDialogBase({
    super.key,
    required this.colors,
    required this.title,
    required this.content,
    required this.imageUrl,
    required this.confirmButtonText,
    required this.cancelButtonText,
    this.onConfirm,
    this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: colors.primaryColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: ListView(
          shrinkWrap: true,
          children: [
            SizedBox(
              height: 100,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            SizedBox(
              height: 15,
            ),
            Text(
              title,
              style: TextStyle(
                  color: colors.textColor,
                  fontSize: 20,
                  fontWeight: FontWeight.bold),
            ),
            SizedBox(
              height: 15,
            ),
            Text(
              content,
              style: TextStyle(
                  color: colors.textColor.withValues(alpha: 0.7), fontSize: 14),
            ),
            SizedBox(
              height: 30,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: colors.themeColor),
                  ),
                  onPressed: () {
                    onCancel ?? Navigator.pop(context, false);
                  },
                  child: Text(
                    cancelButtonText,
                    style: TextStyle(color: colors.themeColor),
                  ),
                ),
                SizedBox(
                  width: 10,
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.themeColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  onPressed: () => onConfirm ?? Navigator.pop(context, true),
                  child: Text(
                    confirmButtonText,
                    style: TextStyle(color: colors.primaryColor),
                  ),
                )
              ],
            ),
          ],
        ),
      ),
    );
  }
}
