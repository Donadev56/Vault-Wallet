import 'package:flutter/material.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:moonwallet/types/types.dart';
import 'package:moonwallet/widgets/barre.dart';

class BottomSheetDialog {
  static final instance = BottomSheetDialog._();

  BottomSheetDialog._();

  Future<dynamic> showView({
    required BuildContext context,
    bool isDismissible = true,
    bool useRootNavigator = false,
    Color backgroundColor = Colors.white,
    bool enableDrag = false,
    required Widget child,
    required AppColors colors,
  }) async {
    return showBarModalBottomSheet<dynamic>(
      context: context,
      isDismissible: isDismissible,
      duration: const Duration(
        milliseconds: 200,
      ),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
              topLeft: Radius.circular(30), topRight: Radius.circular(30))),
      backgroundColor: colors.primaryColor,
      enableDrag: enableDrag,
      builder: (context) => child,
      closeProgressThreshold: 0.2,
      useRootNavigator: useRootNavigator,
    );
  }

  Future<dynamic> showViewWithModalStyle(
    Widget widget, {
    required BuildContext context,
    bool isDismissible = false,
    bool useRootNavigator = false,
    bool isScrollController = true,
    bool enableDrag = false,
    required AppColors colors,
  }) async {
    return showCupertinoModalBottomSheet<dynamic>(
      context: context,
      isDismissible: isDismissible,
      backgroundColor: Colors.transparent,
      duration: const Duration(milliseconds: 200),
      topRadius: Radius.circular(30),
      enableDrag: enableDrag,
      builder: (context) => SafeArea(
        bottom: false,
        child: Material(
          child: Column(
            children: [DraggableBar(colors: colors), widget],
          ),
        ),
      ),
      useRootNavigator: useRootNavigator,
    );
  }
}
