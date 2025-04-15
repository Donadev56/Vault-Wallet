import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moonwallet/utils/crypto.dart';

class LastConnectedKeyIdNotifier extends StateNotifier<String?> {
  final Ref ref;

  LastConnectedKeyIdNotifier(this.ref) : super(null) {
    _load();
  }

  Future<void> _load() async {
    final encrypt = EncryptService();
    final keyId = await encrypt.getLastConnectedAddress();
    state = keyId;
  }

  Future<void> updateKeyId(String keyId) async {
    final encrypt = EncryptService();
    await encrypt.saveLastConnectedData(keyId);
    state = keyId;
  }
}
