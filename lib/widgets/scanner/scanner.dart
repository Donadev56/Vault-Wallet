import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:moonwallet/types/types.dart';
import 'package:moonwallet/widgets/dialogs/show_custom_snackbar.dart';

class CustomScanner extends StatelessWidget {
  final MobileScannerController controller;
  final AppColors colors;
  final void Function(String result) onResult;
  const CustomScanner(
      {super.key,
      required this.controller,
      required this.onResult,
      required this.colors});

  @override
  Widget build(BuildContext context) {
    return MobileScanner(
      overlayBuilder: (ctx, c) {
        return Container(
            decoration: BoxDecoration(),
            child: Center(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  border: Border.all(width: 2, color: Colors.white),
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: c.maxWidth / 2,
                    maxHeight: c.maxWidth / 2,
                  ),
                  child: SizedBox.expand(),
                ),
              ),
            ));
      },
      onDetectError: (object, error) {
        notifyError(error.toString(), context);
      },
      controller: controller,
      onDetect: (barcode) {
        final String code = barcode.barcodes.firstOrNull!.displayValue ?? "";
        onResult(code);
      },
    );
  }
}
