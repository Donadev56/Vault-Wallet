import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:moonwallet/service/vibration.dart';
import 'package:moonwallet/types/types.dart';
import 'package:moonwallet/widgets/flowting_modat.dart';
import 'package:moonwallet/widgets/func/show_change_text_dialog.dart';
import 'package:moonwallet/widgets/func/show_color.dart';
import 'package:moonwallet/utils/constant.dart';
import '../../logger/logger.dart';

typedef EditWalletNameType = Future<bool> Function(
    {required PublicData account, String? name, IconData? icon, Color? color});
void showAccountOptions({
  required BuildContext context,
  required AppColors colors,
  required List<PublicData> availableAccounts,
  required List<PublicData> originalList,
  required PublicData wallet,
  required EditWalletNameType editWallet,
  required Future<bool> Function(String keyId) deleteWallet,
  required void Function(List<PublicData> accounts) updateListAccount,
  required void Function(int index) showPrivateData,
  required int index,
}) {
  TextEditingController textController = TextEditingController();
  showFloatingModalBottomSheet(
      backgroundColor: colors.primaryColor,
      context: context,
      builder: (ctx) {
        final originalAccount = originalList
            .where((acc) => acc.keyId == wallet.keyId)
            .toList()
            .first;
        final textTheme = Theme.of(ctx).textTheme;

        return ListView.builder(
            itemCount: appBarButtonOptions.length,
            shrinkWrap: true,
            itemBuilder: (ctx, i) {
              final opt = appBarButtonOptions[i];
              final isLast = i == appBarButtonOptions.length - 1;

              return Material(
                  color: Colors.transparent,
                  child: ListTile(
                      tileColor: isLast
                          ? colors.redColor.withOpacity(0.1)
                          : Colors.transparent,
                      leading: Icon(
                        opt["icon"] ?? Icons.integration_instructions,
                        color: isLast
                            ? colors.redColor
                            : colors.textColor.withOpacity(0.8),
                      ),
                      title: Text(
                        opt["name"] ?? "",
                        style: textTheme.bodyMedium?.copyWith(
                          color: isLast
                              ? colors.redColor
                              : colors.textColor.withOpacity(0.8),
                        ),
                      ),
                      onTap: () async {
                        vibrate();

                        if (i == 0) {
                          textController.text =
                              availableAccounts[index].walletName;
                          showChangeTextDialog(
                              context: context,
                              colors: colors,
                              textController: textController,
                              onSubmit: (v) async {
                                log("Submitted $v");

                                editWallet(
                                  account: originalAccount,
                                  name: v,
                                );
                                textController.text = "";
                              });
                        } else if (i == 4) {
                          final response = await deleteWallet(wallet.keyId);

                          if (response == true) {
                            updateListAccount(availableAccounts
                                .where((account) =>
                                    account.keyId != originalAccount.keyId)
                                .toList());
                            Navigator.pop(context);
                          }
                        } else if (i == 2) {
                          Clipboard.setData(
                              ClipboardData(text: wallet.address));
                        } else if (i == 3) {
                          showPrivateData(
                              originalList.indexOf(originalAccount));
                        } else if (i == 1) {
                          showColorPicker(
                              onSelect: (c) async {
                                await editWallet(
                                    account: originalAccount,
                                    color: colorList[c]);
                              },
                              context: context,
                              colors: colors);
                        }
                      }));
            });
      });
}
