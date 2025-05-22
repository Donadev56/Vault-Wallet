import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:moonwallet/logger/logger.dart';
import 'package:moonwallet/notifiers/providers.dart';
import 'package:moonwallet/service/crypto_manager.dart';
import 'package:moonwallet/types/account_related_types.dart';
import 'package:moonwallet/types/types.dart';
import 'package:moonwallet/widgets/dialogs/search_modal_header.dart';
import 'package:moonwallet/widgets/dialogs/show_custom_snackbar.dart';
import 'package:moonwallet/widgets/dialogs/standard_circular_progress_indicator.dart';
import 'package:moonwallet/widgets/dialogs/standard_container.dart';
import 'package:moonwallet/widgets/func/tokens_config/show_token_detials.dart';
import 'package:moonwallet/widgets/screen_widgets/crypto_picture.dart';
import 'package:moonwallet/widgets/screen_widgets/custom_switch_list_title.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

void showAdditionalTokens({
  required BuildContext context,
  required AppColors colors,
  required DoubleFactor roundedOf,
  required DoubleFactor fontSizeOf,
  required DoubleFactor iconSizeOf,
}) async {
  showCupertinoModalBottomSheet<Crypto>(
      context: context,
      enableDrag: false,
      builder: (ctx) {
        return ShowAdditionalTokensView(
            colors: colors,
            roundedOf: roundedOf,
            fontSizeOf: fontSizeOf,
            iconSizeOf: iconSizeOf);
      });
}

class ShowAdditionalTokensView extends HookConsumerWidget {
  final AppColors colors;
  final DoubleFactor roundedOf;
  final DoubleFactor fontSizeOf;
  final DoubleFactor iconSizeOf;
  const ShowAdditionalTokensView({
    super.key,
    required this.colors,
    required this.roundedOf,
    required this.fontSizeOf,
    required this.iconSizeOf,
  });
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pageController = useMemoized(() => PageController());
    final manager = useMemoized(() => CryptoManager());
    final tokens = useState<List<Crypto>>([]);
    final requestedPageCount = useState<int>(0);
    final savedCryptoProvider = ref.watch(savedCryptosProviderNotifier);
    final savedCryptoNotifier =
        ref.watch(savedCryptosProviderNotifier.notifier);

    final isLoading = useState<bool>(false);
    final loadedAll = useState<bool>(false);
    final accountAsync = ref.watch(currentAccountProvider);
    final canIncreaseValue = useState<bool>(false);
    final searchingTokens = useState<List<Crypto>>([]);
    final queryValue = useState<String>("");
    final isSearching = useState<bool>(false);
    final pageIndex = useState<int>(0);

    final positionListener = useMemoized(() {
      return ItemPositionsListener.create();
    }, []);

    List<Crypto> filterTokens(List<Crypto> newTokens, PublicAccount account) {
      newTokens.sort((a, b) => a.symbol.compareTo(b.symbol));
      newTokens = newTokens
          .where((e) => e.symbol.trim().isNotEmpty && e.icon != null)
          .toList();
      return manager.compatibleCryptos(account, newTokens);
    }

    useEffect(() {
      Future<void> getTokens() async {
        try {
          final account = accountAsync.value;
          if (account == null) {
            throw Exception("Account not yet initialized");
          }
          int initialTokensCount = tokens.value.length;
          isLoading.value = true;
          final newTokens =
              await manager.getTokenPerPage(requestedPageCount.value + 1);

          final savedTokens = savedCryptoProvider.value;
          List<Crypto> withoutSaved = manager.removeAlreadySavedTokens(
              savedTokens ?? [], [...tokens.value, ...newTokens]);

          tokens.value = filterTokens(withoutSaved, account);
          if (tokens.value.length == initialTokensCount) {
            loadedAll.value = true;
          } else {
            loadedAll.value = false;
          }
        } catch (e) {
          logError(e.toString());
        } finally {
          isLoading.value = false;
          canIncreaseValue.value = true;
        }
      }

      getTokens();

      return null;
    }, [requestedPageCount.value]);

    useEffect(() {
      void listenPosition() async {
        final positions = positionListener.itemPositions.value;

        if (positions.isNotEmpty) {
          final maxIndex = positions
              .map((item) => item.index)
              .reduce((a, b) => a > b ? a : b);

          if (maxIndex == tokens.value.length) {
            if (isLoading.value) {
              return;
            }
            if (!canIncreaseValue.value) {
              log("Can't increase value\n targetValue ${requestedPageCount.value + 1}");
              return;
            }

            requestedPageCount.value = requestedPageCount.value + 1;
            canIncreaseValue.value = false;
          }
        }
      }

      positionListener.itemPositions.addListener(listenPosition);
      return () =>
          positionListener.itemPositions.removeListener(listenPosition);
    }, []);

    useEffect(() {
      Future<void> searchTokens() async {
        try {
          isSearching.value = true;
          final account = accountAsync.value;
          if (account == null) {
            throw Exception("Account not yet initialized");
          }
          final query = queryValue.value;
          if (query.trim().isEmpty) {
            pageController.previousPage(
                duration: Duration(milliseconds: 300), curve: Curves.easeInOut);

            return;
          }

          if (pageIndex.value == 0) {
            pageController.nextPage(
                duration: Duration(microseconds: 300), curve: Curves.easeInOut);
          }

          Future.delayed(Duration(seconds: 1));

          List<Crypto> newTokens = await manager.searchTokens(query);
          newTokens = newTokens.sublist(
              0, newTokens.length > 1000 ? 1000 : newTokens.length);

          final withoutSaved = manager.removeAlreadySavedTokens(
              savedCryptoProvider.value ?? [], newTokens);
          searchingTokens.value = filterTokens(withoutSaved, account);
        } catch (e) {
          logError(e.toString());
        } finally {
          isSearching.value = false;
        }
      }

      searchTokens();
      return null;
    }, [queryValue.value]);

/*
    List<Crypto> getTokens() {
      final query = queryValue.value;
      if (query.trim().isEmpty && searchingTokens.value.isEmpty) {
        return tokens.value;
      } else {
        return searchingTokens.value;
      }
    } */
    bool isEnabled(Crypto token) {
      return (savedCryptoProvider.value ?? []).any((c) =>
          c.contractAddress?.trim().toLowerCase() ==
              token.contractAddress?.trim().toLowerCase() &&
          c.network?.chainId == token.network?.chainId);
    }

    return Material(
        color: colors.primaryColor,
        child: StandardContainer(
          padding: const EdgeInsets.all(0),
          child: Column(
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
                child: SearchModalAppBar(
                  hint: "Search Tokens",
                  onChanged: (v) => queryValue.value = v,
                  colors: colors,
                  title: "Explore",
                  fontSizeOf: fontSizeOf,
                  iconSizeOf: iconSizeOf,
                  roundedOf: roundedOf,
                ),
              ),
              Expanded(
                  child: PageView.builder(
                      onPageChanged: (index) => pageIndex.value = index,
                      controller: pageController,
                      itemCount: 2,
                      itemBuilder: (context, pageIndex) {
                        final isFirstView = pageIndex == 0;
                        final listTokens =
                            isFirstView ? tokens.value : searchingTokens.value;

                        return GlowingOverscrollIndicator(
                            axisDirection: AxisDirection.down,
                            color: colors.themeColor,
                            child: ScrollablePositionedList.builder(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 10),
                              itemCount: listTokens.length + 1,
                              itemPositionsListener:
                                  !isFirstView ? null : positionListener,
                              itemBuilder: (context, index) {
                                if (index == listTokens.length) {
                                  if (!isFirstView) {
                                    return buildStaticLoader(
                                        loading: !isSearching.value,
                                        context: context,
                                        colors: colors,
                                        text: "Searching...");
                                  }
                                  return buildStaticLoader(
                                      loading: loadedAll.value,
                                      context: context,
                                      colors: colors);
                                }
                                final token = listTokens[index];

                                return Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 5,
                                  ),
                                  child: CustomSwitchListTitle(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 5, horizontal: 15),
                                    density: VisualDensity.compact,
                                    leading: CryptoPicture(
                                        crypto: token,
                                        size: 35,
                                        colors: colors),
                                    onTap: () => showTokenDetails(
                                        context: context,
                                        colors: colors,
                                        crypto: token),
                                    colors: colors,
                                    title: token.symbol,
                                    fontSizeOf: fontSizeOf,
                                    onChanged: (v) async {
                                      await savedCryptoNotifier
                                          .toggleCanDisplay(token, v)
                                          .then((v) {
                                        if (v) {
                                          // ignore: use_build_context_synchronously
                                          notifySuccess("Enabled", context);
                                        } else {
                                          // ignore: use_build_context_synchronously
                                          notifyError(
                                              "An error has occurred", context);
                                        }
                                      });
                                    },
                                    value: isEnabled(token),
                                    rounded: 10,
                                  ),
                                );
                              },
                            ));
                      }))
            ],
          ),
        ));
  }
}

Widget buildStaticLoader(
    {required bool loading,
    required BuildContext context,
    required AppColors colors,
    String text = "Loading..."}) {
  final textTheme = TextTheme.of(context);
  return Container(
    padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
    margin: const EdgeInsets.all(10),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          !loading ? text : "Completed",
          style: textTheme.bodyMedium
              ?.copyWith(color: colors.textColor, fontWeight: FontWeight.w400),
        ),
        !loading
            ? standardCircularProgressIndicator(colors: colors)
            : Icon(
                Icons.check,
                color: colors.textColor,
              )
      ],
    ),
  );
}
