import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moonwallet/logger/logger.dart';
import 'package:moonwallet/notifiers/providers.dart';
import 'package:moonwallet/service/external_data/crypto_request_manager.dart';
import 'package:moonwallet/types/types.dart';
import 'package:moonwallet/utils/constant.dart';

class SavedCryptoProvider extends AsyncNotifier<List<Crypto>> {
  late final cryptoStorage = ref.read(cryptoStorageProvider);

  @override
  Future<List<Crypto>> build() => getSavedCrypto();

  Future<List<Crypto>> getSavedCrypto() async {
    try {
      final account = await ref.watch(currentAccountProvider.future);

      if (account == null) {
        logError("No active account");
        return [];
      }
      List<Crypto> listCrypto = [];

      List<Crypto> cryptos = [];
      try {
        cryptos = await cryptoStorage.getSavedCryptos(wallet: account) ?? [];
      } catch (e) {
        logError(e.toString());
      }

      if (cryptos.isNotEmpty) {
        return cryptos;
      }

      List<Crypto> standardCrypto = [];

      try {
        standardCrypto = await CryptoRequestManager().getAllCryptos();
        log("All Crypto ${standardCrypto.map((c) => c.toJson()).toList()}");
      } catch (e) {
        logError(e.toString());
      }

      if (standardCrypto.isNotEmpty) {
        listCrypto = standardCrypto;
      } else {
        listCrypto = popularCrypto;
      }

      if (listCrypto.isNotEmpty) {
        await saveListCrypto(listCrypto, account);
        return listCrypto;
      }

      return [];
    } catch (e) {
      logError(e.toString());
      return [];
    }
  }

  Future<bool> saveListCrypto(List<Crypto> cryptos, PublicData account) async {
    try {
      final result =
          await cryptoStorage.saveListCrypto(cryptos: cryptos, wallet: account);
      return result;
    } catch (e) {
      logError(e.toString());
      return false;
    }
  }

  Future<bool> addCrypto(Crypto newCrypto) async {
    try {
      final currentAccount = ref.watch(currentAccountProvider).value;

      final List<Crypto>? cryptos = state.value;
      if (currentAccount == null) {
        throw "No account found";
      }

      if (cryptos != null) {
        for (final crypto in cryptos) {
          if (crypto.contractAddress != null &&
              crypto.contractAddress?.trim().toLowerCase() ==
                  newCrypto.contractAddress?.trim().toLowerCase()) {
            throw ('Token already added.');
          }
        }
      }
      final saveResult = await cryptoStorage.addCrypto(
          wallet: currentAccount, crypto: newCrypto);

      if (saveResult) {
        state = AsyncLoading();
        state = AsyncData(await getSavedCrypto());
        ref.invalidate(assetsNotifierProvider);

        return true;
      }
      return false;
    } catch (e) {
      logError(e.toString());
      rethrow;
    }
  }

  Future<bool> editNetwork(
      {required int chainId,
      String? name,
      String? symbol,
      List<String>? rpcUrls,
      List<String>? explorers,
      required PublicData currentAccount}) async {
    try {
      final result = await cryptoStorage.editNetwork(
          chainId: chainId,
          name: name,
          symbol: symbol,
          rpcUrls: rpcUrls,
          explorers: explorers,
          wallet: currentAccount);

      if (result) {
        state = AsyncLoading();
        state = AsyncData(await getSavedCrypto());
        ref.invalidate(assetsNotifierProvider);

        return true;
      }
      return false;
    } catch (e) {
      logError(e.toString());
      rethrow;
    }
  }

  Future<bool> toggleCanDisplay(Crypto crypto, bool value) async {
    try {
      final account = await ref.watch(currentAccountProvider.future);
      if (account == null) {
        logError("No account found");
        return false;
      }
      final result = await cryptoStorage.toggleCanDisplay(
          wallet: account, crypto: crypto, value: value);
      if (result) {
        state = AsyncData(await getSavedCrypto());
        ref.invalidate(assetsNotifierProvider);

        return true;
      }

      return false;
    } catch (e) {
      logError(e.toString());
      return false;
    }
  }
}
