import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moonwallet/logger/logger.dart';
import 'package:moonwallet/notifiers/providers.dart';
import 'package:moonwallet/types/types.dart';

class AccountsNotifier extends AsyncNotifier<List<PublicData>> {
  late final walletSaver = ref.read(walletSaverProvider);
  late final encryptService = ref.read(encryptServiceProvider);

  List<PublicData> get currentAccounts => [...state.value ?? []];

  @override
  Future<List<PublicData>> build() async {
    return await getPublicData();
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

  PublicData? getAccountByKeyId(String keyId) {
    return state.value?.firstWhere((acc) => acc.keyId == keyId);
  }

  Future<List<PublicData>> getPublicData() async {
    try {
      final savedData = await walletSaver.getPublicData();
      List<PublicData> accounts = [];
      if (savedData != null && savedData.isNotEmpty) {
        for (final account in savedData) {
          final newAccount = PublicData.fromJson(account);
          accounts.add(newAccount);
        }
      }
      log("Accounts length ${accounts.length}");
      return accounts;
    } catch (e) {
      logError(e.toString());
      return [];
    }
  }

  Future<bool> deleteWallet(PublicData accountToRemove) async {
    try {
      if (state.value == null) throw ("No account found");

      final newState = AsyncValue.data(state.value!
          .where((val) => val.keyId != accountToRemove.keyId)
          .toList());
      final currentAccount = await ref.read(currentAccountProvider.future);
      final accountIndex = currentAccounts
          .indexWhere((acc) => acc.keyId == accountToRemove.keyId);

      if (accountToRemove.keyId == currentAccount?.keyId) {
        await saveLastConnectedAccount(currentAccounts[accountIndex - 1].keyId);
      }

      final result = await walletSaver.saveListPublicData(newState.value!);
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

      final result = await walletSaver.saveListPublicData(accounts);
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
      {required PublicData account,
      String? name,
      IconData? icon,
      Color? color}) async {
    if (state.value == null) throw ("No account found");

    try {
      final res = await walletSaver.editWallet(
          account: account, newName: name, icon: icon, color: color);
      if (res != null) {
        final newWallets = await getPublicData();
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
