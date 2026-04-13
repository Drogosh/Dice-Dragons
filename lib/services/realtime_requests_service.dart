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

  /// Парсер запроса из RTDB (типобезопасный)
  Request _parseRequest(String id, Map requestData) {
    try {
      // Безопасно преобразуем в Map<String, dynamic>
      final data = Map<String, dynamic>.from(requestData);

      // Parse targetUids (может быть list или map)
      List<String> targetUids = [];
      if (data['targetUids'] != null) {
        try {
          if (data['targetUids'] is List) {
            targetUids = List<String>.from(data['targetUids'] as List<dynamic>);
          } else if (data['targetUids'] is Map) {
            // Если это map от Firebase (map-of-true pattern)
            targetUids = (data['targetUids'] as Map).keys.cast<String>().toList();
          }
        } catch (e) {
          debugPrint('⚠️  Error parsing targetUids for $id: $e');
        }
      }

      return Request(
        id: id,
        sessionId: (data['sessionId'] as String?) ?? '',
        dmId: (data['dmId'] as String?) ?? '',
        characterId: (data['characterId'] as String?) ?? '',
        characterName: (data['characterName'] as String?) ?? '',
        type: RequestType.values.firstWhere(
          (t) => t.name == data['type'],
          orElse: () => RequestType.check,
        ),
        formula: (data['formula'] as String?) ?? '',
        modifier: (data['modifier'] as int?) ?? 0,
        targetAc: data['targetAc'] as int?,
        note: data['note'] as String?,
        abilityType: data['abilityType'] != null
            ? AbilityType.values.firstWhere(
                (a) => a.name == data['abilityType'] as String,
                orElse: () => AbilityType.strength,
              )
            : null,
        createdAt: (data['createdAt'] as String?),
        status: (data['status'] as String?) ?? 'open',
        audience: (data['audience'] as String?) ?? 'all',
        targetUids: targetUids,
      );
    } catch (e) {
      debugPrint('❌ Critical error parsing request $id: $e, data: $requestData');
      rethrow;
    }
  }
}




