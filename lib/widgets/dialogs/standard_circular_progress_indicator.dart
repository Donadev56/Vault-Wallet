import 'package:flutter/material.dart';
import 'package:moonwallet/types/types.dart';

Widget standardCircularProgressIndicator(
    {double width = 25,
    double height = 25,
    required AppColors colors,
    Color? color}) {
  return SizedBox(
    width: width,
    height: height,
    child: CircularProgressIndicator(
      color: color ?? colors.textColor,
    ),
  );
}
