// ignore_for_file: deprecated_member_use, use_build_context_synchronously

import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:moonwallet/custom/web3_webview/lib/utils/loading.dart';
import 'package:moonwallet/custom/web3_webview/lib/widgets/alert.dart';
import 'package:moonwallet/main.dart';
import 'package:moonwallet/notifiers/providers.dart';
import 'package:moonwallet/service/db/wallet_db.dart';
import 'package:moonwallet/utils/colors.dart';
import 'package:moonwallet/utils/crypto.dart';
import 'package:moonwallet/utils/themes.dart';
import 'package:moonwallet/widgets/appBar/button.dart';
import 'package:moonwallet/widgets/appBar/show_wallet_actions.dart';
import 'package:moonwallet/widgets/func/security/ask_password.dart';
import 'package:moonwallet/widgets/screen_widgets/crypto_picture.dart';
import 'package:moonwallet/widgets/func/tokens_config/show_add_network.dart';
import 'package:moonwallet/widgets/func/tokens_config/show_add_token.dart';
import 'package:moonwallet/widgets/func/snackbar.dart';
import 'package:moonwallet/widgets/func/tokens_config/show_edit_network_modal.dart';
import 'package:moonwallet/widgets/func/tokens_config/show_select_network_modal.dart';
import 'package:moonwallet/widgets/solana_related/dialogs/show_first_solana_use_dialog.dart';
import 'package:ulid/ulid.dart';

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:moonwallet/logger/logger.dart';
import 'package:moonwallet/service/db/crypto_storage_manager.dart';
import 'package:moonwallet/service/web3_interactions/evm/token_manager.dart';
import 'package:moonwallet/types/types.dart';
import 'package:moonwallet/utils/prefs.dart';

class AddCryptoView extends StatefulHookConsumerWidget {
  final AppColors? colors;
  const AddCryptoView({super.key, this.colors});

  @override
  ConsumerState<AddCryptoView> createState() => _AddCryptoViewState();
}

class _AddCryptoViewState extends ConsumerState<AddCryptoView> {
  bool isDarkMode = true;
  List<Crypto> reorganizedCrypto = [];
  final cryptoStorageManager = CryptoStorageManager();
  final tokenManager = TokenManager();
  List<PublicData> accounts = [];
  final web3Manager = WalletDatabase();
  final encryptService = EncryptService();

  bool hasSaved = false;
  PublicData? currentAccount;
  final nullAccount = PublicData(
      createdLocally: false,
      keyId: "",
      creationDate: 0,
      walletName: "",
      addresses: [],
      isWatchOnly: false);
  final TextEditingController _searchController = TextEditingController();

  final publicDataManager = PublicDataManager();
  AppColors colors = AppColors.defaultTheme;

  bool saved = false;
  Themes themes = Themes();
  String savedThemeName = "";
  Future<void> getSavedTheme() async {
    try {
      final manager = ColorsManager();
      final savedName = await manager.getThemeName();
      setState(() {
        savedThemeName = savedName ?? "";
      });
      final savedTheme = await manager.getDefaultTheme();
      setState(() {
        colors = savedTheme;
      });
    } catch (e) {
      logError(e.toString());
    }
  }

  @override
  void initState() {
    super.initState();
    if (widget.colors != null) {
      setState(() {
        colors = widget.colors!;
      });
    }
    getSavedTheme();
  }

  String generateUUID() {
    return Ulid().toUuid();
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
    final textTheme = Theme.of(context).textTheme;
    final width = MediaQuery.of(context).size.width;
    final currentAccountAsync = ref.watch(currentAccountProvider);
    final savedCryptoAsync = ref.watch(savedCryptosProviderNotifier);
    final savedCryptoProvider =
        ref.watch(savedCryptosProviderNotifier.notifier);
    final accountsProvider = ref.watch(accountsNotifierProvider);
    final appUIConfigAsync = ref.watch(appUIConfigProvider);

    final uiConfig = useState<AppUIConfig>(AppUIConfig.defaultConfig);

    useEffect(() {
      appUIConfigAsync.whenData((data) {
        uiConfig.value = data;
      });
      return null;
    }, [appUIConfigAsync]);

    /* double listTitleVerticalOf(double size) {
      return size * uiConfig.value.styles.listTitleVisualDensityVerticalFactor;
    }

    double listTitleHorizontalOf(double size) {
      return size *
          uiConfig.value.styles.listTitleVisualDensityHorizontalFactor;
    } */
    double fontSizeOf(double size) {
      return size * uiConfig.value.styles.fontSizeScaleFactor;
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

    savedCryptoAsync.whenData((data) => {
          setState(() {
            final cryptos = data;
            if (cryptos.isNotEmpty) {
              cryptos.sort((a, b) => a.symbol.compareTo(b.symbol));
              setState(() {
                reorganizedCrypto = cryptos;
              });
            }
          })
        });

    accountsProvider.whenData((data) => {
          setState(() {
            accounts = data;
          })
        });

    currentAccountAsync.whenData((value) => setState(() {
          currentAccount = value;
        }));

    Future<void> addCrypto(SearchingContractInfo? contractInfo,
        String contractAddress, Crypto? network) async {
      try {
        {
          final newCrypto = Crypto(
              symbol: contractInfo?.symbol ?? "",
              name: contractInfo?.name ?? "Unknown ",
              color: network?.color ?? Colors.white,
              type: CryptoType.token,
              cryptoId: generateUUID(),
              canDisplay: true,
              network: network,
              decimals: contractInfo?.decimals.toInt() ?? 1,
              contractAddress: contractAddress);

          final saveResult = await savedCryptoProvider.addCrypto(newCrypto);
          if (saveResult) {
            hasSaved = true;
            notifySuccess('Token added successfully.');

            Navigator.pop(context);
          } else {
            notifyError('Error adding token.');
            Navigator.pop(context);
          }
        }
      } catch (e) {
        logError(e.toString());
        notifyError(e.toString());
      }
    }

    Future<void> addNetwork(Crypto newCrypto) async {
      try {
        {
          final saveResult = await savedCryptoProvider.addCrypto(newCrypto);
          if (saveResult) {
            hasSaved = true;
            notifySuccess('Network added successfully.');

            Navigator.pop(context);
          } else {
            notifyError('Error adding token.');
            Navigator.pop(context);
          }
        }
      } catch (e) {
        logError(e.toString());
        notifyError(e.toString());
      }
    }

    Future<bool> editNetwork(
        {required int chainId,
        String? name,
        String? symbol,
        List<String>? explorers,
        List<String>? rpcUrls}) async {
      try {
        if (currentAccount == null) {
          throw "No account found";
        }

        final result = await savedCryptoProvider.editNetwork(
            chainId: chainId,
            symbol: symbol,
            name: name,
            rpcUrls: rpcUrls,
            explorers: explorers,
            currentAccount: currentAccount!);
        if (result) {
          notifySuccess("Network Edited");
        }

        return result;
      } catch (e) {
        logError(e.toString());
        notifyError(e.toString());
        return false;
      }
    }

    return Scaffold(
      backgroundColor: colors.primaryColor,
      appBar: AppBar(
        surfaceTintColor: colors.primaryColor,
        backgroundColor: colors.primaryColor,
        actions: [
          Container(
            margin: const EdgeInsets.all(10),
            height: 35,
            width: 35,
            decoration: BoxDecoration(
                color: colors.grayColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(roundedOf(5))),
            child: IconButton(
              onPressed: () {
                showAppBarWalletActions(
                  context: context,
                  colors: colors,
                  children: [
                    Column(
                      spacing: 10,
                      children: [
                        CustomListTitleButton(
                            roundedOf: roundedOf,
                            fontSizeOf: fontSizeOf,
                            iconSizeOf: iconSizeOf,
                            textColor: colors.textColor,
                            text: "Add custom token",
                            icon: Icons.add,
                            onTap: () {
                              showAddToken(
                                  roundedOf: roundedOf,
                                  fontSizeOf: fontSizeOf,
                                  iconSizeOf: iconSizeOf,
                                  reorganizedCrypto: reorganizedCrypto,
                                  notifyError: notifyError,
                                  notifySuccess: notifySuccess,
                                  addCrypto: addCrypto,
                                  context: context,
                                  colors: colors,
                                  width: width,
                                  hasSaved: hasSaved);
                            }),
                        CustomListTitleButton(
                            roundedOf: roundedOf,
                            fontSizeOf: fontSizeOf,
                            iconSizeOf: iconSizeOf,
                            textColor: colors.textColor,
                            text: "Add custom network",
                            icon: Icons.construction,
                            onTap: () async {
                              final newNetwork = await showAddNetwork(
                                  roundedOf: roundedOf,
                                  fontSizeOf: fontSizeOf,
                                  iconSizeOf: iconSizeOf,
                                  context: context,
                                  colors: colors);
                              if (newNetwork != null) {
                                if (reorganizedCrypto.any(
                                    (c) => c.chainId == newNetwork.chainId)) {
                                  notifyError("Network already exist");
                                  return;
                                }
                                addNetwork(newNetwork)
                                    .withLoading(context, colors);
                              }
                            }),
                        CustomListTitleButton(
                            roundedOf: roundedOf,
                            fontSizeOf: fontSizeOf,
                            iconSizeOf: iconSizeOf,
                            textColor: colors.textColor,
                            text: "Edit network",
                            icon: Icons.border_color,
                            onTap: () async {
                              final selectedNetwork =
                                  await showSelectNetworkModal(
                                      roundedOf: roundedOf,
                                      fontSizeOf: fontSizeOf,
                                      iconSizeOf: iconSizeOf,
                                      context: context,
                                      colors: colors,
                                      networks: reorganizedCrypto);
                              if (selectedNetwork != null) {
                                showEditNetwork(
                                    roundedOf: roundedOf,
                                    fontSizeOf: fontSizeOf,
                                    iconSizeOf: iconSizeOf,
                                    context: context,
                                    network: selectedNetwork,
                                    onSubmitted: editNetwork,
                                    colors: colors);
                              }
                            })
                      ],
                    )
                  ],
                );
              },
              icon: Icon(
                LucideIcons.plus,
                color: colors.textColor,
                size: iconSizeOf(20),
              ),
            ),
          ),
        ],
        leading: IconButton(
            onPressed: () {
              Navigator.pushNamed(context, Routes.pageManager);
            },
            icon: Icon(
              LucideIcons.chevronLeft,
              color: colors.textColor,
            )),
        title: Text(
          "Manage Coins ",
          style: textTheme.bodyMedium
              ?.copyWith(color: colors.textColor, fontSize: fontSizeOf(20)),
        ),
      ),
      body: Column(
        spacing: 15,
        children: [
          SizedBox(
            height: 10,
          ),
          Align(
            alignment: Alignment.center,
            child: SizedBox(
              width: width * 0.92,
              child: TextField(
                onChanged: (v) {
                  setState(() {
                    _searchController.text = v;
                  });
                },
                style: textTheme.bodyMedium?.copyWith(color: colors.textColor),
                cursorColor: colors.themeColor,
                controller: _searchController,
                decoration: InputDecoration(
                    hintText: "Search Crypto",
                    hintStyle: textTheme.bodyMedium
                        ?.copyWith(color: colors.textColor.withOpacity(0.4)),
                    contentPadding:
                        const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                    prefixIcon: Icon(
                      Icons.search,
                      color: colors.textColor.withOpacity(0.3),
                    ),
                    filled: true,
                    fillColor: colors.grayColor.withOpacity(0.1),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(roundedOf(10)),
                        borderSide:
                            BorderSide(width: 0, color: Colors.transparent)),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(roundedOf(10)),
                        borderSide:
                            BorderSide(width: 0, color: Colors.transparent))),
              ),
            ),
          ),
          Expanded(
              child: GlowingOverscrollIndicator(
            axisDirection: AxisDirection.down,
            color: colors.themeColor,
            child: ListView.builder(
                itemCount: reorganizedCrypto
                    .where((c) => c.symbol
                        .toLowerCase()
                        .contains(_searchController.text.toLowerCase()))
                    .length,
                itemBuilder: (ctx, i) {
                  final crypto = reorganizedCrypto
                      .where((c) => c.symbol
                          .toLowerCase()
                          .contains(_searchController.text.toLowerCase()))
                      .toList()[i];

                  return Material(
                    color: Colors.transparent,
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                          vertical: 8, horizontal: 20),
                      onTap: () {},
                      leading: CryptoPicture(
                          crypto: crypto,
                          size: imageSizeOf(40),
                          colors: colors),
                      title: Text(
                        crypto.symbol,
                        style: textTheme.bodyMedium?.copyWith(
                            color: colors.textColor,
                            fontSize: fontSizeOf(16),
                            fontWeight: FontWeight.bold),
                      ),
                      trailing: Switch(
                          value: crypto.canDisplay,
                          onChanged: (newVal) async {
                            try {
                              if (crypto.getNetworkType == NetworkType.svm &&
                                  currentAccount?.svmAddress == null) {
                                final confirm = await showFirstUseDialog(
                                    context: context, colors: colors);
                                if (confirm) {
                                  final password = await askPassword(
                                      context: context, colors: colors);
                                  if (password.isNotEmpty) {
                                    try {
                                      final result = await savedCryptoProvider
                                          .toggleAndEnableSolana(
                                              crypto, newVal, password)
                                          .withLoading(
                                            context,
                                            colors,
                                            "Creating Solana wallet",
                                          );
                                      if (!result) {
                                        showAlert(
                                            context: context,
                                            colors: colors,
                                            title: "Invalid Account",
                                            content:
                                                "Create a new valid wallet and try again.",
                                            confirmText: "Ok");
                                      }
                                    } catch (e) {
                                      logError(e.toString());
                                      notifyError(e.toString());
                                      return;
                                    }
                                  }

                                  return;
                                }
                                return;
                              }
                              final result = await savedCryptoProvider
                                  .toggleCanDisplay(crypto, newVal);

                              if (result) {
                                log("State changed successfully");
                              } else {
                                log("Error changing state");
                              }
                            } catch (e) {
                              logError(e.toString());
                              showCustomSnackBar(
                                  context: context,
                                  message: e.toString(),
                                  colors: colors,
                                  type: MessageType.error);
                            }
                          }),
                    ),
                  );
                }),
          ))
        ],
      ),
    );
  }
}
