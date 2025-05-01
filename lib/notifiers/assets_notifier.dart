import 'package:decimal/decimal.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moonwallet/logger/logger.dart';
import 'package:moonwallet/notifiers/providers.dart';
import 'package:moonwallet/service/rpc_service.dart';
import 'package:moonwallet/types/types.dart';

class AssetsNotifier extends AsyncNotifier<List<Asset>> {
  late final cryptoStorage = ref.read(cryptoStorageProvider);
  late final priceManager = ref.read(priceProvider);
  late final internetChecker = ref.read(internetConnectionProvider);

  @override
  Future<List<Asset>> build() async {
    try {
      PublicData? account = await getAccount();
      if (account == null) {
        logError("The account is null");
        return [];
      }
      final userAssets = await getUserAssets(account: account);
      return userAssets;
    } catch (e) {
      logError(e.toString());
      return [];
    }
  }

  Future<PublicData?> getAccount() async {
    try {
      PublicData? account;
      final savedAccount = await ref.watch(currentAccountProvider.future);
      if (savedAccount != null) {
        return savedAccount;
      }

      final accounts =
          await ref.read(accountsNotifierProvider.notifier).getPublicData();
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

  Future<void> rebuild(PublicData account) async {
    try {
      state = AsyncData((await getUserAssets(account: account)));
      ref.invalidate(savedCryptosProviderNotifier);
    } catch (e) {
      logError(e.toString());
    }
  }

  Future<bool> saveListAssets(List<Asset> assets, PublicData account) async {
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

  Future<Map<String, dynamic>> getAssetData(Crypto crypto, PublicData account,
      List<CryptoMarketData> listTokenData) async {
    try {
      final cryptoBalance = await RpcService().getBalance(
        crypto,
        account,
      );

      final tokenData = listTokenData
          .where((d) =>
              d.id.toLowerCase().trim() ==
              crypto.cgSymbol?.toLowerCase().trim())
          .firstOrNull;

      final balance = cryptoBalance;
      log("Balance $balance");

      final trend = tokenData?.priceChangePercentage24h ?? 0;

      final cryptoPrice = tokenData?.currentPrice ?? 0;

      final balanceUsd =
          Decimal.parse(balance) * Decimal.parse(cryptoPrice.toString());

      return {
        "cryptoBalance": Asset(
            crypto: crypto,
            balanceUsd: balanceUsd.toString(),
            balanceCrypto: balance,
            cryptoTrendPercent: trend,
            cryptoPrice: cryptoPrice,
            marketData: tokenData),
        "availableCrypto": crypto,
        "balanceUsd": balanceUsd,
        "marketData": tokenData
      };
    } catch (e) {
      logError(e.toString());
      return <String, dynamic>{};
    }
  }

  Future<List<Asset>> getUserAssets({required PublicData account}) async {
    try {
      log("Updating assets");
      final savedCrypto = await ref.read(savedCryptosProviderNotifier.future);
      log("Saved crypto ${savedCrypto.length}");

      List<Crypto> enabledCryptos = [];
      List<Asset> cryptoBalance = [];

      if (savedCrypto.isNotEmpty) {
        enabledCryptos =
            savedCrypto.where((c) => c.canDisplay == true).toList();

        List<Map<String, dynamic>> results = [];
        final listTokenData = await priceManager.getListTokensMarketData();
        results = await Future.wait(enabledCryptos.map((crypto) async {
          return await getAssetData(crypto, account, listTokenData);
        }));

        cryptoBalance.addAll(results.map((r) => r["cryptoBalance"] as Asset));

        cryptoBalance.sort((a, b) => (b.balanceUsd).compareTo(a.balanceUsd));

        final userAssets = cryptoBalance;
        await saveListAssets(cryptoBalance, account);
        // await saveListAssetsResponse(userAssets, account);
        return userAssets;
      }

      throw ("No crypto found");
    } catch (e) {
      logError(e.toString());
      return [];
    }
  }
}
