import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';
import 'package:moonwallet/logger/logger.dart';
import 'package:moonwallet/service/db/secure_storage.dart';
import 'package:moonwallet/service/db/wallet_db.dart';
import 'package:moonwallet/types/types.dart';

class AppSecureConfigNotifier extends AsyncNotifier<AppSecureConfig> {
  final _walletStorage = WalletDatabase();
  final _secureStorage = SecureStorageService();
  final LocalAuthentication _auth = LocalAuthentication();

  final dataKey = "userSecureConfig";

  @override
  Future<AppSecureConfig> build() => getSecureConfig();

  Future<bool> saveConfig(AppSecureConfig secureConfig, String password) async {
    try {
      if (!(await _walletStorage.isPasswordValid(password))) {
        throw Exception("Wrong password");
      }
      await _secureStorage.saveDataInFSS(
          json.encode(secureConfig.toJson()), dataKey);
      state = AsyncData(secureConfig);

      return true;
    } catch (e) {
      logError(e.toString());
      return false;
    }
  }

  Future<AppSecureConfig> getSecureConfig() async {
    try {
      final savedConfig = await _secureStorage.loadDataFromFSS(dataKey);
      if (savedConfig == null) {
        return AppSecureConfig();
      }

      return AppSecureConfig.fromJson(jsonDecode(savedConfig));
    } catch (e) {
      logError(e.toString());
      return AppSecureConfig();
    }
  }

  Future<bool> updateConfig(
      {bool? useBio, bool? lockAtStartup, required String password}) async {
    try {
      final lastSecureConfig = state.value;
      final newConfig = (lastSecureConfig ?? AppSecureConfig())
          .copyWith(useBioMetric: useBio, lockAtStartup: lockAtStartup);
      return await saveConfig(newConfig, password);
    } catch (e) {
      logError(e.toString());
      return false;
    }
  }

  Future<bool> toggleCanUseBio(bool v, String password) async {
    try {
      if (!(await _walletStorage.isPasswordValid(password))) {
        throw Exception("Wrong password");
      }
      if (!v) {
        return await updateConfig(useBio: v, password: password);
      }

      final bool canCheckBiometrics = await _auth.canCheckBiometrics;
      final bool isDeviceSupported = await _auth.isDeviceSupported();
      final bool canAuthenticate = canCheckBiometrics || isDeviceSupported;
      if (canAuthenticate) {
        if (await _auth.authenticate(
            localizedReason: "Enabled to use biometric authentication")) {
          return await updateConfig(useBio: v, password: password);
        }
      }

      return false;
    } catch (e) {
      logError(e.toString());
      return false;
    }
  }
}
