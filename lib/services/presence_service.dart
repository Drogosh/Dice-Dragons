import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter/foundation.dart';

/// Статус онлайн участника
class PresenceStatus {
  final String uid;
  final bool online;
  final DateTime lastSeen;

  PresenceStatus({
    required this.uid,
    required this.online,
    required this.lastSeen,
  });

  factory PresenceStatus.fromMap(String uid, Map<dynamic, dynamic> map) {
    return PresenceStatus(
      uid: uid,
      online: (map['online'] ?? false) as bool,
      lastSeen: DateTime.fromMillisecondsSinceEpoch(
        (map['lastSeen'] ?? DateTime.now().millisecondsSinceEpoch) as int,
      ),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'online': online,
      'lastSeen': ServerValue.timestamp,
    };
  }

  @override
  String toString() =>
      'PresenceStatus(uid: $uid, online: $online, lastSeen: $lastSeen)';
}

/// Сервис для управления присутствием (presence) участников в сессии
class PresenceService {
  final FirebaseDatabase _database = FirebaseDatabase.instance;
  final fb.FirebaseAuth _auth = fb.FirebaseAuth.instance;

  static const String _liveSessionsPath = 'liveSessions';
  static const String _presencePath = 'presence';

  /// Войти в сессию (установить online=true)
  Future<void> enterSession(String sessionId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final presenceRef = _database
          .ref()
          .child(_liveSessionsPath)
          .child(sessionId)
          .child(_presencePath)
          .child(user.uid);

      // Устанавливаем presence как online
      await presenceRef.set({
        'online': true,
        'lastSeen': ServerValue.timestamp,
      });

      // Устанавливаем обработчик onDisconnect
      // Когда клиент потеряет соединение, автоматически установится offline
      await presenceRef.onDisconnect().set({
        'online': false,
        'lastSeen': ServerValue.timestamp,
      });

      debugPrint('✅ Entered session: $sessionId');
    } catch (e) {
      debugPrint('❌ Error entering session: $e');
      rethrow;
    }
  }

  /// Покинуть сессию (установить online=false)
  Future<void> leaveSession(String sessionId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final presenceRef = _database
          .ref()
          .child(_liveSessionsPath)
          .child(sessionId)
          .child(_presencePath)
          .child(user.uid);

      // Отменить onDisconnect если был установлен
      await presenceRef.onDisconnect().cancel();

      // Установить offline
      await presenceRef.set({
        'online': false,
        'lastSeen': ServerValue.timestamp,
      });

      debugPrint('✅ Left session: $sessionId');
    } catch (e) {
      debugPrint('❌ Error leaving session: $e');
      rethrow;
    }
  }

  /// Слушать список активных участников в реальном времени
  Stream<List<PresenceStatus>> watchPresence(String sessionId) {
    return _database
        .ref()
        .child(_liveSessionsPath)
        .child(sessionId)
        .child(_presencePath)
        .onValue
        .map((event) {
      final presenceList = <PresenceStatus>[];

      if (event.snapshot.value is Map) {
        final presenceMap = event.snapshot.value as Map<dynamic, dynamic>;
        presenceMap.forEach((uid, data) {
          if (data is Map<dynamic, dynamic>) {
            presenceList.add(PresenceStatus.fromMap(uid as String, data));
          }
        });
      }

      return presenceList;
    });
  }

  /// Получить статус одного участника
  Future<PresenceStatus?> getPresence(String sessionId, String uid) async {
    try {
      final snapshot = await _database
          .ref()
          .child(_liveSessionsPath)
          .child(sessionId)
          .child(_presencePath)
          .child(uid)
          .get();

      if (!snapshot.exists) return null;

      final data = snapshot.value as Map<dynamic, dynamic>;
      return PresenceStatus.fromMap(uid, data);
    } catch (e) {
      debugPrint('❌ Error getting presence: $e');
      return null;
    }
  }

  /// Получить список всех участников с их статусом присутствия
  Future<List<PresenceStatus>> getAllPresence(String sessionId) async {
    try {
      final snapshot = await _database
          .ref()
          .child(_liveSessionsPath)
          .child(sessionId)
          .child(_presencePath)
          .get();

      final presenceList = <PresenceStatus>[];

      if (snapshot.value is Map) {
        final presenceMap = snapshot.value as Map<dynamic, dynamic>;
        presenceMap.forEach((uid, data) {
          if (data is Map<dynamic, dynamic>) {
            presenceList.add(PresenceStatus.fromMap(uid as String, data));
          }
        });
      }

      return presenceList;
    } catch (e) {
      debugPrint('❌ Error getting all presence: $e');
      return [];
    }
  }

  /// Проверить если участник онлайн
  bool isOnline(PresenceStatus status) => status.online;

  /// Получить время последнего видения
  String getLastSeenText(DateTime lastSeen) {
    final now = DateTime.now();
    final difference = now.difference(lastSeen);

    if (difference.inSeconds < 60) {
      return 'Только что';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} мин назад';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} ч назад';
    } else {
      return '${lastSeen.day}.${lastSeen.month}.${lastSeen.year}';
    }
  }
}

