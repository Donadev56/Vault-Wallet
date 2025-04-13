import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moonwallet/logger/logger.dart';
import 'package:moonwallet/notifiers/providers.dart';
import 'package:moonwallet/types/types.dart';
import 'package:moonwallet/widgets/account_list_view_widget.dart';

class EditWalletView extends ConsumerStatefulWidget {
  final PublicData wallet;
  const EditWalletView({super.key, required this.wallet});

  @override
  ConsumerState<EditWalletView> createState() => _EditWalletViewState();
}

class _EditWalletViewState extends ConsumerState<EditWalletView> {
  AppColors colors = AppColors.defaultTheme;
  @override
  Widget build(BuildContext context) {
    final asyncColor = ref.watch(colorsNotifierProvider);

    asyncColor.whenData((value) => {
          setState(() {
            colors = value ?? AppColors.defaultTheme;
          })
        });

    final providerNotifier = ref.watch(accountsNotifierProvider.notifier);
    final textTheme = Theme.of(context).textTheme;
    final wallet = widget.wallet;

    return Scaffold(
      backgroundColor: colors.primaryColor,
      appBar: AppBar(
        backgroundColor: colors.primaryColor,
        surfaceTintColor: colors.primaryColor,
        title: Text(
          "Edit Wallet",
          style: textTheme.headlineMedium?.copyWith(fontSize: 20),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Column(
            children: [
              Material(
                color: Colors.transparent,
                child: AccountListViewWidget(
                    colors: colors,
                    wallet: wallet,
                    onTap: () => log('clicked'),
                    onMoreTap: () => log("clicked")),
              )
            ],
          ),
        ),
      ),
    );
  }
}
