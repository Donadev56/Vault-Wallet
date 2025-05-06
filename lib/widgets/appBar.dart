// ignore_for_file: deprecated_member_use

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moonwallet/screens/dashboard/main/edit_wallets.dart';
import 'package:moonwallet/service/vibration.dart';
import 'package:moonwallet/types/account_related_types.dart';
import 'package:moonwallet/types/types.dart';
import 'package:moonwallet/widgets/appBar/show_custom_drawer.dart';
import 'package:moonwallet/widgets/appBar/show_wallet_actions.dart';
import 'package:moonwallet/widgets/appBar/wallet_actions.dart';
import 'package:page_transition/page_transition.dart';

typedef DoubleFactor = double Function(double size);

typedef EditWalletNameType = void Function(String newName, int index);
typedef ActionWithIndexType = void Function(int index);
typedef ActionWithCryptoId = Future<bool> Function(
    String cryptoId, BuildContext? context);

typedef ReorderList = Future<void> Function(int oldIndex, int newIndex);
typedef SearchWallet = void Function(String query);

class CustomAppBar extends ConsumerWidget implements PreferredSizeWidget {
  final Color primaryColor;
  final Color textColor;
  final Color surfaceTintColor;
  final List<Crypto> availableCryptos;
  final List<PublicAccount> accounts;
  final String totalBalanceUsd;
  final Future<bool> Function(String keyId) deleteWallet;
  final PublicAccount currentAccount;
  final ActionWithIndexType changeAccount;
  final ActionWithIndexType showPrivateData;
  final ReorderList reorderList;
  final Color secondaryColor;
  final GlobalKey<ScaffoldState> scaffoldKey;
  final File? profileImage;
  final double balanceOfAllAccounts;
  final bool isHidden;
  final AppColors colors;
  final Future<bool> Function(File) changeProfileImage;
  final Future<bool> Function(bool state) toggleCanUseBio;
  final bool canUseBio;
  final Future<bool> Function(
      {required PublicAccount account,
      String? name,
      IconData? icon,
      Color? color}) editWallet;

  final DoubleFactor roundedOf;
  final DoubleFactor fontSizeOf;
  final DoubleFactor iconSizeOf;
  final DoubleFactor imageSizeOf;
  final DoubleFactor listTitleHorizontalOf;
  final DoubleFactor listTitleVerticalOf;

  const CustomAppBar(
      {super.key,
      required this.canUseBio,
      required this.totalBalanceUsd,
      required this.primaryColor,
      required this.textColor,
      required this.surfaceTintColor,
      required this.changeAccount,
      required this.secondaryColor,
      required this.reorderList,
      required this.showPrivateData,
      required this.scaffoldKey,
      required this.balanceOfAllAccounts,
      required this.isHidden,
      required this.colors,
      required this.availableCryptos,
      required this.profileImage,
      required this.editWallet,
      required this.toggleCanUseBio,
      required this.deleteWallet,
      required this.currentAccount,
      required this.changeProfileImage,
      required this.accounts,
      required this.fontSizeOf,
      required this.iconSizeOf,
      required this.imageSizeOf,
      required this.listTitleHorizontalOf,
      required this.listTitleVerticalOf,
      required this.roundedOf});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // ignore: no_leading_underscores_for_local_identifiers
    final textTheme = Theme.of(context).textTheme;

    return AppBar(
      backgroundColor: primaryColor,
      surfaceTintColor: colors.grayColor.withOpacity(0.1),
      leading: IconButton(
          onPressed: () {
            showCustomDrawer(
                iconSizeOf: iconSizeOf,
                imageSizeOf: imageSizeOf,
                listTitleHorizontalOf: listTitleHorizontalOf,
                listTitleVerticalOf: listTitleHorizontalOf,
                fontSizeOf: fontSizeOf,
                roundedOf: roundedOf,
                changeProfileImage: changeProfileImage,
                isHidden: isHidden,
                toggleCanUseBio: toggleCanUseBio,
                canUseBio: canUseBio,
                deleteWallet: (acc) async {
                  deleteWallet(acc.keyId);
                },
                editWallet: editWallet,
                totalBalanceUsd: totalBalanceUsd,
                context: context,
                profileImage: profileImage,
                colors: colors,
                account: currentAccount,
                availableCryptos: availableCryptos);
          },
          icon: profileImage != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(roundedOf(50)),
                  child: Image.file(
                    profileImage!,
                    width: imageSizeOf(30),
                    height: imageSizeOf(30),
                    fit: BoxFit.cover,
                  ),
                )
              : Icon(
                  Icons.person,
                  color: textColor,
                )),
      title: Material(
        color: Colors.transparent,
        child: InkWell(
            borderRadius: BorderRadius.circular(roundedOf(10)),
            onTap: () async {
              await vibrate(duration: 10);

              Navigator.of(context).push(PageTransition(
                  type: PageTransitionType.rightToLeftWithFade,
                  child: EditWalletsView(
                    colors: colors,
                    account: currentAccount,
                  )));
              /*  showAccountList(
                colors: colors,
                context: context,
                accounts: accounts,
                currentAccount: currentAccount,
                editWallet: editWallet,
                deleteWallet: (id) async {
                  final res = await deleteWallet(id);
                  return res;
                },
                changeAccount: changeAccount,
                showPrivateData: showPrivateData,
                reorderList: reorderList,
              ); */
            },
            child: Container(
              padding: const EdgeInsets.all(2),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(currentAccount.walletName,
                      style: textTheme.bodyMedium?.copyWith(
                          fontSize: fontSizeOf(16),
                          color: textColor.withOpacity(0.8))),
                  SizedBox(
                    width: 5,
                  ),
                  Icon(
                    FeatherIcons.chevronDown,
                    color: textColor,
                  )
                ],
              ),
            )),
      ),
      actions: <Widget>[
        IconButton(
            onPressed: () async {
              showAppBarWalletActions(children: [
                WalletActions(
                    iconSizeOf: iconSizeOf,
                    fontSizeOf: fontSizeOf,
                    roundedOf: roundedOf,
                    colors: colors)
              ], context: context, colors: colors);
            },
            icon: Icon(
              Icons.add,
              color: textColor.withOpacity(0.7),
            )),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class CustomPopupMenuItem<T> extends PopupMenuEntry<T> {
  final T value;
  final Widget child;
  @override
  final double height;
  final VoidCallback onTap;

  const CustomPopupMenuItem({
    super.key,
    required this.value,
    required this.child,
    this.height = kMinInteractiveDimension,
    required this.onTap,
  });

  @override
  bool represents(T? value) => this.value == value;

  @override
  CustomPopupMenuItemState<T> createState() => CustomPopupMenuItemState<T>();
}

class CustomPopupMenuItemState<T> extends State<CustomPopupMenuItem<T>> {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: widget.height,
      alignment: Alignment.centerLeft,
      child: PopupMenuItem(
        onTap: widget.onTap,
        child: widget.child,
      ),
    );
  }
}
