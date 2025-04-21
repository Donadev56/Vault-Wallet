import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:local_auth/local_auth.dart';
import 'package:moonwallet/logger/logger.dart';
import 'package:moonwallet/service/db/wallet_saver.dart';
import 'package:moonwallet/utils/prefs.dart';

class BioStatusNotifier extends AsyncNotifier<bool> {
  final String bioKey = "BioStatus";
  static const String on = "on";
  static const String off = "off";
  final LocalAuthentication auth = LocalAuthentication();

  @override
  Future<bool> build() => loadCanUseBio();

  Future<bool> loadCanUseBio() async {
    try {
      final prefs = PublicDataManager();
      final biometryStatus = await prefs.getDataFromPrefs(key: bioKey);
      return biometryStatus == on;
    } catch (e) {
      log("Error checking biometry status: $e");
      return false;
    }
  }

  Future<bool> changeValue(bool v) async {
    try {
      final result = await PublicDataManager()
          .saveDataInPrefs(data: v ? on : off, key: bioKey);
      if (result) {
        state = AsyncData(v);
      }

      return result;
    } catch (e) {
      logError(e.toString());
      return false;
    }
  }

  Future<bool> toggleCanUseBio(bool v, String password) async {
    try {
      if (!(await WalletSaver().isPasswordValid(password))) {
        throw Exception("Wrong password");
      }
      if (!v) {
        return await changeValue(v);
      }

      final bool canCheckBiometrics = await auth.canCheckBiometrics;
      final bool isDeviceSupported = await auth.isDeviceSupported();
      final bool canAuthenticate = canCheckBiometrics || isDeviceSupported;
      if (canAuthenticate) {
        if (await auth.authenticate(
            localizedReason: "Enabled to use biometric authentication")) {
          await changeValue(v);
          return true;
        }
      }

      return false;
    } catch (e) {
      logError(e.toString());
      return false;
    }
  }
}
