import 'package:flutter/material.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';

class FloatingModal extends StatelessWidget {
  final Widget child;
  final Color? backgroundColor;

  const FloatingModal({super.key, required this.child, this.backgroundColor});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Material(
          color: backgroundColor,
          clipBehavior: Clip.antiAlias,
          borderRadius: BorderRadius.circular(12),
          child: child,
        ),
      ),
    );
  }
}

Future<T> showFloatingModalBottomSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  Color? backgroundColor,
  bool isDismissible = true,
  bool enableDrag = true,
}) async {
  final result = await showCustomModalBottomSheet(
      isDismissible: isDismissible,
      enableDrag: enableDrag,
      elevation: 0,
      barrierColor: const Color.fromARGB(179, 0, 0, 0),
      context: context,
      builder: builder,
      containerWidget: (_, animation, child) => FloatingModal(
            backgroundColor: backgroundColor,
            child: child,
          ),
      expand: false);

  return result;
}
