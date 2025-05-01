import 'package:flutter/material.dart';
import 'package:moonwallet/types/types.dart';

class BackupWarningWidget extends StatelessWidget {
  final AppColors colors;
  final void Function()? onTap;
  const BackupWarningWidget({super.key, required this.colors, this.onTap});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return SliverAppBar(
        surfaceTintColor: Colors.orange,
        backgroundColor: Colors.orange,
        automaticallyImplyLeading: false,
        expandedHeight: 120.0,
        pinned: true,
        leading: Icon(
          Icons.warning_amber_outlined,
          color: Colors.white,
          size: 30,
        ),
        title: Text("Risk Detected",
            style: textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.white)),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 5,
            ),
            child: TextButton.icon(
              style: TextButton.styleFrom(
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: onTap,
              label: Text("Backup",
                  style: textTheme.bodyMedium?.copyWith(
                    fontSize: 14,
                    color: Colors.orange,
                  )),
              icon:
                  Icon(Icons.arrow_forward_ios, color: Colors.orange, size: 15),
            ),
          )
        ],
        flexibleSpace: FlexibleSpaceBar(
            background: Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              "This wallet has been detected as unbacked, posing a significant risk to your digital assets.",
              style: textTheme.bodyMedium?.copyWith(
                fontSize: 14,
                // ignore: deprecated_member_use
                color: Colors.white.withOpacity(0.5),
              ),
              textAlign: TextAlign.center,
            ),
          ),
        )));
  }
}
