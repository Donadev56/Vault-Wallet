// ignore_for_file: deprecated_member_use, use_build_context_synchronously

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moonwallet/main.dart';
import 'package:moonwallet/notifiers/providers.dart';
import 'package:moonwallet/service/wallet_saver.dart';
import 'package:moonwallet/utils/colors.dart';
import 'package:moonwallet/utils/crypto.dart';
import 'package:moonwallet/utils/themes.dart';
import 'package:moonwallet/widgets/crypto_picture.dart';
import 'package:moonwallet/widgets/func/show_add_token.dart';
import 'package:moonwallet/widgets/func/snackbar.dart';
import 'package:ulid/ulid.dart';

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:moonwallet/logger/logger.dart';
import 'package:moonwallet/service/crypto_storage_manager.dart';
import 'package:moonwallet/service/token_manager.dart';
import 'package:moonwallet/types/types.dart';
import 'package:moonwallet/utils/prefs.dart';

class AddCryptoView extends ConsumerStatefulWidget {
  final AppColors? colors;
  const AddCryptoView({super.key, this.colors});

  @override
  ConsumerState<AddCryptoView> createState() => _AddCryptoViewState();
}

class _AddCryptoViewState extends ConsumerState<AddCryptoView> {
  bool isDarkMode = true;
  Crypto? selectedNetwork;
  List<Crypto> reorganizedCrypto = [];
  SearchingContractInfo? searchingContractInfo;
  final cryptoStorageManager = CryptoStorageManager();
  final tokenManager = TokenManager();
  List<PublicData> accounts = [];
  final web3Manager = WalletSaver();
  final encryptService = EncryptService();

  bool hasSaved = false;
  PublicData? currentAccount;
  final nullAccount = PublicData(
      keyId: "",
      creationDate: 0,
      walletName: "",
      address: "",
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

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final width = MediaQuery.of(context).size.width;
    final currentAccountAsync = ref.watch(currentAccountProvider);
    final savedCryptoAsync = ref.watch(savedCryptosProviderNotifier);
    final savedCryptoProvider =
        ref.watch(savedCryptosProviderNotifier.notifier);
    final accountsProvider = ref.watch(accountsNotifierProvider);

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
                borderRadius: BorderRadius.circular(5)),
            child: IconButton(
              onPressed: () {
                showAddToken(
                    context: context,
                    colors: colors,
                    width: width,
                    hasSaved: hasSaved);
              },
              icon: Icon(
                LucideIcons.plus,
                color: colors.textColor,
                size: 20,
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
              ?.copyWith(color: colors.textColor, fontSize: 20),
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
                        borderRadius: BorderRadius.circular(10),
                        borderSide:
                            BorderSide(width: 0, color: Colors.transparent)),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
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
                          crypto: crypto, size: 40, colors: colors),
                      title: Text(
                        crypto.symbol,
                        style: textTheme.bodyMedium?.copyWith(
                            color: colors.textColor,
                            fontSize: 16,
                            fontWeight: FontWeight.bold),
                      ),
                      trailing: Switch(
                          value: crypto.canDisplay,
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
