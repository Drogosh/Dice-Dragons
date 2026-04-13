import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import '../models/roll_response.dart';

/// Сервис для работы с ответами игроков в RTDB
class RealtimeResponsesService {
  final FirebaseDatabase _database = FirebaseDatabase.instance;

  static const String _liveSessionsPath = 'liveSessions';
  static const String _responsesPath = 'responses';

  /// Отправить ответ на запрос
  Future<void> submitResponse({
    required String sessionId,
    required String requestId,
    required String uid,
    required String displayName,
    String? characterId,
    String? characterName,
    required int baseRoll,
    required String mode,
    required int modifier,
    required int total,
    bool? success,
  }) async {
    try {
      final ref = _database.ref(
        '$_liveSessionsPath/$sessionId/$_responsesPath/$requestId/$uid',
      );

      final responseData = {
        'uid': uid,
        'displayName': displayName,
        'characterId': characterId,
        'characterName': characterName,
        'baseRoll': baseRoll,
        'mode': mode,
        'modifier': modifier,
        'total': total,
        'createdAt': DateTime.now().toIso8601String(),
        'success': success,
      };

      await ref.set(responseData);
      debugPrint('✅ Ответ отправлен: $uid на запрос $requestId');
    } catch (e) {
      debugPrint('❌ Ошибка отправки ответа: $e');
      rethrow;
    }
  }

  /// Watch все ответы на запрос (для DM)
  Stream<Map<String, RollResponse>> watchResponses(
    String sessionId,
    String requestId,
  ) {
    return _database
        .ref('$_liveSessionsPath/$sessionId/$_responsesPath/$requestId')
        .onValue
        .map((event) {
          if (!event.snapshot.exists) return {};

          final data = event.snapshot.value as Map?;
          if (data == null) return {};

          return Map.fromEntries(
            data.entries.map((e) {
              try {
                final mapData = Map<String, dynamic>.from(e.value as Map);
                return MapEntry(e.key, RollResponse.fromMap(e.key, mapData));
              } catch (err) {
                debugPrint('❌ Ошибка парсинга ответа: $err');
                return null;
              }
            }).whereType<MapEntry<String, RollResponse>>(),
          );
        });
  }

  /// Получить все ответы на запрос (разовый запрос)
  Future<Map<String, RollResponse>> getResponses(
    String sessionId,
    String requestId,
  ) async {
    try {
      final snapshot = await _database
          .ref('$_liveSessionsPath/$sessionId/$_responsesPath/$requestId')
          .get();

      if (!snapshot.exists) return {};

      final data = snapshot.value as Map?;
      if (data == null) return {};

      return Map.fromEntries(
        data.entries.map((e) {
          final mapData = Map<String, dynamic>.from(e.value as Map);
          return MapEntry(e.key, RollResponse.fromMap(e.key, mapData));
        }),
      );
    } catch (e) {
      debugPrint('❌ Ошибка получения ответов: $e');
      return {};
    }
  }

  /// Проверить, ответил ли игрок
  Future<bool> hasPlayerResponded(
    String sessionId,
    String requestId,
    String uid,
  ) async {
    try {
      final snapshot = await _database
          .ref('$_liveSessionsPath/$sessionId/$_responsesPath/$requestId/$uid')
          .get();

      return snapshot.exists;
    } catch (e) {
      debugPrint('❌ Ошибка проверки ответа: $e');
      return false;
    }
  }

  /// Удалить ответ (если нужно отменить)
  Future<void> deleteResponse(
    String sessionId,
    String requestId,
    String uid,
  ) async {
    try {
      await _database
          .ref('$_liveSessionsPath/$sessionId/$_responsesPath/$requestId/$uid')
          .remove();

      debugPrint('✅ Ответ удален: $uid на запрос $requestId');
    } catch (e) {
      debugPrint('❌ Ошибка удаления ответа: $e');
      rethrow;
    }
  }
}



