import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moonwallet/logger/logger.dart';
import 'package:moonwallet/notifiers/providers.dart';
import 'package:moonwallet/service/crypto_manager.dart';
import 'package:moonwallet/service/db/wallet_db_stateless.dart';
import 'package:moonwallet/service/external_data/crypto_request_manager.dart';
import 'package:moonwallet/service/rpc_service.dart';
import 'package:moonwallet/types/account_related_types.dart';
import 'package:moonwallet/types/exception.dart';
import 'package:moonwallet/types/types.dart';
import 'package:moonwallet/widgets/func/security/ask_derivate_key.dart';

class SavedCryptoProvider extends AsyncNotifier<List<Crypto>> {
  late final cryptoStorage = ref.read(cryptoStorageProvider);
  final walletStorage = WalletDbStateLess();
  final rpcService = RpcService();
  final manager = CryptoManager();

  @override
  Future<List<Crypto>> build() => getSavedCrypto();

  Future<List<Crypto>> getSavedCrypto() async {
    try {
      final account = await ref.watch(currentAccountProvider.future);

      if (account == null) {
        logError("No active account");
        return [];
      }

      List<Crypto> savedCryptos = [];
      List<Crypto> standardCrypto = [];

      try {
        savedCryptos =
            await cryptoStorage.getSavedCryptos(wallet: account) ?? [];
      } catch (e) {
        logError(e.toString());
      }

      if (savedCryptos.isNotEmpty) {
        return manager.compatibleCryptos(account, savedCryptos);
      }

      try {
        final defaultTokens = await CryptoRequestManager().getDefaultTokens();

        if (defaultTokens != null) {
          standardCrypto = defaultTokens
              .sublist(0, defaultTokens.length > 5 ? 5 : defaultTokens.length)
              .map((e) => e.copyWith(canDisplay: true))
              .toList();
        }
      } catch (e) {
        logError(e.toString());
      }

      if (standardCrypto.isNotEmpty) {
        await saveListCrypto(standardCrypto, account);
        return manager.compatibleCryptos(account, standardCrypto);
      }
      return [];
    } catch (e) {
      logError(e.toString());
      return [];
    }
  }

  Future<List<Crypto>> getDefaultTokens() async {
    try {
      return CryptoManager().getDefaultTokens();
    } catch (e) {
      logError(e.toString());
      return [];
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
