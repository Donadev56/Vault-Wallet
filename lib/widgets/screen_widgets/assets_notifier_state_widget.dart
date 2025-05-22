import 'package:flutter/material.dart';
import 'package:moonwallet/types/notifications_types.dart';
import 'package:moonwallet/types/types.dart';

class AssetsNotifierStateWidget extends SliverPersistentHeaderDelegate {
  final AppColors colors;
  final DoubleFactor fontSizeOf;
  final DoubleFactor roundedOf;
  final AssetNotification state;
  const AssetsNotifierStateWidget(
      {required this.colors,
      required this.fontSizeOf,
      required this.roundedOf,
      required this.state});
  @override
  double get maxExtent => 150.0;

  @override
  double get minExtent => 100.0;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final textTheme = TextTheme.of(context);

    String getText() {
      if (state.isLoading) {
        return "Updating...";
      } else if (state.isError) {
        return "Error";
      } else {
        return "completed";
      }
    }

    Widget getIconState() {
      if (state.isLoading) {
        return SizedBox(
          height: 25,
          width: 25,
          child: CircularProgressIndicator(
            color: colors.primaryColor,
          ),
        );
      } else if (state.isError) {
        return Icon(
          Icons.error_outline,
          color: colors.redColor,
        );
      } else {
        return Icon(
          Icons.check,
          color: colors.primaryColor,
        );
      }
    }

    return Container(
      height: 50,
      margin: const EdgeInsets.symmetric(horizontal: 30),
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 5),
      decoration: BoxDecoration(
          color: state.isError ? colors.redColor : colors.themeColor,
          borderRadius: BorderRadius.circular(roundedOf(20))),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            getText(),
            style: textTheme.bodyMedium?.copyWith(
                color: colors.primaryColor,
                fontSize: fontSizeOf(15),
                fontWeight: FontWeight.w400),
          ),
          getIconState()
        ],
      ),
    );
  }

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) {
    // Rebuild if the parameters have changed
    return true;
  }
}
