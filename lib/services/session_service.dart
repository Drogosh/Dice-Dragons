import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter/foundation.dart';
import 'dart:async';
import 'dart:math';
import '../models/session.dart';
import '../models/request.dart';
import '../models/character.dart';

class SessionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final fb.FirebaseAuth _auth = fb.FirebaseAuth.instance;

  static const String _sessionsCollection = 'sessions';
  static const String _membersSubcollection = 'members';
  static const String _requestsSubcollection = 'requests';

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
        id: '', // Будет установлен Firestore
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

      // Создаём документ сессии
      final docRef = _firestore.collection(_sessionsCollection).doc();
      final sessionWithId = session.copyWith(id: docRef.id);

      // Сохраняем сессию
      await docRef.set(sessionWithId.toFirestore());

      // Добавляем DM как члена сессии
      await _addMember(
        docRef.id,
        user.uid,
        user.displayName ?? 'DM',
        SessionRole.dm,
      );

      debugPrint('✅ Session created: ${docRef.id}');
      return sessionWithId;
    } catch (e) {
      debugPrint('❌ Error creating session: $e');
      rethrow;
    }
  }

  /// Присоединиться к сессии по коду
  Future<Session> joinSessionByCode(
    String joinCode, {
    String? characterId,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Найти сессию по коду
      final query = await _firestore
          .collection(_sessionsCollection)
          .where('joinCode', isEqualTo: joinCode)
          .where('status', isEqualTo: 'active')
          .limit(1)
          .get();

      if (query.docs.isEmpty) {
        throw Exception('Session not found');
      }

      final sessionDoc = query.docs.first;
      final sessionId = sessionDoc.id;
      final sessionData = sessionDoc.data();

      // Проверить, есть ли свободные места
      final memberCount = await _getMemberCount(sessionId);
      final maxPlayers = sessionData['maxPlayers'] as int? ?? 0;

      if (maxPlayers > 0 && memberCount >= maxPlayers) {
        throw Exception('Session is full');
      }

      // Проверить, не участвует ли уже пользователь
      final existingMember = await _firestore
          .collection(_sessionsCollection)
          .doc(sessionId)
          .collection(_membersSubcollection)
          .doc(user.uid)
          .get();

      if (existingMember.exists) {
        throw Exception('Already in this session');
      }

      // Добавить как игрока
      await _addMember(
        sessionId,
        user.uid,
        user.displayName ?? 'Player',
        SessionRole.player,
        characterId: characterId,
      );

      // Загрузить и вернуть сессию
      return getSessions(sessionId);
    } catch (e) {
      debugPrint('❌ Error joining session: $e');
      rethrow;
    }
  }

  /// Добавить члена сессии
  Future<void> _addMember(
    String sessionId,
    String uid,
    String displayName,
    SessionRole role, {
    String? characterId,
  }) async {
    try {
      final member = SessionMember(
        uid: uid,
        role: role,
        displayName: displayName,
        characterId: characterId,
      );

      await _firestore
          .collection(_sessionsCollection)
          .doc(sessionId)
          .collection(_membersSubcollection)
          .doc(uid)
          .set(member.toMap());

      // Обновить updatedAt сессии
      await _firestore
          .collection(_sessionsCollection)
          .doc(sessionId)
          .update({
        'updatedAt': Timestamp.now(),
      });

      debugPrint('✅ Member added: $uid to session: $sessionId');
    } catch (e) {
      debugPrint('❌ Error adding member: $e');
      rethrow;
    }
  }

  /// Получить сессию по ID
  Future<Session> getSessions(String sessionId) async {
    try {
      final sessionDoc = await _firestore
          .collection(_sessionsCollection)
          .doc(sessionId)
          .get();

      if (!sessionDoc.exists) {
        throw Exception('Session not found');
      }

      // Загрузить членов
      final membersQuery = await _firestore
          .collection(_sessionsCollection)
          .doc(sessionId)
          .collection(_membersSubcollection)
          .get();

      final members = <String, SessionMember>{};
      for (final memberDoc in membersQuery.docs) {
        final member = SessionMember.fromMap(memberDoc.id, memberDoc.data());
        members[memberDoc.id] = member;
      }

      return Session.fromFirestore(sessionDoc, members: members);
    } catch (e) {
      debugPrint('❌ Error getting session: $e');
      rethrow;
    }
  }

  /// Получить сессии, где пользователь является участником
  Future<List<Session>> getUserSessions() async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Найти все сессии, где пользователь является членом
      final memberQuery = await _firestore
          .collectionGroup(_membersSubcollection)
          .where(FieldPath.documentId, isEqualTo: user.uid)
          .get();

      final sessions = <Session>[];

      for (final memberDoc in memberQuery.docs) {
        final sessionRef = memberDoc.reference.parent.parent;
        if (sessionRef == null) continue;

        final sessionDoc = await sessionRef.get();
        if (!sessionDoc.exists) continue;

        // Загрузить членов сессии
        final membersQuery = await sessionRef
            .collection(_membersSubcollection)
            .get();

        final members = <String, SessionMember>{};
        for (final md in membersQuery.docs) {
          final member = SessionMember.fromMap(md.id, md.data());
          members[md.id] = member;
        }

        final session =
            Session.fromFirestore(sessionDoc, members: members);
        sessions.add(session);
      }

      return sessions;
    } catch (e) {
      debugPrint('❌ Error getting user sessions: $e');
      return [];
    }
  }

  /// Получить сессии, управляемые пользователем (DM)
  Future<List<Session>> getDMSessions() async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final query = await _firestore
          .collection(_sessionsCollection)
          .where('dmId', isEqualTo: user.uid)
          .get();

      final sessions = <Session>[];

      for (final sessionDoc in query.docs) {
        // Загрузить членов
        final membersQuery = await sessionDoc.reference
            .collection(_membersSubcollection)
            .get();

        final members = <String, SessionMember>{};
        for (final memberDoc in membersQuery.docs) {
          final member = SessionMember.fromMap(memberDoc.id, memberDoc.data());
          members[memberDoc.id] = member;
        }

        final session = Session.fromFirestore(sessionDoc, members: members);
        sessions.add(session);
      }

      return sessions;
    } catch (e) {
      debugPrint('❌ Error getting DM sessions: $e');
      return [];
    }
  }

  /// Получить количество членов сессии
  Future<int> _getMemberCount(String sessionId) async {
    try {
      final query = await _firestore
          .collection(_sessionsCollection)
          .doc(sessionId)
          .collection(_membersSubcollection)
          .count()
          .get();

      return query.count ?? 0;
    } catch (e) {
      debugPrint('❌ Error getting member count: $e');
      return 0;
    }
  }

  /// Обновить сессию (только DM)
  Future<void> updateSession(
    String sessionId, {
    String? name,
    String? description,
    SessionStatus? status,
    String? campaignName,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Проверить, что пользователь - DM
      final sessionDoc =
          await _firestore.collection(_sessionsCollection).doc(sessionId).get();
      final sessionData = sessionDoc.data();
      if (sessionData?['dmId'] != user.uid) {
        throw Exception('Only DM can update session');
      }

      final updates = <String, dynamic>{
        'updatedAt': Timestamp.now(),
      };

      if (name != null) updates['name'] = name;
      if (description != null) updates['description'] = description;
      if (status != null) updates['status'] = status.name;
      if (campaignName != null) updates['campaignName'] = campaignName;

      await _firestore
          .collection(_sessionsCollection)
          .doc(sessionId)
          .update(updates);

      debugPrint('✅ Session updated: $sessionId');
    } catch (e) {
      debugPrint('❌ Error updating session: $e');
      rethrow;
    }
  }

  /// Удалить сессию (только DM)
  Future<void> deleteSession(String sessionId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Проверить, что пользователь - DM
      final sessionDoc =
          await _firestore.collection(_sessionsCollection).doc(sessionId).get();
      final sessionData = sessionDoc.data();
      if (sessionData?['dmId'] != user.uid) {
        throw Exception('Only DM can delete session');
      }

      // Удалить всех членов
      final membersQuery = await _firestore
          .collection(_sessionsCollection)
          .doc(sessionId)
          .collection(_membersSubcollection)
          .get();

      for (final memberDoc in membersQuery.docs) {
        await memberDoc.reference.delete();
      }

      // Удалить саму сессию
      await _firestore.collection(_sessionsCollection).doc(sessionId).delete();

      debugPrint('✅ Session deleted: $sessionId');
    } catch (e) {
      debugPrint('❌ Error deleting session: $e');
      rethrow;
    }
  }

  /// Покинуть сессию
  Future<void> leaveSession(String sessionId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Удалить члена
      await _firestore
          .collection(_sessionsCollection)
          .doc(sessionId)
          .collection(_membersSubcollection)
          .doc(user.uid)
          .delete();

      // Обновить updatedAt
      await _firestore
          .collection(_sessionsCollection)
          .doc(sessionId)
          .update({
        'updatedAt': Timestamp.now(),
      });

      debugPrint('✅ Left session: $sessionId');
    } catch (e) {
      debugPrint('❌ Error leaving session: $e');
      rethrow;
    }
  }

  /// Слушать изменения сессии + членов в реальном времени (truly real-time)
  Stream<Session?> watchSession(String sessionId) {
    // Два независимых stream-а
    final sessionDocStream = _firestore
        .collection(_sessionsCollection)
        .doc(sessionId)
        .snapshots();

    final membersStream = _firestore
        .collection(_sessionsCollection)
        .doc(sessionId)
        .collection(_membersSubcollection)
        .snapshots();

    // Комбинируем stream-ы используя StreamController
    late StreamController<Session?> controller;
    Session? _lastSession;
    Map<String, SessionMember>? _lastMembers;

    void _emitCombined() {
      if (_lastSession != null && _lastMembers != null) {
        final combined = _lastSession!.copyWith(members: _lastMembers!);
        controller.add(combined);
      }
    }

    controller = StreamController<Session?>(
      onListen: () {
        // Слушаем session doc
        final sessionSub = sessionDocStream.listen((sessionDoc) {
          if (!sessionDoc.exists) {
            _lastSession = null;
            controller.add(null);
            return;
          }

          _lastSession = Session.fromFirestore(sessionDoc, members: _lastMembers ?? {});
          debugPrint('📄 Session doc updated for $sessionId');
          _emitCombined();
        }, onError: (e) {
          debugPrint('❌ Error watching session doc: $e');
          controller.addError(e);
        });

        // Слушаем members subcollection
        final membersSub = membersStream.listen((membersQuery) {
          final members = <String, SessionMember>{};
          for (final memberDoc in membersQuery.docs) {
            final member = SessionMember.fromMap(memberDoc.id, memberDoc.data());
            members[memberDoc.id] = member;
          }

          _lastMembers = members;
          debugPrint('👥 Members updated for $sessionId: ${members.length} members');
          _emitCombined();
        }, onError: (e) {
          debugPrint('❌ Error watching members: $e');
          controller.addError(e);
        });

        controller.onCancel = () {
          sessionSub.cancel();
          membersSub.cancel();
        };
      },
    );

    return controller.stream;
  }

   /// Слушать членов сессии в реальном времени
   Stream<List<SessionMember>> watchMembers(String sessionId) {
     return _firestore
         .collection(_sessionsCollection)
         .doc(sessionId)
         .collection(_membersSubcollection)
         .snapshots()
         .map((query) {
       return query.docs
           .map((doc) => SessionMember.fromMap(doc.id, doc.data()))
           .toList();
     });
   }

   /// Создать запрос с автоматическим расчетом модификатора
   Future<Request> createRequest({
     required String sessionId,
     required Character character,
     required RequestType type,
     required String baseFormula,
     int? targetAc,
     String? note,
     AbilityType? abilityType,
     String audience = 'all',
     List<String> targetUids = const [],
   }) async {
     try {
       final user = _auth.currentUser;
       if (user == null) throw Exception('User not authenticated');

       // Создаем запрос с автоматическим расчетом модификатора
       final request = Request.createWithAutoModifier(
         sessionId: sessionId,
         dmId: user.uid,
         character: character,
         type: type,
         baseFormula: baseFormula,
         targetAc: targetAc,
         note: note,
         abilityType: abilityType,
       );

       // Добавляем audience и targetUids
       final requestWithAudience = request.copyWith(
         audience: audience,
         targetUids: targetUids,
       );

       // Сохраняем в Firestore
       final docRef = _firestore
           .collection(_sessionsCollection)
           .doc(sessionId)
           .collection(_requestsSubcollection)
           .doc();

       final requestWithId = requestWithAudience.copyWith(id: docRef.id);

       await docRef.set(requestWithId.toMap());

       debugPrint('✅ Request created: ${request.type.toString()} with modifier: ${request.modifier}');
       return requestWithId;
     } catch (e) {
       debugPrint('❌ Error creating request: $e');
       rethrow;
     }
   }

   /// Получить запросы сессии
   Future<List<Request>> getRequests(String sessionId) async {
     try {
       final query = await _firestore
           .collection(_sessionsCollection)
           .doc(sessionId)
           .collection(_requestsSubcollection)
           .orderBy('createdAt', descending: true)
           .get();

       final requests = <Request>[];
       for (final doc in query.docs) {
         try {
           requests.add(Request.fromMap(doc.data()));
         } catch (e) {
           debugPrint('⚠️  Error parsing request: $e');
         }
       }

       return requests;
     } catch (e) {
       debugPrint('❌ Error getting requests: $e');
       return [];
     }
   }

   /// Слушать запросы в реальном времени
   Stream<List<Request>> watchRequests(String sessionId) {
     return _firestore
         .collection(_sessionsCollection)
         .doc(sessionId)
         .collection(_requestsSubcollection)
         .orderBy('createdAt', descending: true)
         .snapshots()
         .map((query) {
       return query.docs
           .map((doc) {
             try {
               return Request.fromMap(doc.data());
             } catch (e) {
               debugPrint('⚠️  Error parsing request: $e');
               return null;
             }
           })
           .whereType<Request>()
           .toList();
     });
   }

   /// Закрыть запрос
   Future<void> closeRequest(String sessionId, String requestId) async {
     try {
       await _firestore
           .collection(_sessionsCollection)
           .doc(sessionId)
           .collection(_requestsSubcollection)
           .doc(requestId)
           .update({'status': 'closed'});

       debugPrint('✅ Request closed: $requestId');
     } catch (e) {
       debugPrint('❌ Error closing request: $e');
       rethrow;
     }
   }

   /// Удалить запрос
   Future<void> deleteRequest(String sessionId, String requestId) async {
     try {
       await _firestore
           .collection(_sessionsCollection)
           .doc(sessionId)
           .collection(_requestsSubcollection)
           .doc(requestId)
           .delete();

       debugPrint('✅ Request deleted: $requestId');
     } catch (e) {
       debugPrint('❌ Error deleting request: $e');
       rethrow;
     }
   }
 }


