import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';
import 'package:moonwallet/logger/logger.dart';

class InternetManager {
  final internetChecker = InternetConnection();

  Future<bool> isConnected() async {
    try {
      if ((await internetChecker.internetStatus
          .then((st) => st == InternetStatus.connected))) {
        return true;
      }

      return false;
    } catch (e) {
      logError(e.toString());
      return false;
    }
  }
}
