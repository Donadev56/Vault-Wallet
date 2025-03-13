import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/test_icons.dart';
import 'package:moonwallet/types/types.dart';
import 'package:moonwallet/widgets/flowting_modat.dart';

void showIconPicker(
    {required void Function(IconData icon) onSelect,
    required BuildContext context,
    required AppColors colors}) {
  showFloatingModalBottomSheet(
      context: context,
      builder: (BuildContext ctx) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.5,
          decoration: BoxDecoration(
            color: colors.primaryColor,
            borderRadius: BorderRadius.only(
                topLeft: Radius.circular(15), topRight: Radius.circular(15)),
          ),
          child: GridView.builder(
              shrinkWrap: true,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4),
              itemCount: icons.length,
              itemBuilder: (context, index) {
                return IconButton(
                    onPressed: () {
                      onSelect(icons[index]);
                      Navigator.pop(context);
                    },
                    icon: Icon(
                      icons[index],
                      size: 27,
                      color: colors.textColor.withOpacity(0.7),
                    ));
              }),
        );
      });
}
