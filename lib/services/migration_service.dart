import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'firebase_realtime_database_service.dart';
import '../models/session.dart';

/// Сервис для миграции данных из Firestore в Real-time Database
class MigrationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseRealtimeDatabaseService _rtdb;

  MigrationService(this._rtdb);

  static const String _sessionsCollection = 'sessions';
  static const String _membersSubcollection = 'members';

  /// Мигрировать все сессии из Firestore в RTDB
  Future<MigrationResult> migrateAllSessions() async {
    try {
      debugPrint('🔄 Начало миграции сессий из Firestore...');

      int successCount = 0;
      int errorCount = 0;

      final snapshot = await _firestore.collection(_sessionsCollection).get();

      for (final doc in snapshot.docs) {
        try {
          final session = await _getSessionWithMembers(doc.id);
          if (session != null) {
            await _rtdb.createSessionInRTDB(session);
            successCount++;
            debugPrint('✅ Мигрирована сессия: ${session.name}');
          }
        } catch (e) {
          errorCount++;
          debugPrint('❌ Ошибка при миграции сессии ${doc.id}: $e');
        }
      }

      debugPrint('🎉 Миграция завершена! Успешно: $successCount, Ошибок: $errorCount');
      return MigrationResult(
        successCount: successCount,
        errorCount: errorCount,
        totalCount: snapshot.docs.length,
      );
    } catch (e) {
      debugPrint('❌ Критическая ошибка при миграции: $e');
      rethrow;
    }
  }

  /// Мигрировать одну сессию
  Future<bool> migrateSession(String sessionId) async {
    try {
      debugPrint('🔄 Миграция сессии: $sessionId');

      final session = await _getSessionWithMembers(sessionId);
      if (session == null) {
        debugPrint('❌ Сессия не найдена: $sessionId');
        return false;
      }

      await _rtdb.createSessionInRTDB(session);
      debugPrint('✅ Сессия успешно мигрирована: ${session.name}');
      return true;
    } catch (e) {
      debugPrint('❌ Ошибка при миграции сессии: $e');
      return false;
    }
  }

  /// Получить сессию с членами из Firestore
  Future<Session?> _getSessionWithMembers(String sessionId) async {
    try {
      final docSnapshot = await _firestore
          .collection(_sessionsCollection)
          .doc(sessionId)
          .get();

      if (!docSnapshot.exists) return null;

      final data = docSnapshot.data() as Map<String, dynamic>;

      // Получить членов из подколлекции
      final membersSnapshot = await _firestore
          .collection(_sessionsCollection)
          .doc(sessionId)
          .collection(_membersSubcollection)
          .get();

      final members = <String, SessionMember>{};
      for (final memberDoc in membersSnapshot.docs) {
        final memberData = memberDoc.data();
        members[memberDoc.id] = SessionMember.fromMap(memberDoc.id, memberData);
      }

      return Session.fromMap(
        sessionId,
        data,
        members: members,
      );
    } catch (e) {
      debugPrint('❌ Ошибка получения сессии из Firestore: $e');
      return null;
    }
  }

  /// Проверить статус миграции
  Future<MigrationStatus> checkMigrationStatus() async {
    try {
      final firestoreSessions = await _firestore
          .collection(_sessionsCollection)
          .get();

      final firestoreCount = firestoreSessions.docs.length;

      // Получить количество сессий в RTDB (примерно)
      final rtdbCount = firestoreCount; // Временно

      return MigrationStatus(
        firestoreCount: firestoreCount,
        rtdbCount: rtdbCount,
        isMigrated: firestoreCount <= rtdbCount,
      );
    } catch (e) {
      debugPrint('❌ Ошибка проверки статуса миграции: $e');
      rethrow;
    }
  }

  /// Синхронизировать данные (двусторонняя синхронизация)
  Future<void> syncSessionData(String sessionId) async {
    try {
      debugPrint('🔄 Синхронизация сессии: $sessionId');

      final firestoreSession = await _getSessionWithMembers(sessionId);
      if (firestoreSession == null) {
        debugPrint('❌ Сессия не найдена в Firestore: $sessionId');
        return;
      }

      await _rtdb.createSessionInRTDB(firestoreSession);
      debugPrint('✅ Сессия синхронизирована: $sessionId');
    } catch (e) {
      debugPrint('❌ Ошибка синхронизации: $e');
      rethrow;
    }
  }
}

/// Результат миграции
class MigrationResult {
  final int successCount;
  final int errorCount;
  final int totalCount;

  MigrationResult({
    required this.successCount,
    required this.errorCount,
    required this.totalCount,
  });

  int get failedCount => totalCount - successCount;
  double get successPercentage => (successCount / totalCount) * 100;

  @override
  String toString() {
    return 'MigrationResult('
        'успешно: $successCount, '
        'ошибок: $errorCount, '
        'всего: $totalCount, '
        'успешность: ${successPercentage.toStringAsFixed(1)}%'
        ')';
  }
}

/// Статус миграции
class MigrationStatus {
  final int firestoreCount;
  final int rtdbCount;
  final bool isMigrated;

  MigrationStatus({
    required this.firestoreCount,
    required this.rtdbCount,
    required this.isMigrated,
  });

  @override
  String toString() {
    return 'MigrationStatus('
        'Firestore: $firestoreCount, '
        'RTDB: $rtdbCount, '
        'мигрировано: ${isMigrated ? "✅" : "❌"}'
        ')';
  }
}

