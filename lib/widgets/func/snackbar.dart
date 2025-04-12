import 'package:cherry_toast/cherry_toast.dart';
import 'package:flutter/material.dart';
import 'package:moonwallet/types/types.dart';

void showCustomSnackBar(
    {required BuildContext context,
    required String message,
    IconData icon = Icons.info,
    required AppColors colors,
    required MessageType type,
    Color? iconColor}) {
  final title = Text(message, style: TextStyle(color: colors.textColor));
  final shadowColor = const Color.fromARGB(18, 21, 21, 21);
  final double borderRadius = 20;
  final duration = Duration(milliseconds: 500);
  switch (type) {
    case MessageType.success:
      CherryToast.success(
              actionHandler: () {
                Navigator.of(context);
              },
              shadowColor: shadowColor,
              borderRadius: borderRadius,
              animationDuration: duration,
              backgroundColor: colors.primaryColor,
              title: title)
          .show(context);
    case MessageType.error:
      CherryToast.error(
              actionHandler: () {
                Navigator.of(context);
              },
              shadowColor: shadowColor,
              borderRadius: borderRadius,
              animationDuration: duration,
              backgroundColor: colors.primaryColor,
              title: title)
          .show(context);

    case MessageType.warning:
      CherryToast.warning(
              actionHandler: () {
                Navigator.of(context);
              },
              shadowColor: shadowColor,
              borderRadius: borderRadius,
              animationDuration: duration,
              backgroundColor: colors.primaryColor,
              title: title)
          .show(context);

    case MessageType.info:
      CherryToast.warning(
              actionHandler: () {
                Navigator.of(context);
              },
              shadowColor: shadowColor,
              borderRadius: borderRadius,
              animationDuration: duration,
              backgroundColor: colors.primaryColor,
              title: title)
          .show(context);

      break;
  }
}

/*class ToastParams  {
  ToastParams toastParams = ToastParams(
               shadowColor: shadowColor,
        
              borderRadius: borderRadius,
              animationDuration: duration,
              backgroundColor: colors.primaryColor,
              title: title

    );

  final Text? title;
  final Text? action;
  final Function? actionHandler;
  final Text? description;
  final Color backgroundColor ;
  final Color shadowColor ;
  final Position toastPosition ;
  final Duration animationDuration ;
  final Cubic animationCurve;
  final AnimationType animationType ;
  final bool autoDismiss;
  final Duration toastDuration ;
  final TextDirection textDirection;
  final bool displayCloseButton ;
  final double borderRadius;
  final Widget? iconWidget;
  final bool displayIcon ;
  final bool enableIconAnimation;
  final double? height;
  final double? width;
  final BoxConstraints? constraints;
  final bool disableToastAnimation ;
  final bool inheritThemeColors ;
  final dynamic Function()? onToastClosed;
  final CrossAxisAlignment horizontalAlignment ;
  final double titleDescriptionMargin;
  final double descriptionActionMargin;

  ToastParams(
    {
  Key? key,
  this.title,
  this. action,
  this.actionHandler,
  this.description,
  this.backgroundColor = defaultBackgroundColor,
  this.shadowColor = defaultShadowColor,
  this.toastPosition = Position.top,
  this.animationDuration = const Duration(milliseconds: 1500),
  this.animationCurve = Curves.ease,
  this.animationType = AnimationType.fromLeft,
  this.autoDismiss = true,
  this.toastDuration = const Duration(milliseconds: 3000),
  this.textDirection = TextDirection.ltr,
  this.displayCloseButton = true,
 this.borderRadius = 20,
  this.iconWidget,
  this.displayIcon = true,
  this.enableIconAnimation = true,
  this. height,
  this. width,
  this. constraints,
  this.disableToastAnimation = false,
  this. inheritThemeColors = false,
 this.onToastClosed,
  this. horizontalAlignment = CrossAxisAlignment.start,
  this. titleDescriptionMargin = 0,
 this. descriptionActionMargin = 0,
});
}*/

/*
void showCustomSnackBar(
    {required BuildContext context,
    required String message,
    IconData icon = Icons.info,
    required AppColors colors,
    Color? iconColor}) {
  DelightToastBar(
    autoDismiss: true,
    builder: (context) => ToastCard(
    
      color: colors.secondaryColor,
      leading: Icon(
        color: iconColor ?? colors.redColor,
        icon,
        size: 28,
      ),
      title: Text(
        message,
        style: TextStyle(
          color: colors.textColor,
          fontWeight: FontWeight.w700,
          fontSize: 14,
        ),
      ),
    ),
  ).show(context);
}
*/
