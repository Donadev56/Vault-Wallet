import 'package:ulid/ulid.dart';

class IdManager {
  String generateUUID() {
    return Ulid().toUuid();
  }
}
