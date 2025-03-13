import 'dart:io';
import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart'
    as modal_bottom_sheet;
import 'package:moonwallet/types/types.dart';

class AvatarBottomSheet extends StatelessWidget {
  final Widget child;
  final Animation<double> animation;
  final SystemUiOverlayStyle? overlayStyle;

  final AppColors colors;
  final Widget avatarChild;

  AvatarBottomSheet(
      {super.key,
      required this.child,
      required this.animation,
      this.overlayStyle,
      required this.avatarChild,
      required this.colors});

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 7, sigmaY: 7),
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: overlayStyle ?? SystemUiOverlayStyle.light,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 12),
            SafeArea(
              bottom: false,
              child: AnimatedBuilder(
                animation: animation,
                builder: (context, child) => Transform.translate(
                    offset: Offset(0, (1 - animation.value) * 100),
                    child: Opacity(
                        child: child,
                        opacity: max(0, animation.value * 2 - 1))),
                child: Row(
                  children: <Widget>[
                    SizedBox(width: 20),
                    ClipRRect(
                        borderRadius: BorderRadius.circular(50),
                        child: avatarChild),
                  ],
                ),
              ),
            ),
            SizedBox(height: 12),
            Flexible(
              flex: 1,
              fit: FlexFit.loose,
              child: ClipRRect(
                borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(15),
                    topRight: Radius.circular(15)),
                child: Container(
                  decoration: BoxDecoration(
                    color: colors.primaryColor,
                    boxShadow: [
                      BoxShadow(
                        blurRadius: 10,
                        color: Colors.black12,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  width: double.infinity,
                  child: MediaQuery.removePadding(
                      context: context, removeTop: true, child: child),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Future<T?> showAvatarModalBottomSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  Color? backgroundColor,
  double? elevation,
  ShapeBorder? shape,
  Clip? clipBehavior,
  Color barrierColor = const Color.fromARGB(92, 0, 0, 0),
  bool bounce = true,
  bool expand = false,
  AnimationController? secondAnimation,
  bool useRootNavigator = false,
  bool isDismissible = true,
  bool enableDrag = false,
  Duration? duration,
  SystemUiOverlayStyle? overlayStyle,
  File? profileImage,
  required AppColors colors,
  required Widget avatarChild,
}) async {
  assert(debugCheckHasMediaQuery(context));
  assert(debugCheckHasMaterialLocalizations(context));
  final result = await Navigator.of(context, rootNavigator: useRootNavigator)
      .push(modal_bottom_sheet.ModalSheetRoute<T>(
    builder: builder,
    containerBuilder: (_, animation, child) => AvatarBottomSheet(
      avatarChild: avatarChild,
      colors: colors,
      animation: animation,
      overlayStyle: overlayStyle,
      child: child,
    ),
    bounce: bounce,
    secondAnimationController: secondAnimation,
    expanded: expand,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    isDismissible: isDismissible,
    modalBarrierColor: barrierColor,
    enableDrag: enableDrag,
    duration: duration,
  ));
  return result;
}
