import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';
import 'package:moonwallet/logger/logger.dart';
import 'package:moonwallet/notifiers/providers.dart';
import 'package:moonwallet/service/crypto_request_manager.dart';
import 'package:moonwallet/types/types.dart';
import 'package:riverpod/riverpod.dart';

class AssetsNotifier extends AsyncNotifier<List<Asset>> {
  late final cryptoStorage = ref.read(cryptoStorageProvider);
  late final web3InteractionManager = ref.read(web3InteractionProvider);
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
      final savedAccount = await ref.read(currentAccountProvider.future);
      if (savedAccount != null) {
        return savedAccount;
      }

      final accounts =
          await ref.read(accountsNotifierProvider.notifier).getPublicData();
      if (accounts.isNotEmpty) {
        account = accounts[0];
        log("Account found ${account.address}");
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

  Future<List<Asset>> getUserAssets({required PublicData account}) async {
    try {
      log("Updating assets");
      final savedCrypto = await ref.watch(savedCryptosProviderNotifier.future)
          ;

      List<Crypto> enabledCryptos = [];
      List<Asset> cryptoBalance = [];

      if (savedCrypto.isNotEmpty) {
        enabledCryptos =
            savedCrypto.where((c) => c.canDisplay == true).toList();

        List<Map<String, Object>> results = [];

        results = await Future.wait(enabledCryptos.map((crypto) async {
          final response = await Future.wait([
            web3InteractionManager.getBalance(account, crypto),
            priceManager.checkCryptoTrend(
                crypto.binanceSymbol ?? "${crypto.symbol}USDT"),
            priceManager.getPriceUsingBinanceApi(
                crypto.binanceSymbol ?? "${crypto.symbol}USDT")
          ]);
          final balance = response[0] as double;

          final trend = response[1] as dynamic;

          final cryptoPrice = response[2] as double;

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

        if ((await internetChecker.internetStatus
            .then((st) => st == InternetStatus.disconnected))) {
          throw ("Not connected to the internet");
        }

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
