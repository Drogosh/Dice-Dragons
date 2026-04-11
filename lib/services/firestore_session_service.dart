import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Сервис для работы с сессиями в Firestore
class FirestoreSessionService {
  static final FirestoreSessionService _instance = FirestoreSessionService._internal();
  late final FirebaseFirestore _firestore;

  factory FirestoreSessionService() {
    return _instance;
  }

  FirestoreSessionService._internal() {
    _firestore = FirebaseFirestore.instance;
  }

  /// Создать игровую сессию (только для DM)
  Future<String> createSession(String dmId, String sessionName) async {
    try {
      final docRef = _firestore.collection('sessions').doc();

      await docRef.set({
        'id': docRef.id,
        'dmId': dmId,
        'name': sessionName,
        'players': [],
        'status': 'active',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      debugPrint('✅ Сессия создана: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      debugPrint('❌ Ошибка создания сессии: $e');
      throw 'Ошибка создания сессии: $e';
    }
  }

  /// Получить сессию по ID
  Future<Map<String, dynamic>?> getSession(String sessionId) async {
    try {
      final doc = await _firestore.collection('sessions').doc(sessionId).get();

      if (doc.exists) {
        return doc.data();
      }
      return null;
    } catch (e) {
      debugPrint('❌ Ошибка получения сессии: $e');
      throw 'Ошибка получения сессии: $e';
    }
  }

  /// Получить все сессии DM
  Future<List<Map<String, dynamic>>> getDMSessions(String dmId) async {
    try {
      final querySnapshot = await _firestore
          .collection('sessions')
          .where('dmId', isEqualTo: dmId)
          .get();

      return querySnapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      debugPrint('❌ Ошибка получения сессий DM: $e');
      throw 'Ошибка получения сессий DM: $e';
    }
  }

  /// Добавить игрока в сессию
  Future<void> addPlayerToSession(String sessionId, String userId) async {
    try {
      await _firestore.collection('sessions').doc(sessionId).update({
        'players': FieldValue.arrayUnion([userId]),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      debugPrint('✅ Игрок добавлен в сессию');
    } catch (e) {
      debugPrint('❌ Ошибка добавления игрока: $e');
      throw 'Ошибка добавления игрока: $e';
    }
  }

  /// Удалить игрока из сессии
  Future<void> removePlayerFromSession(String sessionId, String userId) async {
    try {
      await _firestore.collection('sessions').doc(sessionId).update({
        'players': FieldValue.arrayRemove([userId]),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      debugPrint('✅ Игрок удален из сессии');
    } catch (e) {
      debugPrint('❌ Ошибка удаления игрока: $e');
      throw 'Ошибка удаления игрока: $e';
    }
  }

  /// Завершить сессию
  Future<void> endSession(String sessionId) async {
    try {
      await _firestore.collection('sessions').doc(sessionId).update({
        'status': 'ended',
        'updatedAt': FieldValue.serverTimestamp(),
      });
      debugPrint('✅ Сессия завершена');
    } catch (e) {
      debugPrint('❌ Ошибка завершения сессии: $e');
      throw 'Ошибка завершения сессии: $e';
    }
  }

  /// Слушать сессию в реальном времени
  Stream<Map<String, dynamic>?> getSessionStream(String sessionId) {
    return _firestore.collection('sessions').doc(sessionId).snapshots().map(
      (doc) => doc.exists ? doc.data() : null,
    );
  }
}

