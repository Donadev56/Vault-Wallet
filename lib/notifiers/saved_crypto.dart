import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moonwallet/logger/logger.dart';
import 'package:moonwallet/notifiers/providers.dart';
import 'package:moonwallet/service/db/wallet_db_stateless.dart';
import 'package:moonwallet/service/external_data/crypto_request_manager.dart';
import 'package:moonwallet/service/rpc_service.dart';
import 'package:moonwallet/types/account_related_types.dart';
import 'package:moonwallet/types/types.dart';
import 'package:moonwallet/widgets/func/security/ask_derivate_key.dart';

class SavedCryptoProvider extends AsyncNotifier<List<Crypto>> {
  late final cryptoStorage = ref.read(cryptoStorageProvider);
  final walletStorage = WalletDbStateLess();
  final rpcService = RpcService();

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

      List<Crypto> savedCryptos = [];
      try {
        savedCryptos =
            await cryptoStorage.getSavedCryptos(wallet: account) ?? [];
      } catch (e) {
        logError(e.toString());
      }

      if (savedCryptos.isNotEmpty) {
        return compatibleCryptos(account, savedCryptos);
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
      }

      if (listCrypto.isNotEmpty) {
        await saveListCrypto(listCrypto, account);
        return compatibleCryptos(account, listCrypto);
      }
      checkCryptoUpdate(account: account);
      return [];
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

  Future<void> checkCryptoUpdate({required PublicAccount account}) async {
    try {
      final List<Crypto> standardCrypto =
          await CryptoRequestManager().getAllCryptos();
      if (standardCrypto.isEmpty) {
        return;
      }
      final savedCryptos = await cryptoStorage.getSavedCryptos(wallet: account);
      List<Crypto> newCryptos = [];
      List<Crypto> cryptoToSave = savedCryptos ?? [];

      if (savedCryptos != null && savedCryptos.isNotEmpty) {
        // Prepare quick lookup sets for faster comparison
        final nativeChainIds = <int>{};
        final contractAddresses = <String>{};

        for (final crypto in savedCryptos) {
          if (crypto.isNative && crypto.chainId != null) {
            nativeChainIds.add(crypto.chainId!);
          } else if (crypto.contractAddress != null) {
            contractAddresses.add(crypto.contractAddress!.trim().toLowerCase());
          }
        }

        for (final crypto in standardCrypto) {
          if (crypto.isNative) {
            if (crypto.chainId != null &&
                !nativeChainIds.contains(crypto.chainId)) {
              newCryptos.add(crypto);
            }
          } else {
            final address = crypto.contractAddress?.trim().toLowerCase();
            if (address != null && !contractAddresses.contains(address)) {
              newCryptos.add(crypto);
            }
          }
        }
      }

      if (newCryptos.isNotEmpty) {
        log("Found ${newCryptos.length} new Crypto");
        cryptoToSave.addAll(newCryptos);
        await saveListCrypto(cryptoToSave, account);
      }
    } catch (e) {
      logError(e.toString());
    }
  }

  Future<bool> saveListCrypto(
      List<Crypto> cryptos, PublicAccount account) async {
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
      required PublicAccount currentAccount}) async {
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

  Future<bool> toggleAndEnableSolana(
      Crypto crypto, bool value, BuildContext context, AppColors colors) async {
    try {
      final account = await ref.watch(currentAccountProvider.future);
      if (account == null) {
        logError("No account found");
        return false;
      }
      final derivateKey =
          await askDerivateKey(context: context, colors: colors);
      if (derivateKey == null) {
        throw InvalidPasswordException();
      }

      final privateAccount = await walletStorage.getPrivateAccountUsingKey(
          deriveKey: derivateKey, account: account);
      final mnemonic = privateAccount?.keyOrigin;

      if (mnemonic == null) {
        throw ("Incompatible account");
      }

      final address = await rpcService.generateSolanaAddress(mnemonic);
      final addresses = account.addresses;
      final newAddresses = [
        ...addresses,
        PublicAddress(address: address, type: NetworkType.svm)
      ];

      final result = await walletStorage.editWallet(
        account: account,
        addresses: newAddresses,
      );
      if (result != null) {
        ref.invalidate(accountsNotifierProvider);
        final toggleResult = await toggleCanDisplay(crypto, value);

        return toggleResult;
      }

      return false;
    } catch (e) {
      logError(e.toString());
      return false;
    }
  }
}
