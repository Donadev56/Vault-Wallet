import 'package:flutter/material.dart';
import 'package:moonwallet/types/types.dart';
import 'package:moonwallet/widgets/dialogs/first_time_use.dart';

Future<bool> showFirstUseDialog(
    {required BuildContext context, required AppColors colors}) async {
  final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return FirstTimeUseDialogBase(
            colors: colors,
            title: "First time using Solana?",
            content:
                "Solana is a high-performance blockchain that supports fast and low-cost transactions. It is designed to scale with the growing demand for decentralized applications and services.",
            imageUrl:
                "https://optim.tildacdn.net/tild3735-3035-4336-b333-643830343932/-/format/webp/Solana_Brand_Overvie.png.webp",
            cancelButtonText: "Cancel",
            confirmButtonText: "Continue");
      });
  return ok ?? false;
}
