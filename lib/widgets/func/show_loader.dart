import 'package:flutter/material.dart';
import 'package:moonwallet/types/types.dart';

void showLoader(BuildContext context, AppColors colors) {
  showDialog(
      context: context,
      builder: (BuildContext context) {
        return Center(
          child: Container(
            padding: const EdgeInsets.all(30),
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: colors.primaryColor,
            ),
            child: SizedBox(
              width: 65,
              height: 65,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: colors.themeColor,
              ),
            ),
          ),
        );
      });
}
