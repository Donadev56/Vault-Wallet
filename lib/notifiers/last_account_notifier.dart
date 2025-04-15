import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moonwallet/utils/crypto.dart';

import '../logger/logger.dart';

class LastConnectedKeyIdNotifier extends AsyncNotifier<String?> {
  @override
  Future<String?> build() => load();

  Future<String?> load() async {
    final encrypt = EncryptService();

    final keyId = await encrypt.getLastConnectedAddress();
    log("Key id ${keyId}");
    return keyId;
  }

  Future<void> updateKeyId(String keyId) async {
    final encrypt = EncryptService();
    await encrypt.saveLastConnectedData(keyId);
    state = AsyncData(keyId);
  }
}
