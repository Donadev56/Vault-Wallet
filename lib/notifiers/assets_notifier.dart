import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';
import 'package:moonwallet/logger/logger.dart';
import 'package:moonwallet/notifiers/providers.dart';
import 'package:moonwallet/service/crypto_request_manager.dart';
import 'package:moonwallet/types/types.dart';
import 'package:moonwallet/utils/constant.dart';
import 'package:riverpod/riverpod.dart';

class AssetsNotifier extends AsyncNotifier<UserAssetsResponse?> {
  late final cryptoStorage = ref.read(cryptoStorageProvider);
  late final web3InteractionManager = ref.read(web3InteractionProvider);
  late final priceManager = ref.read(priceProvider);
  late final internetChecker = ref.read(internetConnectionProvider);
  @override
  Future<UserAssetsResponse?> build() async {
    try {
      final account = ref.watch(currentAccountProvider).value;

      if (account == null) {
        log("No current account selected");

        return null;
      }
      final userAssets = await getUserAssets(account: account);
      return userAssets;
    } catch (e) {
      logError(e.toString());
      return null;
    }
  }

  Future<bool> saveListCrypto(List<Crypto> cryptos, PublicData account) async {
    try {
      final result =
          await cryptoStorage.saveListCrypto(cryptos: cryptos, wallet: account);
      ref.invalidate(getSavedCryptosProvider);
      return result;
    } catch (e) {
      logError(e.toString());
      return false;
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

  Future<bool> saveListAssetsResponse(
      UserAssetsResponse assetsResponse, PublicData account) async {
    try {
      final result = await cryptoStorage.saveAssetsResponse(
          assetsResponse: assetsResponse, account: account);
      ref.invalidate(getSavedAssetsResponseProvider);
      return result;
    } catch (e) {
      logError(e.toString());
      return false;
    }
  }

  Future<UserAssetsResponse?> getUserAssets(
      {required PublicData account}) async {
    try {
      final savedDataResult = await ref.read(getSavedCryptosProvider.future);

      List<Crypto> standardCrypto = [];
      try {
        standardCrypto = await CryptoRequestManager().getAllCryptos();
      } catch (e) {
        logError(e.toString());
      }
      if (standardCrypto.isEmpty) {
        standardCrypto.addAll(popularCrypto);
      }

      final savedCrypto = (savedDataResult);

      List<Crypto> cryptosList = [];
      List<Crypto> enabledCryptos = [];
      List<Asset> cryptoBalance = [];
      List<Crypto> availableCryptos = [];
      double userBalanceUsd = 0;

      if (savedCrypto == null || savedCrypto.isEmpty) {
        cryptosList = standardCrypto;
      } else {
        cryptosList = savedCrypto;
      }

      if (cryptosList.isNotEmpty) {
        enabledCryptos =
            cryptosList.where((c) => c.canDisplay == true).toList();
        userBalanceUsd = 0;
        availableCryptos = [];
        List<Map<String, Object>> results = [];

        results = await Future.wait(enabledCryptos.map((crypto) async {
          final balance =
              await web3InteractionManager.getBalance(account, crypto);
          final trend = await priceManager
              .checkCryptoTrend(crypto.binanceSymbol ?? "${crypto.symbol}USDT");
          final cryptoPrice = await priceManager.getPriceUsingBinanceApi(
              crypto.binanceSymbol ?? "${crypto.symbol}USDT");
          final balanceUsd = cryptoPrice * balance;

          return {
            "cryptoBalance": Asset(
              crypto: crypto,
              balanceUsd: balanceUsd,
              balanceCrypto: balance,
              cryptoTrendPercent: trend["percent"] ?? 0,
              cryptoPrice: cryptoPrice,
            ),
            "availableCrypto": crypto,
            "balanceUsd": balanceUsd
          };
        }));

        cryptoBalance.addAll(results.map((r) => r["cryptoBalance"] as Asset));

        availableCryptos
            .addAll(results.map((r) => r["availableCrypto"] as Crypto));
        userBalanceUsd +=
            results.fold(0.0, (sum, r) => sum + (r["balanceUsd"] as double));

        if ((await internetChecker.internetStatus
            .then((st) => st == InternetStatus.disconnected))) {
          throw ("Not connected to the internet");
        }

        cryptoBalance.sort((a, b) => (b.balanceUsd).compareTo(a.balanceUsd));

        final userAssets = UserAssetsResponse(
            assets: cryptoBalance,
            totalBalanceUsd: userBalanceUsd,
            availableCryptos: availableCryptos,
            cryptosList: cryptosList);
        await saveListAssets(cryptoBalance, account);
        await saveListAssetsResponse(userAssets, account);
        return userAssets;
      }

      throw ("No crypto found");
    } catch (e) {
      logError(e.toString());
      return null;
    }
  }

  Future<void> checkCryptoUpdate({required PublicData account}) async {
    try {
      final List<Crypto> standardCrypto =
          await CryptoRequestManager().getAllCryptos();
      final savedCrypto = await cryptoStorage.getSavedCryptos(wallet: account);
      List<Crypto> cryptosList = [];
      if (savedCrypto != null && savedCrypto.isNotEmpty) {
        cryptosList = savedCrypto;

        Set<String> savedCryptoIds =
            savedCrypto.map((crypto) => crypto.cryptoId).toSet();

        for (final stCrypto in standardCrypto) {
          if (!savedCryptoIds.contains(stCrypto.cryptoId)) {
            cryptosList.add(stCrypto);
          }
        }

        if (cryptosList.length > savedCrypto.length) {
          log("${cryptosList.length - savedCrypto.length} new Crypto(s) found");
          await cryptoStorage.saveListCrypto(
              wallet: account, cryptos: cryptosList);
        } else {
          log("No new Crypto founded");
        }
      }
    } catch (e) {
      logError(e.toString());
    }
  }
}
