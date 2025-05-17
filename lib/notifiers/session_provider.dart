import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moonwallet/logger/logger.dart';
import 'package:moonwallet/service/db/session_db.dart';
import 'package:moonwallet/service/db/wallet_db_stateless.dart';
import 'package:moonwallet/types/account_related_types.dart';
import 'package:moonwallet/types/exception.dart';
import 'package:moonwallet/types/types.dart';
import 'package:moonwallet/utils/encrypt_service.dart';
import 'package:moonwallet/utils/id_manager.dart';
import 'package:moonwallet/utils/prefs.dart';

class SessionProvider extends AsyncNotifier<LocalSession?> {
  final unsavedSessionKey = "user/unsaved/local-session";
  @override
  Future<LocalSession?> build() async => null;

  Future<DerivateKeys> generateSessionKey(String derivateKey) async {
    return await EncryptService().generateNewSecretKey(derivateKey);
  }

  Future<void> startSession(String derivateKey) async {
    try {
      final now = (DateTime.now().millisecondsSinceEpoch / 1000).toInt();
      final id = IdManager().generateUUID();
      final sessionKey = await generateSessionKey(derivateKey);
      final isKeyValid =
          await WalletDbStateLess().isDerivateKeyValid(derivateKey);
      if (!isKeyValid) {
        throw InvalidPasswordException();
      }
      final lastTrace = await getTrace();
      if (lastTrace != null) {
        await SessionDb()
            .saveSession(lastTrace.copyWith(endTime: now, hasExpired: true));
      }

      LocalSession newSession = LocalSession(
          startTime: now,
          endTime: 0,
          sessionId: id,
          sessionKey: sessionKey,
          hasExpired: false,
          isAuthenticated: true);
      await keepTrace(newSession);

      state = AsyncData(newSession);
      log("Session : $id started");
    } catch (e) {
      logError(e.toString());
      rethrow;
    }
  }

  Future<bool> keepTrace(LocalSession session) async {
    try {
      return await PublicDataManager().saveDataInPrefs(
          data: jsonEncode(session.toJson()), key: unsavedSessionKey);
    } catch (e) {
      logError(e.toString());
      return false;
    }
  }

  Future<LocalSession?> getTrace() async {
    try {
      final unsavedSession =
          await PublicDataManager().getDataFromPrefs(key: unsavedSessionKey);
      if (unsavedSession == null) {
        throw "No unsaved session";
      }
      return LocalSession.fromJson(jsonDecode(unsavedSession));
    } catch (e) {
      logError(e.toString());
      return null;
    }
  }

  Future<bool> removeTrace() async {
    try {
      return await PublicDataManager()
          .removeDataFromPrefs(key: unsavedSessionKey);
    } catch (e) {
      logError(e.toString());
      return false;
    }
  }

  Future<void> endSession() async {
    try {
      final lastSession = state.value;
      if (lastSession == null || lastSession.hasExpired) {
        throw Exception("Session not found");
      }
      final now = (DateTime.now().millisecondsSinceEpoch / 1000).toInt();
      final newSession = lastSession.copyWith(hasExpired: true, endTime: now);
      await SessionDb().saveSession(newSession);
      await removeTrace();
      state = AsyncData(newSession);
      log("Session $lastSession ended");
    } catch (e) {
      logError(e.toString());
    }
  }

  Future<List<LocalSession>> getListSessions() async {
    try {
      return await SessionDb().getSessions();
    } catch (e) {
      logError(e.toString());
      rethrow;
    }
  }
}
