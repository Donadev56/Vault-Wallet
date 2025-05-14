import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';
import 'package:moonwallet/logger/logger.dart';
import 'package:moonwallet/notifiers/accounts_notifier.dart';
import 'package:moonwallet/notifiers/app_secure_config_notifier.dart';
import 'package:moonwallet/notifiers/app_ui_config_notifier.dart';
import 'package:moonwallet/notifiers/assets_notifier.dart';
import 'package:moonwallet/notifiers/current_page_index_notifier.dart';
import 'package:moonwallet/notifiers/last_account_notifier.dart';
import 'package:moonwallet/notifiers/profile_image_notifier.dart';
import 'package:moonwallet/notifiers/saved_crypto.dart';
import 'package:moonwallet/notifiers/wallet_manager_notifier.dart';
import 'package:moonwallet/service/db/crypto_storage_manager.dart';
import 'package:moonwallet/service/external_data/price_manager.dart';
import 'package:moonwallet/service/db/wallet_db.dart';
import 'package:moonwallet/types/account_related_types.dart' as types;
import 'package:moonwallet/types/types.dart' as types;
import 'package:moonwallet/utils/colors.dart';
import 'package:moonwallet/utils/encrypt_service.dart';

final connectivityStatusProvider = StreamProvider<InternetStatus>((ref) {
  return InternetConnection().onStatusChange;
});
final internetConnectionProvider =
    Provider<InternetConnection>((ref) => InternetConnection());

final accountsNotifierProvider =
    AsyncNotifierProvider<AccountsNotifier, List<types.PublicAccount>>(
        AccountsNotifier.new);

final assetsNotifierProvider =
    AsyncNotifierProvider<AssetsNotifier, List<types.Asset>>(
        AssetsNotifier.new);

final profileImageProviderNotifier =
    AsyncNotifierProvider<ProfileImageNotifier, File?>(
        ProfileImageNotifier.new);

final colorsManagerProvider = Provider((ref) => ColorsManager());

final walletSaverProvider = Provider((ref) => WalletDatabase());
final encryptServiceProvider = Provider((ref) => EncryptService());
final priceProvider = Provider((ref) => PriceManager());

final cryptoStorageProvider = Provider((ref) => (CryptoStorageManager()));

final savedCryptosProviderNotifier =
    AsyncNotifierProvider<SavedCryptoProvider, List<types.Crypto>>(
        SavedCryptoProvider.new);

final getSavedAssetsProvider = FutureProvider<List<types.Asset>?>((ref) async {
  final cryptoStorage = ref.watch(cryptoStorageProvider);
  final account = await ref.watch(currentAccountProvider.future);
  if (account != null) {
    log("Getting saved assets");
    final savedAssets = await cryptoStorage.getSavedAssets(wallet: account);
    log("Saved Assets len ${savedAssets?.length}");

    return savedAssets;
  }
  return null;
});

final allAccountsProvider =
    FutureProvider<List<types.PublicAccount>>((ref) async {
  return await ref.watch(accountsNotifierProvider.future);
});

final currentAccountProvider =
    FutureProvider<types.PublicAccount?>((ref) async {
  final accounts = await ref.watch(accountsNotifierProvider.future);
  final lastKeyId = await ref.watch(lastConnectedKeyIdNotifierProvider.future);
  if (accounts.isEmpty) {
    throw ("No account found");
  }

  if (lastKeyId != null) {
    final accountFounded = accounts.firstWhere(
      (acc) => acc.keyId.toLowerCase().trim() == lastKeyId.toLowerCase().trim(),
      orElse: () => accounts.first,
    );
    log("Last account id: $lastKeyId");

    log("Account founded: ${accountFounded.toJson()}");
    return accountFounded;
  }
  return accounts.firstOrNull;
});

final lastConnectedKeyIdNotifierProvider =
    AsyncNotifierProvider<LastConnectedKeyIdNotifier, String?>(
        LastConnectedKeyIdNotifier.new);

final currentPageIndexNotifierProvider =
    AsyncNotifierProvider<CurrentPageIndexNotifier, int>(
        CurrentPageIndexNotifier.new);

final web3ProviderNotifier = Provider<WalletManagerNotifier>((ref) {
  return WalletManagerNotifier(ref);
});

final appUIConfigProvider =
    AsyncNotifierProvider<AppUIConfigNotifier, types.AppUIConfig>(() {
  return AppUIConfigNotifier();
});

final appSecureConfigProvider =
    AsyncNotifierProvider<AppSecureConfigNotifier, types.AppSecureConfig>(
  AppSecureConfigNotifier.new,
);
/*
final transactionsProviderNotifier = AsyncNotifierProvider.family<
    TransactionsNotifier, List<Transaction>, AccountWithToken>(
  TransactionsNotifier.new,
);

final savedTransactionProviderNotifier = AsyncNotifierProvider.family<
    SavedTransactions, List<Transaction>, AccountWithToken>(
  SavedTransactions.new,
);
*/
