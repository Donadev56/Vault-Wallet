import 'package:decimal/decimal.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moonwallet/logger/logger.dart';
import 'package:moonwallet/notifiers/providers.dart';
import 'package:moonwallet/service/external_data/price_manager.dart';
import 'package:moonwallet/service/rpc_service.dart';
import 'package:moonwallet/types/account_related_types.dart';
import 'package:moonwallet/types/notifications_types.dart';

class AssetsNotifier extends AsyncNotifier<List<Asset>> {
  late final cryptoStorage = ref.read(cryptoStorageProvider);
  late final internetChecker = ref.read(internetConnectionProvider);
  late final assetState = ref.watch(assetsLoadStateProvider.notifier);

  @override
  Future<List<Asset>> build() async {
    try {
      PublicAccount? account = await getAccount();
      if (account == null) {
        logError("The account is null");
        return [];
      }
      updateState(AssetNotificationState.loading);
      final userAssets = await getUserAssets(account: account);
      updateState(AssetNotificationState.completed);
      return userAssets;
    } catch (e) {
      logError(e.toString());
      updateState(AssetNotificationState.error);
      return [];
    }
  }

  void updateState(AssetNotificationState newState) {
    assetState.updateState(newState);
  }

  Future<PublicAccount?> getAccount() async {
    try {
      PublicAccount? account;
      final savedAccount = await ref.watch(currentAccountProvider.future);
      if (savedAccount != null) {
        return savedAccount;
      }

      final accounts =
          await ref.read(accountsNotifierProvider.notifier).getPublicAccount();
      if (accounts.isNotEmpty) {
        account = accounts[0];
        log("Account found ${account.keyId}");
        await ref
            .read(accountsNotifierProvider.notifier)
            .saveLastConnectedAccount(account.keyId);
        return account;
      } else {
        logError("The account list is empty");
        return null;
      }
    } catch (e) {
      logError(e.toString());
      return null;
    }
  }

  Future<void> rebuild(PublicAccount account) async {
    try {
      state = AsyncData((await getUserAssets(account: account)));
      ref.invalidate(savedCryptosProviderNotifier);
    } catch (e) {
      logError(e.toString());
    }
  }

  Future<bool> saveListAssets(List<Asset> assets, PublicAccount account) async {
    try {
      final result =
          await cryptoStorage.saveListAssets(assets: assets, account: account);

      ref.invalidate(getSavedAssetsProvider);
      return result;
    } catch (e) {
      logError(e.toString());
      return false;
    }
  }

  Future<Asset> getAssetData(
      Crypto crypto, PublicAccount account, int waitTime) async {
    try {
      await Future.delayed(Duration(microseconds: waitTime));
      final priceManager = PriceManager();
      final cryptoBalance = await RpcService().getBalance(
        crypto,
        account,
      );
      final balance = cryptoBalance;
      final priceDataResult = await priceManager.getPriceDataV2(crypto);
      final trend = priceDataResult.$2;
      final cryptoPrice = priceDataResult.$1;
      final balanceUsd =
          Decimal.parse(balance) * Decimal.parse(cryptoPrice.toString());

      return Asset(
        crypto: crypto,
        balanceUsd: balanceUsd.toString(),
        balanceCrypto: balance,
        cryptoTrendPercent: trend.toString(),
        cryptoPrice: cryptoPrice,
      );
    } catch (e) {
      logError(e.toString());
      rethrow;
    }
  }

  Future<List<Asset>> getUserAssets({required PublicAccount account}) async {
    try {
      updateState(AssetNotificationState.loading);

      final savedCrypto = await ref.read(savedCryptosProviderNotifier.future);
      List<Crypto> enabledCryptos = [];
      List<Asset> assets = [];

      if (savedCrypto.isNotEmpty) {
        enabledCryptos =
            savedCrypto.where((c) => c.canDisplay == true).toList();

        final assetsFuture =
            await Future.wait(List.generate(enabledCryptos.length, (i) {
          final element = enabledCryptos[i];
          return getAssetData(element, account, i * 100);
        }));

        assets.addAll(assetsFuture);
        assets.sort((a, b) =>
            (double.parse(b.balanceUsd)).compareTo(double.parse(a.balanceUsd)));

        final userAssets = assets;
        await saveListAssets(assets, account);
        // await saveListAssetsResponse(userAssets, account);
        updateState(AssetNotificationState.completed);

        return userAssets;
      }

      throw ("No crypto found");
    } catch (e) {
      logError(e.toString());
      updateState(AssetNotificationState.error);

      return [];
    }
  }
}
