import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:moonwallet/types/types.dart';
import 'package:moonwallet/widgets/scanner/scanner.dart';

void showScanner(
    {required BuildContext context,
    required MobileScannerController controller,
    required AppColors colors,
    required void Function(String result) onResult}) {
  showModalBottomSheet(
      isScrollControlled: true,
      context: context,
      builder: (BuildContext scanCtx) {
        return StatefulBuilder(
            builder: (BuildContext stateFScanCtx, setModalState) {
          return ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: MediaQuery.of(context).size.height,
              ),
              child: CustomScanner(
                controller: controller,
                onResult: (result) {
                  onResult(result);
                  Navigator.pop(context);
                } /* (result) {
                                          showCupertinoDialog(context: context, builder: (ctx) {
                                            return CupertinoAlertDialog(
                                              title: Text("Scan Result "),
                                              content: SelectableRegion(selectionControls: materialTextSelectionControls, child: Text(result)),
                                              actions: <Widget>[
                                                CupertinoButton(
                                                  child: Text('Use'),
                                                  onPressed: () {
                                                   onResult(result);
                                                  },
                                                ),
                                              

                                              ],
                                 
                                            );
                                          });
                                        }*/
                ,
                colors: colors,
              ));
        });
      });
}
