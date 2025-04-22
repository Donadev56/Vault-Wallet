import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';
import 'package:moonwallet/logger/logger.dart';
import 'package:moonwallet/service/db/global_database.dart';
import 'package:moonwallet/service/db/wallet_saver.dart';
import 'package:moonwallet/types/types.dart';
import 'package:moonwallet/utils/crypto.dart';

class AppSecureConfigNotifier extends AsyncNotifier<AppSecureConfig> {
  final _db = GlobalDatabase();
  final _walletStorage = WalletSaver();
  final _encryptService = EncryptService();
  final LocalAuthentication _auth = LocalAuthentication();

  final dataKey = "userSecureConfig";



  @override
  Future<AppSecureConfig> build()  =>  getSecureConfig();

  Future<bool> saveConfig (AppSecureConfig secureConfig, String password) async {
    try {
      final encryptedSecureConfig =await _encryptService.encryptJson(jsonEncode(secureConfig.toJson()), password);
      final result = await _db.saveDynamicData(data: encryptedSecureConfig, key: dataKey );
       if (result) {
        state = AsyncData(secureConfig);
       }

       return result;
    } catch (e) {
      logError(e.toString());
      return false ;
      
    }

  }

  Future<AppSecureConfig> getSecureConfig () async {
    try {

      final savedConfig = await _db.getDynamicData(key: dataKey);
      if (savedConfig == null) {
        return AppSecureConfig();
      }
      final decryptedConfig = await _encryptService.decryptJson(savedConfig, (await _walletStorage.getSavedPassword()) ?? "");
      if (decryptedConfig != null) {
        return AppSecureConfig.fromJson(
          jsonDecode(decryptedConfig)
        );
      }

      return AppSecureConfig();

    } catch (e) {
      logError(e.toString());
      return AppSecureConfig() ;
      
    }
  }

    Future<bool> updateConfig ({bool ? useBio,required String password})  async{
      try {
        final lastSecureConfig = state.value ;
        final newConfig =( lastSecureConfig ?? AppSecureConfig()).copyWith(
          useBioMetric:  useBio 
        );
        return await saveConfig(newConfig, password);
      } catch (e) {
        logError(e.toString());
        return false ;
        
      }
    }
    Future<bool> toggleCanUseBio(bool v, String password) async {
    try {
      if (!(await WalletSaver().isPasswordValid(password))) {
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
          return await updateConfig(useBio: v, password: password );
        }
      }

      return false;
    } catch (e) {
      logError(e.toString());
      return false;
    }
  }

}