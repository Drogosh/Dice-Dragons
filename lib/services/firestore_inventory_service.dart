import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Сервис для работы с инвентарем и надетыми предметами в Firestore
class FirestoreInventoryService {
  static final FirestoreInventoryService _instance = FirestoreInventoryService._internal();
  late final FirebaseFirestore _firestore;

  factory FirestoreInventoryService() {
    return _instance;
  }

  FirestoreInventoryService._internal() {
    _firestore = FirebaseFirestore.instance;
  }

  /// Сохранить инвентарь персонажа
  Future<void> saveInventory(
    String userId,
    String charId,
    Map<String, dynamic> inventoryData,
  ) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('characters')
          .doc(charId)
          .collection('inventory')
          .doc('data')
          .set(inventoryData, SetOptions(merge: true));
      debugPrint('✅ Инвентарь сохранен в Firestore');
    } catch (e) {
      debugPrint('❌ Ошибка сохранения инвентаря: $e');
      throw 'Ошибка сохранения инвентаря: $e';
    }
  }

  /// Загрузить инвентарь персонажа
  Future<Map<String, dynamic>?> getInventory(String userId, String charId) async {
    try {
      final doc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('characters')
          .doc(charId)
          .collection('inventory')
          .doc('data')
          .get();
      return doc.data();
    } catch (e) {
      debugPrint('❌ Ошибка загрузки инвентаря: $e');
      throw 'Ошибка загрузки инвентаря: $e';
    }
  }

  /// Слушать инвентарь в реальном времени
  Stream<Map<String, dynamic>?> getInventoryStream(String userId, String charId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('characters')
        .doc(charId)
        .collection('inventory')
        .doc('data')
        .snapshots()
        .map((doc) => doc.exists ? doc.data() : null);
  }

  /// Сохранить надетые предметы
  Future<void> saveEquippedItems(
    String userId,
    String charId,
    Map<String, dynamic> equippedData,
  ) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('characters')
          .doc(charId)
          .collection('equipped')
          .doc('current')
          .set(equippedData, SetOptions(merge: true));
      debugPrint('✅ Надетые предметы сохранены в Firestore');
    } catch (e) {
      debugPrint('❌ Ошибка сохранения надетых предметов: $e');
      throw 'Ошибка сохранения надетых предметов: $e';
    }
  }

  /// Загрузить надетые предметы
  Future<Map<String, dynamic>?> getEquippedItems(String userId, String charId) async {
    try {
      final doc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('characters')
          .doc(charId)
          .collection('equipped')
          .doc('current')
          .get();
      return doc.data();
    } catch (e) {
      debugPrint('❌ Ошибка загрузки надетых предметов: $e');
      throw 'Ошибка загрузки надетых предметов: $e';
    }
  }

  /// Слушать надетые предметы в реальном времени
  Stream<Map<String, dynamic>?> getEquippedItemsStream(String userId, String charId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('characters')
        .doc(charId)
        .collection('equipped')
        .doc('current')
        .snapshots()
        .map((doc) => doc.exists ? doc.data() : null);
  }
}

