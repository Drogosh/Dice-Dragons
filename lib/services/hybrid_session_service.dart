import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter/foundation.dart';
import '../models/session.dart';
import '../models/request.dart';
import '../models/character.dart';
import 'firebase_realtime_database_service.dart';
import 'dart:math';

/// Гибридный сервис сессий: использует RTDB с резервной копией на Firestore
class HybridSessionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final fb.FirebaseAuth _auth = fb.FirebaseAuth.instance;
  final FirebaseRealtimeDatabaseService _rtdb;

  static const String _sessionsCollection = 'sessions';
  static const String _membersSubcollection = 'members';
  static const String _requestsSubcollection = 'requests';

  HybridSessionService(this._rtdb);

  /// Генерировать уникальный код присоединения (6 символов)
  String _generateJoinCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    return List.generate(6, (index) => chars[random.nextInt(chars.length)])
        .join();
  }

  /// Проверить, существует ли сессия с таким кодом
  Future<bool> _joinCodeExists(String joinCode) async {
    try {
      final query = await _firestore
          .collection(_sessionsCollection)
          .where('joinCode', isEqualTo: joinCode)
          .limit(1)
          .get();
      return query.docs.isNotEmpty;
    } catch (e) {
      debugPrint('❌ Error checking join code: $e');
      return false;
    }
  }

  /// Генерировать уникальный код присоединения
  Future<String> _generateUniqueJoinCode() async {
    String joinCode;
    bool exists = true;
    int attempts = 0;

    do {
      joinCode = _generateJoinCode();
      exists = await _joinCodeExists(joinCode);
      attempts++;
    } while (exists && attempts < 10);

    if (attempts >= 10) {
      throw Exception('Failed to generate unique join code');
    }

    return joinCode;
  }

  /// Создать новую сессию (DM)
  Future<Session> createSession({
    required String name,
    String? description,
    String? campaignName,
    int maxPlayers = 0,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final joinCode = await _generateUniqueJoinCode();
      final now = DateTime.now();

      final session = Session(
        id: '', // Будет установлен
        dmId: user.uid,
        name: name,
        joinCode: joinCode,
        status: SessionStatus.active,
        description: description,
        campaignName: campaignName,
        maxPlayers: maxPlayers,
        createdAt: now,
        updatedAt: now,
      );

      // Создаём документ сессии в Firestore (для резервной копии)
      final docRef = _firestore.collection(_sessionsCollection).doc();
      final sessionWithId = session.copyWith(id: docRef.id);

      // Сохраняем в Firestore
      await docRef.set(sessionWithId.toFirestore());

      // Сохраняем в RTDB (основное хранилище)
      await _rtdb.createSessionInRTDB(sessionWithId);

      // Добавляем DM как члена сессии
      await addMember(
        docRef.id,
        user.uid,
        user.displayName ?? 'DM',
        SessionRole.dm,
      );

      debugPrint('✅ Сессия создана: ${docRef.id}');
      return sessionWithId;
    } catch (e) {
      debugPrint('❌ Error creating session: $e');
      rethrow;
    }
  }

  /// Получить сессию по ID
  Future<Session?> getSession(String sessionId) async {
    try {
      // Пытаемся получить из RTDB первым (быстрее)
      final rtdbSession = await _rtdb.getSessionFromRTDB(sessionId);
      if (rtdbSession != null) {
        return rtdbSession;
      }

      // Если не найдено в RTDB, получаем из Firestore
      final firestoreSession = await _getSessionFromFirestore(sessionId);
      
      // И сохраняем в RTDB для синхронизации
      if (firestoreSession != null) {
        await _rtdb.createSessionInRTDB(firestoreSession);
      }

      return firestoreSession;
    } catch (e) {
      debugPrint('❌ Error getting session: $e');
      return null;
    }
  }

  /// Получить сессию из Firestore с членами
  Future<Session?> _getSessionFromFirestore(String sessionId) async {
    try {
      final doc = await _firestore
          .collection(_sessionsCollection)
          .doc(sessionId)
          .get();

      if (!doc.exists) return null;

      // Получить членов
      final membersSnapshot = await _firestore
          .collection(_sessionsCollection)
          .doc(sessionId)
          .collection(_membersSubcollection)
          .get();

      final members = <String, SessionMember>{};
      for (final memberDoc in membersSnapshot.docs) {
        members[memberDoc.id] = SessionMember.fromMap(
          memberDoc.id,
          memberDoc.data(),
        );
      }

      return Session.fromFirestore(doc, members: members);
    } catch (e) {
      debugPrint('❌ Error getting session from Firestore: $e');
      return null;
    }
  }

  /// Watch все сессии текущего пользователя
  Stream<List<Session>> watchUserSessions() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value([]);

    return _rtdb.watchUserSessions(user.uid);
  }

  /// Watch одну сессию
  Stream<Session?> watchSession(String sessionId) {
    return _rtdb.watchSession(sessionId);
  }

  /// Watch членов сессии
  Stream<List<SessionMember>> watchMembers(String sessionId) {
    return _rtdb
        .watchSessionMembers(sessionId)
        .map((membersMap) => membersMap.values.toList());
  }

  /// Добавить члена в сессию
  Future<void> addMember(
    String sessionId,
    String uid,
    String displayName,
    SessionRole role,
  ) async {
    try {
      // Добавляем в RTDB
      await _rtdb.addSessionMember(sessionId, uid, displayName, role);

      // Также добавляем в Firestore для резервной копии
      await _firestore
          .collection(_sessionsCollection)
          .doc(sessionId)
          .collection(_membersSubcollection)
          .doc(uid)
          .set({
        'uid': uid,
        'role': role.name,
        'displayName': displayName,
        'joinedAt': Timestamp.now(),
      });

      debugPrint('✅ Member added: $displayName');
    } catch (e) {
      debugPrint('❌ Error adding member: $e');
      rethrow;
    }
  }

  /// Удалить члена из сессии
  Future<void> removeMember(String sessionId, String uid) async {
    try {
      await _rtdb.removeSessionMember(sessionId, uid);

      // Также удаляем из Firestore
      await _firestore
          .collection(_sessionsCollection)
          .doc(sessionId)
          .collection(_membersSubcollection)
          .doc(uid)
          .delete();

      debugPrint('✅ Member removed: $uid');
    } catch (e) {
      debugPrint('❌ Error removing member: $e');
      rethrow;
    }
  }

  /// Обновить статус сессии
  Future<void> updateSessionStatus(String sessionId, SessionStatus status) async {
    try {
      await _rtdb.updateSessionStatus(sessionId, status);

      // Также обновляем в Firestore
      await _firestore
          .collection(_sessionsCollection)
          .doc(sessionId)
          .update({'status': status.name});

      debugPrint('✅ Session status updated to ${status.name}');
    } catch (e) {
      debugPrint('❌ Error updating session status: $e');
      rethrow;
    }
  }

  /// Удалить сессию
  Future<void> deleteSession(String sessionId) async {
    try {
      // Удаляем из RTDB
      await _rtdb.deleteSession(sessionId);

      // Удаляем из Firestore
      final collRef = _firestore.collection(_sessionsCollection).doc(sessionId);
      
      // Удаляем все подколлекции
      final membersSnapshot = await collRef.collection(_membersSubcollection).get();
      for (final doc in membersSnapshot.docs) {
        await doc.reference.delete();
      }

      final requestsSnapshot = await collRef.collection(_requestsSubcollection).get();
      for (final doc in requestsSnapshot.docs) {
        await doc.reference.delete();
      }

      // Удаляем сам документ
      await collRef.delete();

      debugPrint('✅ Session deleted: $sessionId');
    } catch (e) {
      debugPrint('❌ Error deleting session: $e');
      rethrow;
    }
  }

  /// Создать запрос
  Future<void> createRequest({
    required String sessionId,
    required Character character,
    required RequestType type,
    required String baseFormula,
    int? targetAc,
    String? note,
    String? abilityType,
    required String audience,
    required List<String> targetUids,
  }) async {
    try {
      final requestId = _firestore
          .collection('dummy')
          .doc()
          .id; // Генерируем ID

      final now = DateTime.now();
      final request = Request(
        id: requestId,
        characterId: character.id,
        characterName: character.name,
        type: type,
        formula: baseFormula,
        targetAc: targetAc,
        note: note,
        status: 'open',
        audience: audience,
        targetUids: targetUids,
        createdAt: now,
      );

      // Сохраняем в RTDB
      await _rtdb.createRequest(
        sessionId: sessionId,
        requestId: requestId,
        request: request,
      );

      // Также сохраняем в Firestore
      await _firestore
          .collection(_sessionsCollection)
          .doc(sessionId)
          .collection(_requestsSubcollection)
          .doc(requestId)
          .set({
        'characterId': character.id,
        'characterName': character.name,
        'type': type.name,
        'formula': baseFormula,
        'targetAc': targetAc,
        'note': note,
        'status': 'open',
        'audience': audience,
        'targetUids': targetUids,
        'createdAt': Timestamp.fromDate(now),
      });

      debugPrint('✅ Request created: $requestId');
    } catch (e) {
      debugPrint('❌ Error creating request: $e');
      rethrow;
    }
  }

  /// Получить запросы сессии
  Future<List<Request>> getRequests(String sessionId) async {
    try {
      final snapshot = await _firestore
          .collection(_sessionsCollection)
          .doc(sessionId)
          .collection(_requestsSubcollection)
          .get();

      return snapshot.docs
          .map((doc) => _parseRequestFromFirestore(doc.id, doc.data()))
          .toList();
    } catch (e) {
      debugPrint('❌ Error getting requests: $e');
      return [];
    }
  }

  /// Watch запросы сессии
  Stream<List<Request>> watchRequests(String sessionId) {
    return _rtdb.watchSessionRequests(sessionId);
  }

  /// Закрыть запрос
  Future<void> closeRequest(String sessionId, String requestId) async {
    try {
      await _rtdb.closeRequest(sessionId, requestId);

      // Также обновляем в Firestore
      await _firestore
          .collection(_sessionsCollection)
          .doc(sessionId)
          .collection(_requestsSubcollection)
          .doc(requestId)
          .update({
        'status': 'closed',
        'completedAt': Timestamp.now(),
      });

      debugPrint('✅ Request closed: $requestId');
    } catch (e) {
      debugPrint('❌ Error closing request: $e');
      rethrow;
    }
  }

  /// Парсер запроса из Firestore
  Request _parseRequestFromFirestore(String id, Map<String, dynamic> data) {
    return Request(
      id: id,
      characterId: data['characterId'],
      characterName: data['characterName'] ?? '',
      type: RequestType.values.firstWhere(
        (t) => t.name == data['type'],
        orElse: () => RequestType.skill,
      ),
      formula: data['formula'] ?? '',
      targetAc: data['targetAc'],
      note: data['note'],
      status: data['status'] ?? 'open',
      audience: data['audience'] ?? 'all',
      targetUids: List<String>.from(data['targetUids'] ?? []),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      completedAt: (data['completedAt'] as Timestamp?)?.toDate(),
      result: data['result'],
    );
  }
}

