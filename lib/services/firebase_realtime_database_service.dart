import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter/foundation.dart';
import '../models/session.dart';
import '../models/request.dart';
import 'dart:convert';

/// Сервис для работы с Firebase Real-time Database
class FirebaseRealtimeDatabaseService {
  final FirebaseDatabase _database = FirebaseDatabase.instance;
  final fb.FirebaseAuth _auth = fb.FirebaseAuth.instance;

  // Пути в RTDB
  static const String _sessionsPath = 'sessions';
  static const String _sessionsMetaPath = 'sessions_metadata';
  static const String _requestsPath = 'requests';
  static const String _presencePath = 'presence';

  /// Инициализация RTDB
  Future<void> initialize() async {
    try {
      // Включить persistent caching
      await _database.setPersistenceEnabled(true);
      // Установить размер кэша (10 MB)
      await _database.setPersistenceCacheSizeBytes(10 * 1024 * 1024);
      debugPrint('✅ Firebase Realtime Database инициализирована');
    } catch (e) {
      debugPrint('❌ Ошибка инициализации RTDB: $e');
    }
  }

  // ============ СЕССИИ ============

  /// Создать новую сессию в RTDB
  Future<void> createSessionInRTDB(Session session) async {
    try {
      final ref = _database.ref('$_sessionsPath/${session.id}');

      final sessionData = {
        'id': session.id,
        'dmId': session.dmId,
        'name': session.name,
        'joinCode': session.joinCode,
        'status': session.status.name,
        'description': session.description,
        'campaignName': session.campaignName,
        'maxPlayers': session.maxPlayers,
        'createdAt': session.createdAt.millisecondsSinceEpoch,
        'updatedAt': session.updatedAt.millisecondsSinceEpoch,
        'members': session.members.isEmpty
          ? {}
          : session.members.map((uid, member) => MapEntry(
            uid,
            {
              'uid': uid,
              'role': member.role.name,
              'displayName': member.displayName,
              'characterId': member.characterId,
              'joinedAt': member.joinedAt.millisecondsSinceEpoch,
            },
          )),
      };

      await ref.set(sessionData);
      debugPrint('✅ Сессия ${session.id} создана в RTDB');
    } catch (e) {
      debugPrint('❌ Ошибка создания сессии в RTDB: $e');
      rethrow;
    }
  }

  /// Получить сессию по ID из RTDB
  Future<Session?> getSessionFromRTDB(String sessionId) async {
    try {
      final ref = _database.ref('$_sessionsPath/$sessionId');
      final snapshot = await ref.get();

      if (!snapshot.exists) {
        return null;
      }

      return _parseSession(sessionId, snapshot.value as Map);
    } catch (e) {
      debugPrint('❌ Ошибка получения сессии из RTDB: $e');
      return null;
    }
  }

  /// Stream всех сессий текущего пользователя
  Stream<List<Session>> watchUserSessions(String userId) {
    return _database
        .ref(_sessionsPath)
        .onValue
        .map((event) {
          if (!event.snapshot.exists) {
            return [];
          }

          final data = event.snapshot.value as Map?;
          if (data == null) return [];

          return data.entries
              .map((e) {
                try {
                  return _parseSession(e.key, e.value as Map);
                } catch (err) {
                  debugPrint('❌ Ошибка парсинга сессии: $err');
                  return null;
                }
              })
              .whereType<Session>()
              .where((session) =>
                  session.dmId == userId ||
                  session.members.containsKey(userId))
              .toList();
        });
  }

  /// Stream одной сессии
  Stream<Session?> watchSession(String sessionId) {
    return _database
        .ref('$_sessionsPath/$sessionId')
        .onValue
        .map((event) {
          if (!event.snapshot.exists) {
            return null;
          }
          try {
            return _parseSession(sessionId, event.snapshot.value as Map);
          } catch (e) {
            debugPrint('❌ Ошибка парсинга сессии: $e');
            return null;
          }
        });
  }

  /// Обновить статус сессии
  Future<void> updateSessionStatus(String sessionId, SessionStatus status) async {
    try {
      await _database
          .ref('$_sessionsPath/$sessionId/status')
          .set(status.name);
      debugPrint('✅ Статус сессии обновлен');
    } catch (e) {
      debugPrint('❌ Ошибка обновления статуса сессии: $e');
      rethrow;
    }
  }

  /// Удалить сессию
  Future<void> deleteSession(String sessionId) async {
    try {
      await _database.ref('$_sessionsPath/$sessionId').remove();
      debugPrint('✅ Сессия удалена');
    } catch (e) {
      debugPrint('❌ Ошибка удаления сессии: $e');
      rethrow;
    }
  }

  // ============ ЧЛЕНЫ СЕССИИ ============

  /// Добавить члена в сессию
  Future<void> addSessionMember(
    String sessionId,
    String uid,
    String displayName,
    SessionRole role,
  ) async {
    try {
      final ref = _database.ref('$_sessionsPath/$sessionId/members/$uid');

      await ref.set({
        'uid': uid,
        'role': role.name,
        'displayName': displayName,
        'joinedAt': DateTime.now().millisecondsSinceEpoch,
      });

      // Обновить updatedAt сессии
      await _database
          .ref('$_sessionsPath/$sessionId/updatedAt')
          .set(DateTime.now().millisecondsSinceEpoch);

      debugPrint('✅ Член добавлен в сессию');
    } catch (e) {
      debugPrint('❌ Ошибка добавления члена в сессию: $e');
      rethrow;
    }
  }

  /// Удалить члена из сессии
  Future<void> removeSessionMember(String sessionId, String uid) async {
    try {
      await _database.ref('$_sessionsPath/$sessionId/members/$uid').remove();

      // Обновить updatedAt сессии
      await _database
          .ref('$_sessionsPath/$sessionId/updatedAt')
          .set(DateTime.now().millisecondsSinceEpoch);

      debugPrint('✅ Член удален из сессии');
    } catch (e) {
      debugPrint('❌ Ошибка удаления члена из сессии: $e');
      rethrow;
    }
  }

  /// Stream членов сессии
  Stream<Map<String, SessionMember>> watchSessionMembers(String sessionId) {
    return _database
        .ref('$_sessionsPath/$sessionId/members')
        .onValue
        .map((event) {
          if (!event.snapshot.exists) {
            return {};
          }

          final data = event.snapshot.value as Map?;
          if (data == null) return {};

          return Map.fromEntries(
            data.entries.map((e) {
              final memberData = e.value as Map;
              return MapEntry(
                e.key,
                SessionMember(
                  uid: e.key,
                  role: SessionRole.values.firstWhere(
                    (r) => r.name == memberData['role'],
                    orElse: () => SessionRole.player,
                  ),
                  displayName: memberData['displayName'] ?? 'Unknown',
                  characterId: memberData['characterId'],
                  joinedAt: DateTime.fromMillisecondsSinceEpoch(
                    memberData['joinedAt'] ?? 0,
                  ),
                ),
              );
            }),
          );
        });
  }

  // ============ ЗАПРОСЫ (REQUESTS) ============

  /// Создать новый запрос
  Future<void> createRequest({
    required String sessionId,
    required String requestId,
    required Request request,
  }) async {
    try {
      final ref = _database.ref('$_requestsPath/$sessionId/$requestId');

      final requestData = {
        'id': requestId,
        'characterId': request.characterId,
        'characterName': request.characterName,
        'type': request.type.name,
        'formula': request.formula,
        'targetAc': request.targetAc,
        'note': request.note,
        'status': request.status,
        'audience': request.audience,
        'targetUids': request.targetUids,
        'createdAt': request.createdAt.millisecondsSinceEpoch,
        'completedAt': request.completedAt?.millisecondsSinceEpoch,
        'result': request.result,
      };

      await ref.set(requestData);
      debugPrint('✅ Запрос создан в RTDB');
    } catch (e) {
      debugPrint('❌ Ошибка создания запроса: $e');
      rethrow;
    }
  }

  /// Stream запросов сессии
  Stream<List<Request>> watchSessionRequests(String sessionId) {
    return _database
        .ref('$_requestsPath/$sessionId')
        .onValue
        .map((event) {
          if (!event.snapshot.exists) {
            return [];
          }

          final data = event.snapshot.value as Map?;
          if (data == null) return [];

          return data.entries
              .map((e) {
                try {
                  return _parseRequest(e.value as Map);
                } catch (err) {
                  debugPrint('❌ Ошибка парсинга запроса: $err');
                  return null;
                }
              })
              .whereType<Request>()
              .toList();
        });
  }

  /// Обновить статус запроса
  Future<void> updateRequestStatus(
    String sessionId,
    String requestId,
    String status,
  ) async {
    try {
      await _database
          .ref('$_requestsPath/$sessionId/$requestId/status')
          .set(status);
      debugPrint('✅ Статус запроса обновлен');
    } catch (e) {
      debugPrint('❌ Ошибка обновления статуса запроса: $e');
      rethrow;
    }
  }

  /// Закрыть запрос
  Future<void> closeRequest(String sessionId, String requestId) async {
    try {
      await _database
          .ref('$_requestsPath/$sessionId/$requestId')
          .update({
        'status': 'closed',
        'completedAt': DateTime.now().millisecondsSinceEpoch,
      });
      debugPrint('✅ Запрос закрыт');
    } catch (e) {
      debugPrint('❌ Ошибка закрытия запроса: $e');
      rethrow;
    }
  }

  // ============ PRESENCE (АКТИВНОСТЬ) ============

  /// Установить статус присутствия пользователя
  Future<void> setPresence(String sessionId, String userId, bool isOnline) async {
    try {
      final ref = _database.ref('$_presencePath/$sessionId/$userId');

      if (isOnline) {
        await ref.set({
          'userId': userId,
          'lastSeen': DateTime.now().millisecondsSinceEpoch,
          'online': true,
        });
      } else {
        await ref.remove();
      }

      debugPrint('✅ Статус присутствия обновлен');
    } catch (e) {
      debugPrint('❌ Ошибка обновления статуса присутствия: $e');
    }
  }

  /// Stream присутствия в сессии
  Stream<Map<String, bool>> watchSessionPresence(String sessionId) {
    return _database
        .ref('$_presencePath/$sessionId')
        .onValue
        .map((event) {
          if (!event.snapshot.exists) {
            return {};
          }

          final data = event.snapshot.value as Map?;
          if (data == null) return {};

          return Map.fromEntries(
            data.entries.map((e) => MapEntry(e.key, true)),
          );
        });
  }

  // ============ СЛУЖЕБНЫЕ МЕТОДЫ ============

  /// Парсер сессии
  Session _parseSession(String id, Map sessionData) {
    return Session(
      id: id,
      dmId: sessionData['dmId'] ?? '',
      name: sessionData['name'] ?? 'Unknown',
      joinCode: sessionData['joinCode'] ?? '',
      status: SessionStatus.values.firstWhere(
        (s) => s.name == sessionData['status'],
        orElse: () => SessionStatus.active,
      ),
      description: sessionData['description'],
      campaignName: sessionData['campaignName'],
      maxPlayers: sessionData['maxPlayers'] ?? 0,
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        sessionData['createdAt'] ?? 0,
      ),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(
        sessionData['updatedAt'] ?? 0,
      ),
      members: _parseMembers(sessionData['members'] as Map?),
    );
  }

  /// Парсер членов сессии
  Map<String, SessionMember> _parseMembers(Map? membersData) {
    if (membersData == null || membersData.isEmpty) return {};

    return Map.fromEntries(
      membersData.entries.map((e) {
        final memberData = e.value as Map;
        return MapEntry(
          e.key,
          SessionMember(
            uid: e.key,
            role: SessionRole.values.firstWhere(
              (r) => r.name == memberData['role'],
              orElse: () => SessionRole.player,
            ),
            displayName: memberData['displayName'] ?? 'Unknown',
            characterId: memberData['characterId'],
            joinedAt: DateTime.fromMillisecondsSinceEpoch(
              memberData['joinedAt'] ?? 0,
            ),
          ),
        );
      }),
    );
  }

  /// Парсер запроса
  Request _parseRequest(Map requestData) {
    return Request(
      id: requestData['id'],
      characterId: requestData['characterId'],
      characterName: requestData['characterName'] ?? '',
      type: RequestType.values.firstWhere(
        (t) => t.name == requestData['type'],
        orElse: () => RequestType.skill,
      ),
      formula: requestData['formula'] ?? '',
      targetAc: requestData['targetAc'],
      note: requestData['note'],
      status: requestData['status'] ?? 'open',
      audience: requestData['audience'] ?? 'all',
      targetUids: List<String>.from(requestData['targetUids'] ?? []),
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        requestData['createdAt'] ?? 0,
      ),
      completedAt: requestData['completedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(requestData['completedAt'])
          : null,
      result: requestData['result'],
    );
  }
}

