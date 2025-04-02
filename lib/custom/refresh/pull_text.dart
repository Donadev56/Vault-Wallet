// ignore_for_file: deprecated_member_use

import 'package:custom_refresh_indicator/custom_refresh_indicator.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:moonwallet/custom/refresh/custom_material_indicator.dart';
import 'package:moonwallet/types/types.dart';

class RefreshText {
  final String startingText;
  final String releaseText;
  final String loadingText;

  final String completedText;

  const RefreshText({
    required this.startingText,
    required this.releaseText,
    required this.loadingText,
    required this.completedText,
  });

  static const defaultTexts = RefreshText(
      completedText: "Updated",
      startingText: "Pull to refresh",
      releaseText: "Release to refresh",
      loadingText: "Updating...");
}

class RefreshIcons {
  final IconData startingIcon;
  final IconData releaseIcon;
  final Widget refreshIndicator;

  final IconData completedIcon;

  const RefreshIcons({
    required this.startingIcon,
    required this.releaseIcon,
    required this.completedIcon,
    required this.refreshIndicator,
  });
  static const defaultIcons = RefreshIcons(
    startingIcon: Icons.arrow_downward,
    releaseIcon: Icons.arrow_upward,
    completedIcon: Icons.check_circle,
    refreshIndicator: CircularProgressIndicator(),
  );
}

class PullText extends StatefulWidget {
  final Widget child;
  final AsyncCallback onRefresh;
  final IndicatorController? controller;
  final RefreshText? refreshText;
  final RefreshIcons? icons;
  final AppColors colors;

  const PullText({
    super.key,
    required this.child,
    this.controller,
    required this.onRefresh,
    this.refreshText = RefreshText.defaultTexts,
    this.icons = RefreshIcons.defaultIcons,
    required this.colors,
  });

  @override
  State<PullText> createState() => _PullText();
}

class _PullText extends State<PullText> with SingleTickerProviderStateMixin {
  /// Whether to render check mark instead of spinner
  bool _renderCompleteState = false;

  ScrollDirection prevScrollDirection = ScrollDirection.idle;

  bool _hasError = false;

  Future<void> _handleRefresh() async {
    try {
      setState(() {
        _hasError = false;
      });
      await widget.onRefresh();
    } catch (_) {
      setState(() {
        _hasError = true;
      });
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    return CustomInternalMaterialIndicator(
      width: MediaQuery.of(context).size.width * 0.8,
      useMaterialContainer: false,
      controller: widget.controller,
      onRefresh: _handleRefresh,
      durations: const RefreshIndicatorDurations(
        completeDuration: Duration(seconds: 2),
      ),
      onStateChanged: (change) {
        /// set [_renderCompleteState] to true when controller.state become completed
        if (change.didChange(to: IndicatorState.complete)) {
          _renderCompleteState = true;

          /// set [_renderCompleteState] to false when controller.state become idle
        } else if (change.didChange(to: IndicatorState.idle)) {
          _renderCompleteState = false;
        }
      },
      indicatorBuilder: (
        BuildContext context,
        IndicatorController controller,
      ) {
        // final value = controller.value.clamp(0.0, 1.0) ;

        if (_hasError) {
          return RefreshFeedBack(
            colors: widget.colors,
            text: "Error",
            icon: Icons.error,
          );
        }

        return AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          alignment: Alignment.center,
          child: _renderCompleteState
              ? RefreshFeedBack(
                  colors: widget.colors,
                  text: widget.refreshText!.completedText,
                  icon: widget.icons!.completedIcon,
                )
              : controller.isDragging
                  ? RefreshFeedBack(
                      colors: widget.colors,
                      text: widget.refreshText!.startingText,
                      icon: widget.icons!.startingIcon,
                    )
                  : controller.isArmed
                      ? RefreshFeedBack(
                          colors: widget.colors,
                          text: widget.refreshText!.releaseText,
                          icon: widget.icons!.releaseIcon,
                        )
                      : RefreshFeedBack(
                          colors: widget.colors,
                          text: widget.refreshText!.loadingText,
                          refreshIndicator: widget.icons!.refreshIndicator,
                        ),
        );
      },
      child: widget.child,
    );
  }
}

class RefreshFeedBack extends StatelessWidget {
  final String text;
  final IconData? icon;
  final AppColors colors;
  final Widget? refreshIndicator;
  const RefreshFeedBack({
    super.key,
    required this.text,
    this.icon,
    required this.colors,
    this.refreshIndicator,
  });

  @override
  Widget build(BuildContext context) {
    if (icon == null && refreshIndicator == null) {
      throw ArgumentError(
          "Either 'icon' or'refreshIndicator' must be provided.");
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(width: 16),
        icon != null
            ? Icon(icon, color: colors.textColor.withOpacity(0.7))
            : refreshIndicator!,
        SizedBox(
          width: 10,
        ),
        SizedBox(width: 8),
        Text(text,
            style:
                GoogleFonts.roboto(color: colors.textColor.withOpacity(0.7))),
      ],
    );
  }
}
