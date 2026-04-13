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
      debugPrint('🚀 createRequest START: sessionId=$sessionId dmId=$dmId');

      // Генерируем ключ ровно под нужным путем
      final requestsRef = _database.ref('$_liveSessionsPath/$sessionId/$_requestsPath');
      final newRef = requestsRef.push();
      final requestId = newRef.key;

      if (requestId == null) {
        throw Exception('Failed to generate request ID from push()');
      }

      final requestData = {
        'id': requestId,
        'sessionId': sessionId,
        'dmId': dmId,
        'characterId': request.characterId,
        'characterName': request.characterName,
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

      debugPrint('📝 createRequest payload: $requestData');

      await newRef.set(requestData);

      debugPrint('✅ createRequest SUCCESS: requestId=$requestId path=${newRef.path}');
      return requestId;
    } catch (e, stackTrace) {
      debugPrint('❌ createRequest ERROR: $e\nStackTrace: $stackTrace');
      rethrow;
    }
  }

  /// Watch все открытые запросы сессии для DM (real-time)
  Stream<List<Request>> watchDMRequests(String sessionId) {
    return _database
        .ref('$_liveSessionsPath/$sessionId/$_requestsPath')
        .onValue
        .map((event) {
          try {
            if (!event.snapshot.exists) {
              debugPrint('📭 watchDMRequests: no requests for $sessionId');
              return [];
            }

            final raw = event.snapshot.value;
            if (raw == null) {
              debugPrint('📭 watchDMRequests: snapshot.value is null for $sessionId');
              return [];
            }

            // Безопасное преобразование
            final Map<String, dynamic> map;
            try {
              map = Map<String, dynamic>.from(raw as Map);
            } catch (e) {
              debugPrint('⚠️  watchDMRequests: failed to cast raw to Map: $e');
              return [];
            }

            debugPrint('📨 watchDMRequests: got ${map.length} entries for $sessionId');

            final results = <Request>[];
            for (final entry in map.entries) {
              try {
                final req = _parseRequest(entry.key, entry.value as Map);
                if (req.status == 'open') {
                  results.add(req);
                }
              } catch (e) {
                debugPrint('⚠️  watchDMRequests: parse error for key ${entry.key}: $e');
              }
            }

            debugPrint('✅ watchDMRequests: returning ${results.length} open requests');
            return results;
          } catch (e, stackTrace) {
            debugPrint('❌ watchDMRequests ERROR: $e\nStackTrace: $stackTrace');
            return [];
          }
        });
  }

  /// Watch открытые запросы для конкретного игрока (с фильтрацией)
  Stream<List<Request>> watchPlayerRequests(
    String sessionId,
    String playerId,
    int totalPlayersCount,
  ) {
    return _database
        .ref('$_liveSessionsPath/$sessionId/$_requestsPath')
        .onValue
        .map((event) {
          try {
            if (!event.snapshot.exists) {
              debugPrint('📭 watchPlayerRequests: no requests for $sessionId/$playerId');
              return [];
            }

            final raw = event.snapshot.value;
            if (raw == null) return [];

            final Map<String, dynamic> map;
            try {
              map = Map<String, dynamic>.from(raw as Map);
            } catch (e) {
              debugPrint('⚠️  watchPlayerRequests: failed to cast: $e');
              return [];
            }

            debugPrint('📨 watchPlayerRequests: checking ${map.length} requests for player=$playerId');

            final results = <Request>[];
            for (final entry in map.entries) {
              try {
                final req = _parseRequest(entry.key, entry.value as Map);

                // Фильтруем: открытые запросы, подходящие по аудитории
                final matchAudience = req.audience == 'all' ||
                    (req.audience == 'subset' && req.targetUids.contains(playerId));

                if (req.status == 'open' && matchAudience) {
                  results.add(req);
                  debugPrint('   ✅ Request ${req.id} matches (type=${req.type.name}, audience=${req.audience})');
                }
              } catch (e) {
                debugPrint('⚠️  watchPlayerRequests: parse error for ${entry.key}: $e');
              }
            }

            debugPrint('✅ watchPlayerRequests: returning ${results.length} applicable requests');
            return results;
          } catch (e, stackTrace) {
            debugPrint('❌ watchPlayerRequests ERROR: $e\nStackTrace: $stackTrace');
            return [];
          }
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




