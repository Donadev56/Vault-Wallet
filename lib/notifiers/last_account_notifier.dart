import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moonwallet/utils/prefs.dart';

import '../logger/logger.dart';

class LastConnectedKeyIdNotifier extends AsyncNotifier<String?> {
  @override
  Future<String?> build() => load();
  final prefs = PublicDataManager();

  Future<String?> load() async {
    final keyId = await prefs.getLastConnectedAddress();
    log("Key id ${keyId}");
    return keyId;
  }

  Future<void> updateKeyId(String keyId) async {
    await prefs.saveLastConnectedData(keyId);
    state = AsyncData(keyId);
    //ref.invalidate(getSavedAssetsProvider);
    // ref.invalidate(assetsNotifierProvider);
  }
}
