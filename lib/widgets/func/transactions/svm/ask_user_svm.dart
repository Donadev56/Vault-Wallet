// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:moonwallet/logger/logger.dart';
import 'package:moonwallet/types/types.dart';
import 'package:moonwallet/widgets/custom_filled_text_field.dart';
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
                    height: 10,
                  ),
                  Align(
                      alignment: Alignment.centerLeft,
                      child: LabelText(colors: colors, text: "Memo")),
                  SizedBox(
                    height: 10,
                  ),
                  CustomFilledTextFormField(
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
                  ElevatedButton(
                      onPressed: () {},
                      child: Text(
                        "Confirm",
                        style: textTheme.bodyMedium?.copyWith(
                          color: colors.primaryColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ))
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
