import 'package:flutter/material.dart';
import 'package:moonwallet/types/account_related_types.dart';
import 'package:moonwallet/types/types.dart';
import 'package:moonwallet/widgets/screen_widgets/crypto_picture.dart';

class NetworkChip extends StatelessWidget {
  final AppColors colors;
  final bool isSelected;
  final Crypto network;
  final void Function() onTap;
  const NetworkChip(
      {super.key,
      required this.colors,
      required this.onTap,
      required this.isSelected,
      required this.network});

  @override
  Widget build(BuildContext context) {
    return IconChip(
      textColor: isSelected ? (network.color ?? colors.themeColor) : null,
      borderColor: (network.color ?? colors.themeColor),
      colors: colors,
      icon: CryptoPicture(crypto: network, size: 25, colors: colors),
      text: network.name,
      useBorder: isSelected,
      onTap: onTap,
    );
  }
}

class IconChip extends StatelessWidget {
  final AppColors colors;
  final Widget icon;
  final String text;
  final bool useBorder;
  final Color? textColor;
  final Color? borderColor;
  final void Function()? onTap;

  const IconChip(
      {super.key,
      required this.colors,
      required this.icon,
      required this.text,
      required this.useBorder,
      this.textColor,
      this.borderColor,
      this.onTap});

  @override
  Widget build(BuildContext context) {
    final textTheme = TextTheme.of(context);
    return AnimatedContainer(
        duration: Duration(milliseconds: 200),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          color: colors.secondaryColor,
          border: useBorder
              ? Border.all(
                  color: borderColor ?? colors.themeColor,
                  width: 1,
                )
              : null,
        ),
        child: Material(
            borderRadius: BorderRadius.circular(30),
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(30),
              splashColor: colors.secondaryColor,
              child: AnimatedContainer(
                duration: Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    spacing: 10,
                    children: [
                      icon,
                      Text(
                        text,
                        style: textTheme.bodyMedium?.copyWith(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: textColor ?? colors.textColor),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      )
                    ],
                  ),
                ),
              ),
            )));
  }
}
