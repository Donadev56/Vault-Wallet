import 'package:flutter/material.dart';
import 'package:moonwallet/types/types.dart';

class AddressChip extends StatelessWidget {
  final String address;
  final Widget icon;
  final AppColors colors;
  final DoubleFactor roundedOf;
  final DoubleFactor fontSizeOf;
  const AddressChip({
    super.key,
    required this.address,
    required this.colors,
    required this.icon,
    required this.fontSizeOf,
    required this.roundedOf,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = TextTheme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
      decoration: BoxDecoration(
        color: colors.secondaryColor,
        borderRadius: BorderRadius.circular(roundedOf(15)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        spacing: 10,
        children: [
          icon,
          Text(
            address.isNotEmpty
                ? "${address.substring(0, 6)}...${address.substring(address.length - 6, address.length)}"
                : "No Account",
            style: textTheme.bodyMedium
                ?.copyWith(color: colors.textColor, fontSize: fontSizeOf(14)),
          )
        ],
      ),
    );
  }
}
