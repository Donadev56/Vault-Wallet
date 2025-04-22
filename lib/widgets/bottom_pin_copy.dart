import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:moonwallet/logger/logger.dart';
import 'package:moonwallet/service/vibration.dart';
import 'package:moonwallet/types/types.dart';

typedef ResultType = Future<PinSubmitResult> Function(String numbers);

Future<bool> showPinModalBottomSheet(
    {required BuildContext context,
    required ResultType handleSubmit,
    required AppColors colors,
    required String title,
    bool canApplyBlur = false}) async {
  final result = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        final width = MediaQuery.of(context).size.width;
        final height = MediaQuery.of(context).size.height;
        final textTheme = Theme.of(context).textTheme;

        String error = "";
        String newTitle = "";
        int numberOfNumbers = 0;
        List numbers = List.filled(6, 0);

        return StatefulBuilder(
            builder: (BuildContext context, StateSetter setModalState) {
          void reInit() {
            setModalState(() {
              numberOfNumbers = 0;
              numbers = List.filled(6, 0);
            });
          }

          void handleType(int index) async {
            if (error.isNotEmpty) {
              setModalState(() {
                error = "";
              });
            }
            if (index <= 8) {
              setModalState(() {
                numbers[numberOfNumbers] = index + 1;
                numberOfNumbers++;
                log(numbers.toString());
              });
            } else if (index == 9) {
              setModalState(() {
                numbers[numberOfNumbers] = 0;

                log(numbers.toString());
                numberOfNumbers++;
              });
            } else {
              if (numberOfNumbers <= 0) {
                return;
              }
              setModalState(() {
                numbers[numberOfNumbers] = 0;
                numberOfNumbers--;
                log(numbers.toString());
              });
            }

            if (numberOfNumbers == 6) {
              final PinSubmitResult result =
                  await handleSubmit(numbers.join().toString());
              log("result: $result");
              if (result.success && !result.repeat ||
                  !result.success && !result.repeat) {
                reInit();
                Navigator.pop(context, true);
                return;
              } else if (result.success && result.repeat) {
                setModalState(() {
                  numberOfNumbers = 0;
                  numbers = List.filled(6, 0);
                  String? title = result.newTitle;
                  if (title != null) {
                    newTitle = title;
                  }
                });
                return;
              }

              String? errorText = result.error;
              logError("Error Text $errorText");

              String? title = result.newTitle;

              setModalState(() {
                if (errorText != null) {
                  error = errorText;
                }
                if (title != null) {
                  newTitle = title;
                }
              });

              reInit();
            }
          }

          return BackdropFilter(
            filter: ImageFilter.blur(
              sigmaX: canApplyBlur ? 8 : 0,
              sigmaY: canApplyBlur ? 8 : 0,
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: 700),
              child: Container(
                decoration: BoxDecoration(
                  color: colors.primaryColor,
                ),
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    Align(
                      alignment: Alignment.center,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 20),
                        child: Text(
                          newTitle.isEmpty ? title : newTitle,
                          style: textTheme.bodyMedium
                              ?.copyWith(color: colors.textColor, fontSize: 18),
                        ),
                      ),
                    ),
                    SizedBox(
                      height: 20,
                    ),
                    Align(
                      alignment: Alignment.center,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: List.generate(6, (index) {
                          final isFull = numberOfNumbers > index;

                          return ConstrainedBox(
                              constraints: BoxConstraints(maxWidth: 90),
                              child: Container(
                                decoration: BoxDecoration(
                                    border: Border.all(
                                        width: 0.5,
                                        color: numberOfNumbers > index
                                            ? colors.textColor
                                            : colors.textColor
                                                .withOpacity(0.3)),
                                    borderRadius: BorderRadius.circular(5)),
                                alignment: Alignment.center,
                                width: width * 0.1,
                                height: height * 0.05,
                                padding: const EdgeInsets.all(5),
                                margin: const EdgeInsets.all(5),
                                child: isFull
                                    ? Align(
                                        alignment: Alignment.center,
                                        child: Container(
                                          alignment: Alignment.center,
                                          width: 10,
                                          height: 10,
                                          decoration: BoxDecoration(
                                              color: colors.textColor,
                                              borderRadius:
                                                  BorderRadius.circular(50)),
                                        ),
                                      )
                                    : Container(),
                              ));
                        }),
                      ),
                    ),
                    if (error.isNotEmpty)
                      Align(
                        alignment: Alignment.center,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            SizedBox(
                              height: 10,
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Icon(
                                  FeatherIcons.alertCircle,
                                  color: colors.redColor,
                                ),
                                SizedBox(
                                  width: 5,
                                ),
                                Text(error, style: textTheme.bodyMedium),
                              ],
                            )
                          ],
                        ),
                      ),
                    SizedBox(
                      height: 30,
                    ),
                    Align(
                      alignment: Alignment.center,
                      child: Wrap(
                        alignment: WrapAlignment.end,
                        crossAxisAlignment: WrapCrossAlignment.end,
                        children: List.generate(11, (index) {
                          return ConstrainedBox(
                              constraints: BoxConstraints(maxWidth: 200),
                              child: Container(
                                width: width * 0.26,
                                height: height * 0.055,
                                decoration: BoxDecoration(
                                  border: Border.all(
                                      width: 0.1,
                                      color:
                                          colors.textColor.withOpacity(0.13)),
                                ),
                                margin: const EdgeInsets.all(5),
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    splashFactory: InkRipple.splashFactory,
                                    splashColor:
                                        colors.themeColor.withOpacity(0.1),
                                    onTap: () {
                                      vibrate();
                                      handleType(index);
                                    },
                                    child: Center(
                                      child: index > 9
                                          ? Icon(
                                              Icons.backspace,
                                              color: colors.textColor,
                                            )
                                          : Text(
                                              "${getIndex(index)}",
                                              style: textTheme.bodyMedium
                                                  ?.copyWith(
                                                color: colors.textColor,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 20,
                                              ),
                                            ),
                                    ),
                                  ),
                                ),
                              ));
                        }),
                      ),
                    ),
                    SizedBox(
                      height: 15,
                    ),
                  ],
                ),
              ),
            ),
          );
        });
      });

  return result ?? false;
}

int getIndex(int index) {
  if (index <= 8) {
    return index + 1;
  } else if (index == 9) {
    return 0;
  }

  return 1;
}
