import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moonwallet/logger/logger.dart';
import 'package:moonwallet/notifiers/providers.dart';
import 'package:moonwallet/service/db/wallet_db_stateless.dart';
import 'package:moonwallet/types/account_related_types.dart';
import 'package:moonwallet/types/types.dart';
import 'package:moonwallet/widgets/func/security/ask_password.dart';

class AccountsNotifier extends AsyncNotifier<List<PublicAccount>> {
  final walletSaver = WalletDbStateLess();

  List<PublicAccount> get currentAccounts => [...state.value ?? []];

  @override
  Future<List<PublicAccount>> build() async {
    return await getPublicAccount();
  }

  Future<bool> saveLastConnectedAccount(String keyId) async {
    try {
      await ref
          .read(lastConnectedKeyIdNotifierProvider.notifier)
          .updateKeyId(keyId);

      return true;
    } catch (e) {
      logError(e.toString());
      return false;
    }
  }

  PublicAccount? getAccountByKeyId(String keyId) {
    return state.value?.firstWhere((acc) => acc.keyId == keyId);
  }

  Future<List<PublicAccount>> getPublicAccount() async {
    try {
      return await walletSaver.getListPublicAccount();
    } catch (e) {
      logError(e.toString());
      return [];
    }
  }

  Future<bool> deleteWallet(PublicAccount accountToRemove, AppColors colors,
      BuildContext context) async {
    try {
      final password = await askUserPassword(context: context, colors: colors);
      if (password == null) {
        throw InvalidPasswordException();
      }
      final isValid = await WalletDbStateLess().isPasswordValid(password);

      if (!isValid) {
        throw InvalidPasswordException();
      }
      if (state.value == null) throw ("No account found");
      if (state.value?.length != null && (state.value?.length ?? 0) == 1) {
        await walletSaver.saveListPublicAccount([]);
        state = AsyncData([]);
      }

      final newState = AsyncValue.data(state.value!
          .where((val) => val.keyId != accountToRemove.keyId)
          .toList());

      final currentAccount = await ref.read(currentAccountProvider.future);
      final accountIndex = currentAccounts
          .indexWhere((acc) => acc.keyId == accountToRemove.keyId);

      if (accountToRemove.keyId == currentAccount?.keyId) {
        await saveLastConnectedAccount(currentAccounts[accountIndex - 1].keyId);
      }

      final result = await walletSaver.saveListPublicAccount(newState.value!);
      if (result) {
        state = newState;

        log("Account deleted successfully");
        return true;
      }
      throw ("Failed to delete account");
    } catch (e) {
      logError(e.toString());
      rethrow;
    }
  }

  Future<bool> reorderList(int oldIndex, int newIndex) async {
    try {
      if (state.value == null) throw ("No account found");

      log(" old index : $oldIndex new index : $newIndex");
      if (oldIndex < newIndex) {
        newIndex -= 1;
      }
      final accounts = currentAccounts;
      final removedAccount = accounts.removeAt(oldIndex);
      accounts.insert(newIndex, removedAccount);
      state = AsyncValue.data(accounts);

      final result = await walletSaver.saveListPublicAccount(accounts);
      if (result) {
        log("List reordered successfully");
        return true;
      } else {
        throw ("Failed to reorder list");
      }
    } catch (e) {
      logError(e.toString());
      rethrow;
    }
  }

  Future<bool> editWallet(
      {required PublicAccount account,
      String? name,
      IconData? icon,
      Color? color}) async {
    if (state.value == null) throw ("No account found");

    try {
      final res = await walletSaver.editWallet(
          account: account, newName: name, icon: icon, color: color);
      if (res != null) {
        final newWallets = await getPublicAccount();
        state = AsyncValue.data(newWallets);
        return true;
      }
      throw ("Failed to edit wallet");
    } catch (e) {
      logError(e.toString());
      return false;
    }
  }
}
