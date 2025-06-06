// ignore_for_file: deprecated_member_use, use_build_context_synchronously

import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:moonwallet/custom/web3_webview/lib/utils/loading.dart';
import 'package:moonwallet/notifiers/providers.dart';
import 'package:moonwallet/service/crypto_manager.dart';
import 'package:moonwallet/service/db/wallet_db.dart';
import 'package:moonwallet/types/account_related_types.dart';
import 'package:moonwallet/types/ecosystem_config.dart';
import 'package:moonwallet/utils/colors.dart';
import 'package:moonwallet/utils/encrypt_service.dart';
import 'package:moonwallet/utils/themes.dart';
import 'package:moonwallet/widgets/appBar/custom_list_title_button.dart';
import 'package:moonwallet/widgets/appBar/show_wallet_actions.dart';
import 'package:moonwallet/widgets/func/tokens_config/show_additional_tokens.dart';
import 'package:moonwallet/widgets/func/tokens_config/show_token_detials.dart';
import 'package:moonwallet/widgets/screen_widgets/crypto_picture.dart';
import 'package:moonwallet/widgets/func/tokens_config/show_add_network.dart';
import 'package:moonwallet/widgets/func/tokens_config/show_add_token.dart';
import 'package:moonwallet/widgets/dialogs/show_custom_snackbar.dart';
import 'package:moonwallet/widgets/func/tokens_config/show_edit_network_modal.dart';
import 'package:moonwallet/widgets/func/tokens_config/show_select_network_modal.dart';
import 'package:moonwallet/widgets/screen_widgets/custom_switch_list_title.dart';
import 'package:moonwallet/widgets/screen_widgets/standard_app_bar.dart';
import 'package:ulid/ulid.dart';

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:moonwallet/logger/logger.dart';
import 'package:moonwallet/service/db/crypto_storage_manager.dart';
import 'package:moonwallet/service/web3_interactions/evm/token_manager.dart';
import 'package:moonwallet/types/types.dart';

class AddCryptoView extends StatefulHookConsumerWidget {
  final AppColors? colors;
  const AddCryptoView({super.key, this.colors});

  @override
  ConsumerState<AddCryptoView> createState() => _AddCryptoViewState();
}

class _AddCryptoViewState extends ConsumerState<AddCryptoView> {
  bool isDarkMode = true;
  final cryptoStorageManager = CryptoStorageManager();
  final tokenManager = TokenManager();
  List<PublicAccount> accounts = [];
  final web3Manager = WalletDatabase();
  final encryptService = EncryptService();

  bool hasSaved = false;
  PublicAccount? currentAccount;
  final TextEditingController _searchController = TextEditingController();

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

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final width = MediaQuery.of(context).size.width;
    final currentAccountAsync = ref.watch(currentAccountProvider);
    final savedCryptoProvider =
        ref.watch(savedCryptosProviderNotifier.notifier);
    final savedCryptoAsync = ref.watch(savedCryptosProviderNotifier);
    final accountsProvider = ref.watch(accountsNotifierProvider);
    final appUIConfigAsync = ref.watch(appUIConfigProvider);
    final cryptoManager = CryptoManager();

    final uiConfig = useState<AppUIConfig>(AppUIConfig.defaultConfig);
    final allCryptos = useState<List<Crypto>>([]);

    useEffect(() {
      Future<void> getListDefaultTokens() async {
        try {
          final defaultTokens = await cryptoManager.getDefaultTokens();
          final savedTokens = savedCryptoAsync.value ?? [];
          final uniqueTokens = cryptoManager.addOnlyNewTokens(
              localList: savedTokens, externalList: defaultTokens);
          allCryptos.value = uniqueTokens;
        } catch (e) {
          logError(e.toString());
        }
      }

      getListDefaultTokens();
      return null;
    }, [savedCryptoAsync]);

    useEffect(() {
      appUIConfigAsync.whenData((data) {
        uiConfig.value = data;
      });
      return null;
    }, [appUIConfigAsync]);

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
            notifySuccess('Token added successfully.', context);

            Navigator.pop(context);
          } else {
            notifyError('Error adding token.', context);
            Navigator.pop(context);
          }
        }
      } catch (e) {
        logError(e.toString());
        notifyError(e.toString(), context);
      }
    }

    Future<void> addNetwork(Crypto newCrypto) async {
      try {
        {
          final saveResult = await savedCryptoProvider.addCrypto(newCrypto);
          if (saveResult) {
            hasSaved = true;
            notifySuccess('Network added successfully.', context);

            Navigator.pop(context);
          } else {
            notifyError('Error adding token.', context);
            Navigator.pop(context);
          }
        }
      } catch (e) {
        logError(e.toString());
        notifyError(e.toString(), context);
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
          notifySuccess("Network Edited", context);
        }

        return result;
      } catch (e) {
        logError(e.toString());
        notifyError(e.toString(), context);
        return false;
      }
    }

    List<Crypto> getCryptoList() {
      final listTokens = allCryptos.value
          .where((c) =>
              c.symbol
                  .toLowerCase()
                  .contains(_searchController.text.toLowerCase()) ||
              c.name
                  .toLowerCase()
                  .contains(_searchController.text.toLowerCase()))
          .toList();

      final account = currentAccount;
      if (account == null) {
        throw Exception("No account found");
      }

      if (account.origin.isPrivateKey || account.origin.isPublicAddress) {
        return listTokens
            .where((c) => account.supportedNetworks.contains(c.getNetworkType))
            .toList();
      }

      return listTokens;
    }

    void showWalletActions() {
      showAppBarWalletActions(
        context: context,
        colors: colors,
        children: [
          Column(
            spacing: 10,
            children: [
              if (currentAccount?.supportedNetworks.any(
                      (e) => ecosystemInfo[e]?.supportSmartContracts == true) ==
                  true)
                CustomListTitleButton(
                    roundedOf: roundedOf,
                    fontSizeOf: fontSizeOf,
                    iconSizeOf: iconSizeOf,
                    colors: colors,
                    text: "Add custom token",
                    icon: Icons.add,
                    onTap: () {
                      showAddToken(
                          roundedOf: roundedOf,
                          fontSizeOf: fontSizeOf,
                          iconSizeOf: iconSizeOf,
                          reorganizedCrypto: allCryptos.value,
                          addCrypto: addCrypto,
                          context: context,
                          colors: colors,
                          width: width,
                          hasSaved: hasSaved);
                    }),
              if (currentAccount?.origin.isMnemonic == true ||
                  currentAccount?.supportedNetworks.firstOrNull ==
                      NetworkType.evm)
                CustomListTitleButton(
                    roundedOf: roundedOf,
                    fontSizeOf: fontSizeOf,
                    iconSizeOf: iconSizeOf,
                    colors: colors,
                    text: "Add EVM network",
                    icon: Icons.construction,
                    onTap: () async {
                      final newNetwork = await showAddNetwork(
                          roundedOf: roundedOf,
                          fontSizeOf: fontSizeOf,
                          iconSizeOf: iconSizeOf,
                          context: context,
                          colors: colors);
                      if (newNetwork != null) {
                        if (allCryptos.value
                            .any((c) => c.chainId == newNetwork.chainId)) {
                          notifyError("Network already exist", context);
                          return;
                        }
                        addNetwork(newNetwork).withLoading(context, colors);
                      }
                    }),
              CustomListTitleButton(
                  roundedOf: roundedOf,
                  fontSizeOf: fontSizeOf,
                  iconSizeOf: iconSizeOf,
                  colors: colors,
                  text: "Edit network",
                  icon: Icons.border_color,
                  onTap: () async {
                    final selectedNetwork = await showSelectNetworkModal(
                        roundedOf: roundedOf,
                        fontSizeOf: fontSizeOf,
                        iconSizeOf: iconSizeOf,
                        context: context,
                        colors: colors,
                        networks: allCryptos.value);
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
    }

    return Scaffold(
      backgroundColor: colors.primaryColor,
      appBar: StandardAppBar(
        title: "Manage Coins ",
        colors: colors,
        fontSizeOf: fontSizeOf,
        actions: [
          IconButton(
              onPressed: () => showAdditionalTokens(
                  context: context,
                  colors: colors,
                  roundedOf: roundedOf,
                  fontSizeOf: fontSizeOf,
                  iconSizeOf: iconSizeOf),
              icon: Icon(
                Icons.travel_explore,
                color: colors.textColor,
              )),
          IconButton(
            onPressed: () => showWalletActions(),
            icon: Icon(
              LucideIcons.plus,
              color: colors.textColor,
              size: iconSizeOf(20),
            ),
          ),
        ],
      ),
      body: Column(
        spacing: 15,
        children: [
          Align(
            alignment: Alignment.center,
            child: SizedBox(
              width: width * 0.92,
              height: 50,
              child: TextField(
                onChanged: (v) {
                  setState(() {
                    if (v.trim().isEmpty) {
                      return;
                    }
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
                        const EdgeInsets.symmetric(vertical: 5, horizontal: 8),
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
          if (allCryptos.value.isEmpty)
            Expanded(
                child: Center(
              child: CircularProgressIndicator(
                color: colors.themeColor,
              ),
            ))
          else
            Expanded(
                child: GlowingOverscrollIndicator(
              axisDirection: AxisDirection.down,
              color: colors.themeColor,
              child: ListView.builder(
                  itemCount: getCryptoList().length,
                  itemBuilder: (ctx, i) {
                    final reorganized = getCryptoList()
                      ..sort((a, b) => cryptoManager
                          .cleanName(a.symbol.trim())
                          .compareTo(cryptoManager.cleanName(b.symbol.trim())));

                    final crypto = reorganized[i];

                    return Material(
                      color: Colors.transparent,
                      child: CustomSwitchListTitle(
                        fontSizeOf: fontSizeOf,
                        colors: colors,
                        onTap: () {
                          showTokenDetails(
                              context: context, colors: colors, crypto: crypto);
                        },
                        leading: CryptoPicture(
                            crypto: crypto,
                            size: imageSizeOf(40),
                            colors: colors),
                        title: crypto.symbol,
                        value: cryptoManager.isEnabled(
                            crypto, savedCryptoAsync.value ?? []),
                        onChanged: (newVal) async {
                          try {
                            final result = await savedCryptoProvider
                                .toggleCanDisplay(crypto, newVal);

                            if (result) {
                              log("State changed successfully");
                            } else {
                              log("Error changing state");
                            }
                          } catch (e) {
                            logError(e.toString());
                            notifyError(e.toString(), context);
                          }
                        },
                      ),
                    );
                  }),
            ))
        ],
      ),
    );
  }
}
