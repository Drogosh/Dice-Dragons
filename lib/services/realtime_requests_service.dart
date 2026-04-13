import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import '../models/request.dart';

/// Сервис для работы с live запросами в RTDB
class RealtimeRequestsService {
  final FirebaseDatabase _database = FirebaseDatabase.instance;

  static const String _liveSessionsPath = 'liveSessions';
  static const String _requestsPath = 'requests';

  /// Создать новый запрос в RTDB
  Future<String> createRequest({
    required String sessionId,
    required String dmId,
    required Request request,
  }) async {
    try {
      // Генерируем ключ под правильным путем requests
      final requestsRef = _database.ref('$_liveSessionsPath/$sessionId/$_requestsPath');
      final newRef = requestsRef.push();
      final requestId = newRef.key;

      if (requestId == null) {
        throw Exception('Failed to generate request ID');
      }

      final requestData = {
        'id': requestId,
        'sessionId': sessionId,
        'dmId': dmId,
        'type': request.type.name,
        'formula': request.formula,
        'modifier': request.modifier,
        'targetAc': request.targetAc,
        'note': request.note,
        'abilityType': request.abilityType?.name,
        'status': 'open',
        'audience': request.audience,
        'targetUids': request.targetUids,
        'createdAt': DateTime.now().toIso8601String(),
      };

      await newRef.set(requestData);
      debugPrint('✅ Live запрос создан: $requestId в сессии $sessionId');
      debugPrint('   Тип: ${request.type.name}, Формула: ${request.formula}');
      return requestId;
    } catch (e) {
      debugPrint('❌ Ошибка создания запроса: $e');
      rethrow;
    }
  }

  /// Watch все открытые запросы сессии для DM
  Stream<List<Request>> watchDMRequests(String sessionId) {
    return _database
        .ref('$_liveSessionsPath/$sessionId/$_requestsPath')
        .onValue
        .map((event) {
          if (!event.snapshot.exists) {
            debugPrint('📭 No requests found for session $sessionId');
            return [];
          }

          final data = event.snapshot.value as Map?;
          if (data == null) {
            debugPrint('📭 Requests data is null for session $sessionId');
            return [];
          }

          debugPrint('📨 Received ${data.length} requests for session $sessionId');

          return data.entries
              .map((e) {
                try {
                  return _parseRequest(e.key, e.value as Map);
                } catch (err) {
                  debugPrint('❌ Ошибка парсинга запроса ${e.key}: $err');
                  return null;
                }
              })
              .whereType<Request>()
              .where((req) => req.status == 'open')
              .toList();
        });
  }

  /// Watch открытые запросы для конкретного игрока
  Stream<List<Request>> watchPlayerRequests(
    String sessionId,
    String playerId,
    int totalPlayersCount,
  ) {
    return _database
        .ref('$_liveSessionsPath/$sessionId/$_requestsPath')
        .onValue
        .map((event) {
          if (!event.snapshot.exists) return [];

          final data = event.snapshot.value as Map?;
          if (data == null) return [];

          return data.entries
              .map((e) {
                try {
                  return _parseRequest(e.key, e.value as Map);
                } catch (err) {
                  debugPrint('❌ Ошибка парсинга запроса: $err');
                  return null;
                }
              })
              .whereType<Request>()
              .where((req) =>
                  req.status == 'open' &&
                  (req.audience == 'all' || (req.audience == 'subset' && req.targetUids.contains(playerId))))
              .toList();
        });
  }

  /// Закрыть запрос
  Future<void> closeRequest(String sessionId, String requestId) async {
    try {
      await _database
          .ref('$_liveSessionsPath/$sessionId/$_requestsPath/$requestId/status')
          .set('closed');

      debugPrint('✅ Запрос закрыт: $requestId');
    } catch (e) {
      debugPrint('❌ Ошибка закрытия запроса: $e');
      rethrow;
    }
  }

  /// Удалить запрос
  Future<void> deleteRequest(String sessionId, String requestId) async {
    try {
      // Сначала удаляем все ответы
      await _database
          .ref('$_liveSessionsPath/$sessionId/responses/$requestId')
          .remove();

      // Потом удаляем сам запрос
      await _database
          .ref('$_liveSessionsPath/$sessionId/$_requestsPath/$requestId')
          .remove();

      debugPrint('✅ Запрос удален: $requestId');
    } catch (e) {
      debugPrint('❌ Ошибка удаления запроса: $e');
      rethrow;
    }
  }

  /// Парсер запроса из RTDB
  Request _parseRequest(String id, Map requestData) {
    return Request(
      id: id,
      sessionId: requestData['sessionId'] as String? ?? '',
      dmId: requestData['dmId'] as String? ?? '',
      characterId: '',
      characterName: '',
      type: RequestType.values.firstWhere(
        (t) => t.name == requestData['type'],
        orElse: () => RequestType.check,
      ),
      formula: requestData['formula'] as String? ?? '',
      modifier: requestData['modifier'] as int? ?? 0,
      targetAc: requestData['targetAc'] as int?,
      note: requestData['note'] as String?,
      abilityType: requestData['abilityType'] != null
          ? AbilityType.values.firstWhere(
              (a) => a.name == requestData['abilityType'],
              orElse: () => AbilityType.strength,
            )
          : null,
      createdAt: requestData['createdAt'] as String?,
      status: requestData['status'] as String? ?? 'open',
      audience: requestData['audience'] as String? ?? 'all',
      targetUids: List<String>.from(requestData['targetUids'] as List<dynamic>? ?? []),
    );
  }
}



