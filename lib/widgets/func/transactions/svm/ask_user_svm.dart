// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:moonwallet/logger/logger.dart';
import 'package:moonwallet/types/account_related_types.dart';
import 'package:moonwallet/types/types.dart';
import 'package:moonwallet/widgets/buttons/elevated.dart';
import 'package:moonwallet/widgets/custom_filled_text_field.dart';
import 'package:moonwallet/widgets/func/transactions/svm/show_memo_input.dart';
import 'package:moonwallet/widgets/func/transactions/transactions_body/label_text.dart';
import 'package:moonwallet/widgets/func/transactions/transactions_body/show_transaction_request.dart';
import 'package:moonwallet/widgets/func/transactions/transactions_body/transaction_app_bar.dart';
import 'package:moonwallet/widgets/func/transactions/transactions_body/transaction_destination_details.dart';
import 'package:moonwallet/widgets/func/transactions/transactions_body/transaction_parent_container.dart';
import 'package:moonwallet/widgets/func/transactions/transactions_body/transaction_token_details.dart';

Future<SolanaRequestResponse?> askUserSvm({
  required Crypto crypto,
  required BuildContext context,
  required AppColors colors,
  required String from,
  required String to,
  required String value,
}) async {
  try {
    final memoController = TextEditingController();
    final result = await showTransactionRequest<SolanaRequestResponse>(
      context: context,
      builder: (BuildContext context) {
        final textTheme = Theme.of(context).textTheme;
        return StatefulBuilder(
          builder: (BuildContext ctx, StateSetter setModalState) {
            return TransactionParentContainer(
              colors: colors,
              child: ListView(
                shrinkWrap: true,
                children: [
                  TransactionAppBar(
                      padding: const EdgeInsets.only(bottom: 10),
                      colors: colors,
                      title: "Transfer",
                      actions: [
                        IconButton(
                          onPressed: () {
                            Navigator.pop(
                              context,
                            );
                          },
                          icon: Icon(FeatherIcons.xCircle,
                              color: Colors.pinkAccent),
                        )
                      ]),
                  TransactionTokenDetails(
                      colors: colors, crypto: crypto, value: value),
                  SizedBox(
                    height: 10,
                  ),
                  TransactionDestinationDetails(
                      colors: colors, crypto: crypto, from: from, to: to),
                  SizedBox(
                    height: 15,
                  ),
                  Align(
                      alignment: Alignment.centerLeft,
                      child: LabelText(colors: colors, text: "Memo")),
                  SizedBox(
                    height: 10,
                  ),
                  CustomFilledTextFormField(
                      controller: memoController,
                      onTap: () async {
                        final memo = await showMemoInput(
                            context: context,
                            colors: colors,
                            initialText: memoController.text);
                        if (memo != null) {
                          memoController.text = memo;
                        }
                      },
                      readOnly: true,
                      suffixIcon: Icon(
                        Icons.article,
                        color: colors.textColor,
                        size: 20,
                      ),
                      hintText: "Memo",
                      colors: colors,
                      fontSizeOf: (v) => v,
                      iconSizeOf: (v) => v,
                      roundedOf: (v) => v),
                  SizedBox(
                    height: 40,
                  ),
                  CustomElevatedButton(
                    onPressed: () {
                      Navigator.pop(
                          context,
                          SolanaRequestResponse(
                              ok: true,
                              memo: memoController.text.isEmpty
                                  ? null
                                  : memoController.text));
                    },
                    colors: colors,
                    text: "Confirm",
                  ),
                  SizedBox(
                    height: 20,
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    return result;
  } catch (e) {
    logError(e.toString());
    return null;
  }
}
