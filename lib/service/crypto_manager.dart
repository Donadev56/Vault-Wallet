import 'package:moonwallet/logger/logger.dart';
import 'package:moonwallet/service/db/crypto_storage_manager.dart';
import 'package:moonwallet/service/external_data/crypto_request_manager.dart';
import 'package:moonwallet/types/account_related_types.dart';

class CryptoManager {
  final requestManager = CryptoRequestManager();
  final storage = CryptoStorageManager();

  List<Crypto> removeDuplicate(List<Crypto> cryptoList) {
    final networks = cryptoList.where((e) => e.isNative).toList();
    final tokens = cryptoList.where((e) => !e.isNative).toList();

    List<Crypto> finalList = [];

    Set<int> chainIds = Set.from(
        networks.map((e) => e.chainId ?? 0).where((e) => e != 0).toList());

    Set<String> contractAddresses = Set.from(tokens
        .map((e) => e.contractAddress ?? "")
        .where((e) => e.isNotEmpty)
        .toList());

    final organizedNetworks = chainIds
        .toList()
        .map((chain) {
          final targetNetwork = networks
              .where((e) => e.chainId != null && e.chainId == chain)
              .firstOrNull;
          return targetNetwork;
        })
        .where((e) => e != null)
        .toList();

    List<Crypto> organizedTokens = [];

    for (var address in contractAddresses) {
      final listTargetTokens = tokens
          .where((e) =>
              e.contractAddress != null &&
              e.contractAddress?.trim().toLowerCase() ==
                  address.trim().toLowerCase())
          .toList();

      Set<int> listTargetTokensChainIds = Set.from(listTargetTokens
          .map((e) => e.network?.chainId ?? 0)
          .where((e) => e != 0));

      final foundedTokens = listTargetTokensChainIds
          .toList()
          .map((id) {
            final targetFoundedToken = listTargetTokens
                .where((e) => e.network?.chainId == id)
                .firstOrNull;

            return targetFoundedToken;
          })
          .where((e) => e != null)
          .toList();

      List<Crypto> finalFoundedTokens = [];
      for (var t in foundedTokens) {
        if (t != null) {
          finalFoundedTokens.add(t);
        }
      }
      organizedTokens.addAll(finalFoundedTokens);
    }

    List<Crypto> finalOrganizedNetworks = [];
    for (var net in organizedNetworks) {
      if (net != null) {
        finalOrganizedNetworks.add(net);
      }
    }

    finalList = [...finalOrganizedNetworks, ...organizedTokens];
    finalList.sort((a, b) => b.symbol.compareTo(a.symbol));
    return finalList;
  }

  List<Crypto> addOnlyNewTokens(
      {required List<Crypto> localList, required List<Crypto> externalList}) {
    List<Crypto> initialList = removeDuplicate(localList);
    List<Crypto> initialExternalList = removeDuplicate(externalList);

    final existingTokenList = initialList.where((e) => !e.isNative).toList();
    final existingNetworksList = initialList.where((e) => e.isNative).toList();
    final externalNetworks =
        initialExternalList.where((e) => e.isNative).toList();
    final externalTokenList =
        initialExternalList.where((e) => !e.isNative).toList();
    log("Initial tokens names ${existingTokenList.map((e) => e.name).toList()}");

    Set<int> existingChainIds = Set.from(existingNetworksList
        .map((e) => e.chainId ?? 0)
        .where((e) => e != 0)
        .toList());

    for (final net in externalNetworks) {
      if (!existingChainIds.contains(net.chainId)) {
        initialList.add(net);
      }
    }

    Set<String> existingTokenIdentifiers = Set.from(existingTokenList.map((e) =>
        '${e.contractAddress?.trim().toLowerCase()}-${e.network?.chainId ?? 0}'));

    for (final externalToken in externalTokenList) {
      String tokenIdentifier =
          '${externalToken.contractAddress?.trim().toLowerCase()}-${externalToken.network?.chainId ?? 0}';
      if (!existingTokenIdentifiers.contains(tokenIdentifier)) {
        initialList.add(externalToken);
        existingTokenIdentifiers.add(tokenIdentifier);
      }
    }

    return initialList;
  }

  List<Crypto> removeAlreadySavedTokens(
      List<Crypto> savedCrypto, List<Crypto> newCryptos) {
    try {
      List<Crypto> finalTokens = [];
      final savedTokens = savedCrypto.onlyTokens;
      final newTokens = newCryptos.onlyTokens;

      Set<String> savedTokensSet = savedTokens
          .map((e) => "${e.contractAddress}-${e.getChainId}")
          .toSet();

      finalTokens = newTokens
          .where((token) => !savedTokensSet
              .contains("${token.contractAddress}-${token.getChainId}"))
          .toList();
      return removeDuplicate(finalTokens);
    } catch (e) {
      logError(e.toString());
      return [];
    }
  }

  Future<List<Crypto>> getDefaultTokens() async {
    try {
      final defaultTokens = await requestManager.getDefaultTokens();
      return defaultTokens ?? await requestManager.getSavedDefaultCrypto();
    } catch (e) {
      logError(e.toString());
      return [];
    }
  }

  Future<List<Crypto>> getAllTokens() async {
    try {
      return await requestManager.getAllCryptos();
    } catch (e) {
      logError(e.toString());
      return [];
    }
  }

  List<Crypto> compatibleCryptos(
      PublicAccount account, List<Crypto> listCrypto) {
    if (account.origin.isMnemonic) {
      return listCrypto;
    }

    if (account.origin.isPrivateKey || account.origin.isPublicAddress) {
      return listCrypto
          .where(
              (e) => e.getNetworkType == account.supportedNetworks.firstOrNull)
          .toList();
    }
    return [];
  }

  Future<List<Crypto>> getTokenPerPage(int index) async {
    try {
      return await requestManager.getTokensPerPage(index);
    } catch (e) {
      logError(e.toString());
      return [];
    }
  }

  Future<List<Crypto>> searchTokens(String query) async {
    try {
      return await requestManager.searchTokens(query);
    } catch (e) {
      logError(e.toString());
      return [];
    }
  }
}
