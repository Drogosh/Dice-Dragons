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

      debugPrint('📤 submitResponse START: sessionId=$sessionId requestId=$requestId uid=$uid');
      debugPrint('   data: baseRoll=$baseRoll mode=$mode modifier=$modifier total=$total');

      await ref.set(responseData);
      debugPrint('✅ submitResponse SUCCESS: ответ сохранен');
    } catch (e, stackTrace) {
      debugPrint('❌ submitResponse ERROR: $e\nStackTrace: $stackTrace');
      rethrow;
    }
  }

  /// Watch все ответы на запрос (для DM - real-time)
  Stream<Map<String, RollResponse>> watchResponses(
    String sessionId,
    String requestId,
  ) {
    return _database
        .ref('$_liveSessionsPath/$sessionId/$_responsesPath/$requestId')
        .onValue
        .map((event) {
          try {
            if (!event.snapshot.exists) {
              debugPrint('📭 watchResponses: no responses for $requestId');
              return {};
            }

            final raw = event.snapshot.value;
            if (raw == null) {
              debugPrint('📭 watchResponses: snapshot.value is null');
              return {};
            }

            final Map<String, dynamic> map;
            try {
              map = Map<String, dynamic>.from(raw as Map);
            } catch (e) {
              debugPrint('⚠️  watchResponses: failed to cast: $e');
              return {};
            }

            debugPrint('📨 watchResponses: got ${map.length} responses for requestId=$requestId');

            final results = <String, RollResponse>{};
            for (final entry in map.entries) {
              try {
                final mapData = Map<String, dynamic>.from(entry.value as Map);
                final response = RollResponse.fromMap(entry.key, mapData);
                results[entry.key] = response;
                debugPrint('   ✅ Response from ${response.displayName}: total=${response.total}');
              } catch (e) {
                debugPrint('⚠️  watchResponses: parse error for ${entry.key}: $e');
              }
            }

            debugPrint('✅ watchResponses: returning ${results.length} responses');
            return results;
          } catch (e, stackTrace) {
            debugPrint('❌ watchResponses ERROR: $e\nStackTrace: $stackTrace');
            return {};
          }
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



