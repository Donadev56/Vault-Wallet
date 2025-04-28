import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:moonwallet/logger/logger.dart';
import 'package:moonwallet/main.dart';
import 'package:moonwallet/notifiers/providers.dart';
import 'package:moonwallet/screens/dashboard/wallet_actions/private/private_key_screen.dart';
import 'package:moonwallet/service/vibration.dart';
import 'package:moonwallet/types/types.dart';
import 'package:moonwallet/widgets/screen_widgets/account_list_title_widget.dart';
import 'package:moonwallet/widgets/appBar/show_account_options.dart';
import 'package:moonwallet/widgets/appBar/show_wallet_actions.dart';
import 'package:moonwallet/widgets/appBar/wallet_actions.dart';
import 'package:moonwallet/widgets/func/security/ask_password.dart';
import 'package:moonwallet/widgets/func/snackbar.dart';
import 'package:page_transition/page_transition.dart';

class EditWalletsView extends StatefulHookConsumerWidget {
  final AppColors colors;
  final PublicData account;

  const EditWalletsView(
      {super.key, required this.account, required this.colors});

  @override
  ConsumerState<EditWalletsView> createState() => _EditWalletsViewState();
}

class _EditWalletsViewState extends ConsumerState<EditWalletsView> {
  AppColors colors = AppColors.defaultTheme;
  late PublicData account;
  List<PublicData> accounts = [];
  String searchQuery = "";
  @override
  void initState() {
    super.initState();
    colors = widget.colors;
    account = widget.account;
  }

  List<PublicData> filteredList(
      {String query = "", required List<PublicData> accts}) {
    return accts
        .where((account) =>
            account.walletName.toLowerCase().contains(query.toLowerCase()) ||
            account.address.toLowerCase().contains(query.toLowerCase()))
        .toList();
  }

  notifySuccess(String message) => showCustomSnackBar(
      context: context,
      message: message,
      colors: colors,
      type: MessageType.success);
  notifyError(String message) => showCustomSnackBar(
      context: context,
      message: message,
      colors: colors,
      type: MessageType.error);

  @override
  Widget build(BuildContext context) {
    final textTheme = TextTheme.of(context);
    final screen = MediaQuery.of(context).size;
    final height = screen.height;
    final width = screen.width;
    final accountsProvider = ref.watch(accountsNotifierProvider);
    final providerNotifier = ref.watch(accountsNotifierProvider.notifier);
    final uiConfig = useState<AppUIConfig>(AppUIConfig.defaultConfig);
    final appUIConfigAsync = ref.watch(appUIConfigProvider);

    useEffect(() {
      appUIConfigAsync.whenData((data) {
        uiConfig.value = data;
      });
      return null;
    }, [appUIConfigAsync]);

    accountsProvider.whenData((data) {
      setState(
        () {
          accounts = data;
        },
      );
    });

    void close() {
      Navigator.pop(context);
    }

    double iconSizeOf(double size) {
      return size * uiConfig.value.styles.iconSizeScaleFactor;
    }

    double imageSizeOf(double size) {
      return size * uiConfig.value.styles.imageSizeScaleFactor;
    }

    double roundedOf(double size) {
      return size * uiConfig.value.styles.radiusScaleFactor;
    }

    double fontSizeOf(double size) {
      return size * uiConfig.value.styles.fontSizeScaleFactor;
    }

    double listTitleVerticalOf(double size) {
      return size * uiConfig.value.styles.listTitleVisualDensityVerticalFactor;
    }

    double listTitleHorizontalOf(double size) {
      return size *
          uiConfig.value.styles.listTitleVisualDensityHorizontalFactor;
    }

    Future<void> reorderList(int oldIndex, int newIndex) async {
      try {
        final result = await providerNotifier.reorderList(oldIndex, newIndex);
        if (result) {
          log("List reordered successfully");
        } else {
          throw ("Failed to reorder list");
        }
      } catch (e) {
        logError(e.toString());
      }
    }

    Future<void> showPrivateData(int index) async {
      try {
        if (accounts.isEmpty) {
          throw ("No account found");
        }
        final wallet = accounts[index];
        if (wallet.isWatchOnly) {
          Navigator.pop(context);
          throw ("This is a watch-only wallet.");
        }
        String userPassword =
            await askPassword(context: context, colors: colors, useBio: false);

        if (mounted && userPassword.isNotEmpty) {
          Navigator.push(
            context,
            PageTransition(
                type: PageTransitionType.fade,
                child: PrivateKeyScreen(
                  account: wallet,
                  password: userPassword,
                  colors: colors,
                )),
          );
        }
      } catch (e) {
        logError(e.toString());
        if (mounted) {
          notifyError(e.toString());
        }
      }
    }

    Future<void> changeWallet(int index) async {
      try {
        if (accounts.isEmpty) {
          throw ("No account found");
        }

        final wallet = accounts[index];
        await ref
            .read(lastConnectedKeyIdNotifierProvider.notifier)
            .updateKeyId(wallet.keyId);
        close();
      } catch (e) {
        logError(e.toString());
        if (mounted) {
          notifyError(e.toString());
        }
      }
    }

    Future<bool> deleteWallet(String walletId) async {
      try {
        if (accounts.isEmpty) {
          logError("No account found ");
          return false;
        }
        if (accounts.isEmpty) {
          throw ("No account found");
        }
        final password =
            await askPassword(context: context, colors: colors, useBio: false);
        final accountToRemove =
            accounts.where((acc) => acc.keyId == walletId).first;
        if (password.isNotEmpty) {
          // validateThePassword
          final result =
              await providerNotifier.walletSaver.getDecryptedData(password);
          if (result == null) {
            throw ("Invalid password");
          }
          final deleteResult =
              await providerNotifier.deleteWallet(accountToRemove);
          if (deleteResult) {
            notifySuccess("Account deleted successfully");
            close();
            return true;
          } else {
            throw ("Failed to delete account");
          }
        } else {
          logError("Password is required");
          return false;
        }
      } catch (e) {
        logError(e.toString());
        notifyError(e.toString());
        return false;
      }
    }

    Future<bool> editWallet(
        {required PublicData account,
        Color? color,
        IconData? icon,
        String? name}) async {
      try {
        if (accounts.isEmpty) {
          logError("No account found ");
          return false;
        }
        final result = await providerNotifier.editWallet(
          account: account,
          name: name,
          icon: icon,
          color: color,
        );
        if (result) {
          /*
         final index = accounts.indexWhere((acc)=> acc.keyId.trim().toLowerCase() == account.keyId.trim().toLowerCase() );

          List<PublicData> newList = accounts;
          newList[index] = PublicData(keyId: account.keyId, walletIcon: icon ?? account.walletIcon, walletColor: color ?? account.walletColor , creationDate: account.creationDate, walletName: name ?? account.walletName, address: account.address, isWatchOnly: account.isWatchOnly);
          setState(() {
            accounts = newList ;
          });*/
          log("Account updated successfully");

          return true;
        } else {
          throw ("Failed to update account");
        }
      } catch (e) {
        logError(e.toString());
        notifyError(e.toString());
        return false;
      }
    }

    return Scaffold(
      backgroundColor: colors.primaryColor,
      appBar: AppBar(
        centerTitle: true,
        leading: IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: Icon(
              Icons.arrow_back,
              color: colors.textColor.withValues(alpha: 0.6),
            )),
        title: Text(
          "Wallets",
          style: textTheme.bodyMedium?.copyWith(
            color: colors.textColor.withValues(alpha: 0.6),
            fontSize: fontSizeOf(20),
          ),
        ),
        backgroundColor: colors.primaryColor,
        surfaceTintColor: colors.primaryColor,
      ),
      body: SingleChildScrollView(
        child: Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
              borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(roundedOf(15)),
                  topRight: Radius.circular(roundedOf(15))),
              color: colors.primaryColor),
          child: Column(
            children: [
              // search
              Padding(
                padding: const EdgeInsets.only(
                    bottom: 15, left: 20, right: 20, top: 5),
                child: TextField(
                    style: textTheme.bodyMedium?.copyWith(
                        color: colors.textColor,
                        fontSize: fontSizeOf(14),
                        fontWeight: FontWeight.w500),
                    onChanged: (value) {
                      setState(() {
                        searchQuery = value;
                      });
                    },
                    cursorColor: colors.textColor.withOpacity(0.4),
                    decoration: InputDecoration(
                      prefixIcon: Icon(
                        Icons.search,
                        color: colors.textColor.withOpacity(0.3),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          vertical: 0, horizontal: 20),
                      filled: true,
                      fillColor: colors.textColor.withOpacity(0.05),
                      enabledBorder: OutlineInputBorder(
                          borderSide:
                              BorderSide(color: Colors.transparent, width: 0),
                          borderRadius: BorderRadius.circular(roundedOf(5))),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(roundedOf(5)),
                      ),
                      focusedBorder: OutlineInputBorder(
                          borderSide:
                              BorderSide(color: Colors.transparent, width: 0),
                          borderRadius: BorderRadius.circular(roundedOf(5))),
                      hintText: 'Search wallets',
                      hintStyle: textTheme.bodySmall?.copyWith(
                          fontSize: fontSizeOf(14),
                          fontWeight: FontWeight.normal,
                          color: colors.textColor.withOpacity(0.4)),
                    )),
              ),

              // account list

              SingleChildScrollView(
                  physics: ClampingScrollPhysics(),
                  child: LayoutBuilder(builder: (ctx, c) {
                    return ConstrainedBox(
                        constraints: BoxConstraints(maxHeight: height * 0.70),
                        child: GlowingOverscrollIndicator(
                            color: colors.themeColor,
                            axisDirection: AxisDirection.down,
                            child: ReorderableListView.builder(
                                proxyDecorator: (child, index, animation) {
                                  return AnimatedContainer(
                                    duration: Duration(seconds: 1),
                                    child: Transform.scale(
                                      scale: 1.1,
                                      child: Material(
                                        shadowColor: Colors.transparent,
                                        elevation: 0,
                                        color: colors.secondaryColor,
                                        child: child,
                                      ),
                                    ),
                                  );
                                },
                                shrinkWrap: true,
                                physics: ClampingScrollPhysics(),
                                itemCount: filteredList(
                                        query: searchQuery, accts: accounts)
                                    .length,
                                itemBuilder: (ctx, index) {
                                  final wallet = filteredList(
                                      query: searchQuery,
                                      accts: accounts)[index];

                                  return SizedBox(
                                      key: Key("$index"),
                                      child: Material(
                                          color: Colors.transparent,
                                          child: Padding(
                                            padding: EdgeInsets.symmetric(
                                                vertical: 4, horizontal: 20),
                                            child: AccountListTitleWidget(
                                                listTitleHorizontalOf:
                                                    listTitleHorizontalOf,
                                                listTitleVerticalOf:
                                                    listTitleVerticalOf,
                                                imageSizeOf: imageSizeOf,
                                                iconSizeOf: iconSizeOf,
                                                fontSizeOf: fontSizeOf,
                                                roundedOf: roundedOf,
                                                isCurrent: wallet.keyId ==
                                                    account.keyId,
                                                colors: colors,
                                                tileColor: (wallet.keyId ==
                                                        account.keyId
                                                    ? Colors.transparent
                                                    : wallet.walletColor
                                                                ?.value !=
                                                            0x00000000
                                                        ? wallet.walletColor
                                                        : Colors.transparent),
                                                wallet: wallet,
                                                onTap: () async {
                                                  await vibrate();
                                                  changeWallet(index);

                                                  // edit the account self
                                                },
                                                onMoreTap: () async {
                                                  try {
                                                    showAccountOptions(
                                                      originalList: accounts,
                                                      context: context,
                                                      colors: colors,
                                                      availableAccounts:
                                                          filteredList(
                                                              query:
                                                                  searchQuery,
                                                              accts: accounts),
                                                      wallet: wallet,
                                                      editWallet: editWallet,
                                                      deleteWallet:
                                                          deleteWallet,
                                                      updateListAccount:
                                                          (accts) {
                                                        setState(() {
                                                          accounts = accts;
                                                        });
                                                      },
                                                      showPrivateData:
                                                          showPrivateData,
                                                      index: index,
                                                    );
                                                  } catch (e) {
                                                    logError(e.toString());
                                                  }
                                                }),
                                          )));
                                },

                                /*   */

                                onReorder: (int oldIndex, int newIndex) {
                                  vibrate();
                                  reorderList(oldIndex, newIndex);

                                  setState(() {});
                                })));
                  })),
              // bottom
              SizedBox(
                height: 15,
              ),
              LayoutBuilder(builder: (ctx, c) {
                return SizedBox(
                  width: width,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: ElevatedButton.icon(
                      onPressed: () {
                        vibrate();

                        showAppBarWalletActions(
                            child: WalletActions(
                                roundedOf: roundedOf,
                                fontSizeOf: fontSizeOf,
                                iconSizeOf: iconSizeOf,
                                colors: colors),
                            context: context,
                            colors: colors);
                      },
                      icon: Icon(Icons.add, color: colors.primaryColor),
                      label: Text(
                        "Add Wallet",
                        style: textTheme.bodyMedium?.copyWith(
                            fontSize: fontSizeOf(16),
                            color: colors.primaryColor,
                            fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(
                            vertical: 0, horizontal: 8),
                        backgroundColor: colors.themeColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(roundedOf(25)),
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}
