import 'package:flutter/material.dart';
import 'package:moonwallet/types/types.dart';

class PinedSliverAppBar extends StatelessWidget {
  final AppColors colors;
  final TextEditingController cryptoSearchTextController;
  final void Function(String)? onSearch;
  final DoubleFactor fontSizeOf;
  final DoubleFactor roundedOf;
  final List<PopupMenuEntry<dynamic>> moreButtonOptions;
  const PinedSliverAppBar(
      {super.key,
      required this.colors,
      required this.cryptoSearchTextController,
      this.onSearch,
      required this.fontSizeOf,
      required this.roundedOf,
      required this.moreButtonOptions});

  @override
  Widget build(BuildContext context) {
    final textTheme = TextTheme.of(context);
    return SliverAppBar(
      backgroundColor: colors.primaryColor,
      surfaceTintColor: colors.grayColor.withValues(alpha: 0.1),
      pinned: true,
      automaticallyImplyLeading: false,
      title: Padding(
          padding: const EdgeInsets.only(left: 0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AnimatedContainer(
                duration: Duration(seconds: 1),
                width: cryptoSearchTextController.text.isNotEmpty ? 200 : 125,
                child: SizedBox(
                  height: 30,
                  child: TextField(
                    onChanged: onSearch,
                    controller: cryptoSearchTextController,
                    style: textTheme.bodySmall?.copyWith(
                        fontSize: fontSizeOf(13), color: colors.textColor),
                    decoration: InputDecoration(
                        prefixIcon: Icon(
                          Icons.search,
                          color: colors.textColor.withOpacity(0.3),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 15, vertical: 0),
                        hintStyle: textTheme.bodySmall?.copyWith(
                            color: colors.textColor.withOpacity(0.4)),
                        hintText: "Search",
                        filled: true,
                        fillColor: colors.secondaryColor,
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(roundedOf(40)),
                            borderSide: BorderSide(
                                width: 0, color: Colors.transparent)),
                        enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(roundedOf(40)),
                            borderSide: BorderSide(
                                width: 0, color: Colors.transparent)),
                        focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(roundedOf(40)),
                            borderSide: BorderSide(
                                width: 0, color: Colors.transparent))),
                  ),
                ),
              )
            ],
          )),
      actions: [
        PopupMenuButton(
            splashRadius: roundedOf(10),
            borderRadius: BorderRadius.circular(roundedOf(20)),
            requestFocus: true,
            menuPadding: const EdgeInsets.all(0),
            padding: const EdgeInsets.all(0),
            color: colors.secondaryColor,
            icon: Icon(
              Icons.more_vert,
              color: colors.textColor.withOpacity(0.4),
            ),
            itemBuilder: (ctx) => moreButtonOptions)
      ],
    );
  }
}
