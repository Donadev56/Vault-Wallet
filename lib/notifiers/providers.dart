import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';
import 'package:moonwallet/logger/logger.dart';
import 'package:moonwallet/notifiers/accounts_notifier.dart';
import 'package:moonwallet/notifiers/assets_notifier.dart';
import 'package:moonwallet/notifiers/colors_notifier.dart';
import 'package:moonwallet/notifiers/last_account_notifier.dart';
import 'package:moonwallet/notifiers/saved_crypto.dart';
import 'package:moonwallet/service/crypto_storage_manager.dart';
import 'package:moonwallet/service/price_manager.dart';
import 'package:moonwallet/service/wallet_saver.dart';
import 'package:moonwallet/service/web3_interaction.dart';
import 'package:moonwallet/types/types.dart';
import 'package:moonwallet/utils/colors.dart';
import 'package:moonwallet/utils/crypto.dart';
import 'package:moonwallet/utils/prefs.dart';

final connectivityStatusProvider = StreamProvider<InternetStatus>((ref) {
  return InternetConnection().onStatusChange;
});
final internetConnectionProvider =
    Provider<InternetConnection>((ref) => InternetConnection());

final accountsNotifierProvider =
    AsyncNotifierProvider<AccountsNotifier, List<PublicData>>(
        AccountsNotifier.new);

final assetsNotifierProvider =
    AsyncNotifierProvider<AssetsNotifier, List<Asset>>(AssetsNotifier.new);

final colorsNotifierProvider =
    AsyncNotifierProvider<ColorsNotifier, AppColors?>(ColorsNotifier.new);

final colorsManagerProvider = Provider((ref) => ColorsManager());

final walletSaverProvider = Provider((ref) => WalletSaver());
final encryptServiceProvider = Provider((ref) => EncryptService());
final web3InteractionProvider = Provider((ref) => Web3InteractionManager());
final priceProvider = Provider((ref) => PriceManager());

final publicDataProvider = Provider((ref) => (PublicDataManager()));
final cryptoStorageProvider = Provider((ref) => (CryptoStorageManager()));

final savedCryptosProviderNotifier =
    AsyncNotifierProvider<SavedCryptoProvider, List<Crypto>>(
        SavedCryptoProvider.new);

final getSavedAssetsProvider = FutureProvider<List<Asset>?>((ref) async {
  final cryptoStorage = ref.watch(cryptoStorageProvider);
  final account = await ref.watch(currentAccountProvider.future);
  if (account != null) {
    log("Getting saved assets");
    return await cryptoStorage.getSavedAssets(wallet: account);
  }
  return null;
});

final allAccountsProvider = FutureProvider<List<PublicData>>((ref) async {
  return await ref.watch(accountsNotifierProvider.future);
});

final currentAccountProvider = FutureProvider<PublicData?>((ref) async {
  final accounts = await ref.watch(accountsNotifierProvider.future);
  final lastKeyId = ref.watch(lastConnectedKeyIdNotifierProvider);
  if (accounts.isEmpty) {
    throw ("No account found");
  }

  return lastKeyId.when(data: (data) {
    if (data != null) {
      final accountFounded = accounts.firstWhere(
        (acc) => acc.keyId.toLowerCase().trim() == data.toLowerCase().trim(),
        orElse: () => accounts.first,
      );
      log("Last account id: $data");

      log("Account founded: ${accountFounded.toJson()}");
      return accountFounded;
    }
    return accounts.firstOrNull;
  }, error: (err, stack) {
    logError(err.toString());
    return accounts.firstOrNull;
  }, loading: () {
    log("Loading..");
    throw const AsyncLoading();
  });
});

final lastConnectedKeyIdNotifierProvider =
    AsyncNotifierProvider<LastConnectedKeyIdNotifier, String?>(
        LastConnectedKeyIdNotifier.new);
