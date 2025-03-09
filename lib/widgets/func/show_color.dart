import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:moonwallet/types/types.dart';
import 'package:moonwallet/utils/constant.dart';

void showColorPicker(
    {required void Function(int index) onSelect,
    required BuildContext context,
    required AppColors colors}) {
  showModalBottomSheet(
      isScrollControlled: true,
      context: context,
      builder: (BuildContext ctx) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.9,
          decoration: BoxDecoration(
            color: colors.primaryColor,
            borderRadius: BorderRadius.only(
                topLeft: Radius.circular(15), topRight: Radius.circular(15)),
          ),
          child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 5),
              itemCount: colorList.length,
              itemBuilder: (context, index) {
                return IconButton(
                    onPressed: () {
                      onSelect(index);
                      Navigator.pop(context);
                    },
                    icon: Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(50),
                          color: colorList[index],
                          border: index == colorList.length - 1
                              ? Border.all(width: 1, color: colors.themeColor)
                              : Border.all(
                                  width: 0, color: Colors.transparent)),
                      child: index == colorList.length - 1
                          ? Icon(
                              LucideIcons.x,
                              color: colors.themeColor.withOpacity(0.5),
                            )
                          : null,
                    ));
              }),
        );
      });
}
