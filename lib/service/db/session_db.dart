import 'package:moonwallet/logger/logger.dart';
import 'package:moonwallet/service/db/global_database.dart';
import 'package:moonwallet/types/types.dart';

class SessionDb {
  final sessionKeyName = "user/global-session-list";
  final db = GlobalDatabase();

  Future<List<LocalSession>> getSessions() async {
    try {
      final savedSessions = await db.getDynamicData(key: sessionKeyName);
      if (savedSessions != null && savedSessions is List) {
        final sessions =
            savedSessions.map((e) => LocalSession.fromJson(e)).toList();
        return sessions;
      }
      return [];
    } catch (e) {
      logError(e.toString());
      return [];
    }
  }

  Future<bool> saveSession(LocalSession session) async {
    try {
      List<LocalSession> savedSessions = await getSessions();
      savedSessions = [...savedSessions, session];
      final sessionJson = savedSessions.map((e) => e.toJson()).toList();

      return await db.saveDynamicData(data: sessionJson, key: sessionKeyName);
    } catch (e) {
      logError(e.toString());
      return false;
    }
  }
}
