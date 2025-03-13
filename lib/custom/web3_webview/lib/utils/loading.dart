import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:moonwallet/types/types.dart';

class LoadingHelper {
  static OverlayEntry? _overlay;

  static void show(BuildContext context, AppColors colors, [String? message]) {
    if (_overlay != null) return;

    // Dismiss keyboard
    FocusManager.instance.primaryFocus?.unfocus();

    _overlay = OverlayEntry(
      builder: (context) => Material(
        color: Colors.black87,
        child: Center(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colors.secondaryColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                if (message != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    message,
                    style: GoogleFonts.roboto(color: colors.textColor),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_overlay!);
  }

  static void hide() {
    _overlay?.remove();
    _overlay = null;
  }
}

extension FutureWithLoading<T> on Future<T> {
  Future<T> withLoading(BuildContext context, AppColors colors,
      [String? message]) {
    LoadingHelper.show(context, colors, message);
    return then((value) {
      Future.delayed(const Duration(milliseconds: 1000), LoadingHelper.hide);
      return value;
    }).catchError((error) {
      Future.delayed(const Duration(milliseconds: 1000), LoadingHelper.hide);
      throw error;
    });
  }
}
