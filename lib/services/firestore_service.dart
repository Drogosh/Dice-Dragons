import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/character.dart';

class FirestoreService {
  static final FirestoreService _instance = FirestoreService._internal();
  late final FirebaseFirestore _firestore;

  factory FirestoreService() {
    return _instance;
  }

  FirestoreService._internal() {
    _firestore = FirebaseFirestore.instance;
  }

  // ==================== ПЕРСОНАЖИ ====================

   /// Сохранить персонажа в Firestore
  Future<String> saveCharacter(String userId, Character character) async {
    try {
      // Если персонаж уже имеет ID - обновляем его
      if (character.id != null) {
        await updateCharacter(userId, character.id!, character);
        return character.id!;
      }

      // Иначе создаем новый документ
      final docRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('characters')
          .doc();

      await docRef.set({
        'id': docRef.id,
        'name': character.name,
        'level': character.level,
        'hp': character.hp,
        'ac': character.ac,
        'strength': character.strength,
        'dexterity': character.dexterity,
        'constitution': character.constitution,
        'intelligence': character.intelligence,
        'wisdom': character.wisdom,
        'charisma': character.charisma,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return docRef.id;
    } catch (e) {
      throw 'Ошибка сохранения персонажа: $e';
    }
  }

  /// Получить все персонажей пользователя
  Future<List<Character>> getUserCharacters(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('characters')
          .get();

      return querySnapshot.docs
          .map((doc) => Character.fromMap({
                ...doc.data(),
                'id': doc.id,
              }))
          .toList();
    } catch (e) {
      throw 'Ошибка получения персонажей: $e';
    }
  }

  /// Получить персонажа по ID
  Future<Character?> getCharacterById(String userId, String charId) async {
    try {
      final doc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('characters')
          .doc(charId)
          .get();

      if (doc.exists) {
        return Character.fromMap({
          ...doc.data() ?? {},
          'id': doc.id,
        });
      }
      return null;
    } catch (e) {
      throw 'Ошибка получения персонажа: $e';
    }
  }

   /// Обновить персонажа
  Future<void> updateCharacter(String userId, String charId, Character character) async {
    try {
      // Сохраняем профессиональности навыков
      Map<String, bool> skillProficiencies = {};
      character.skills.forEach((skill, modifier) {
        skillProficiencies[skill.toString()] = modifier.isProficient;
      });

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('characters')
          .doc(charId)
          .update({
        'name': character.name,
        'level': character.level,
        'hp': character.hp,
        'ac': character.ac,
        'strength': character.strength,
        'dexterity': character.dexterity,
        'constitution': character.constitution,
        'intelligence': character.intelligence,
        'wisdom': character.wisdom,
        'charisma': character.charisma,
        'skillProficiencies': skillProficiencies,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw 'Ошибка обновления персонажа: $e';
    }
  }

  /// Удалить персонажа
  Future<void> deleteCharacter(String userId, String charId) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('characters')
          .doc(charId)
          .delete();
    } catch (e) {
      throw 'Ошибка удаления персонажа: $e';
    }
  }

  // ==================== СЕССИИ ====================

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

      return docRef.id;
    } catch (e) {
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
      throw 'Ошибка получения сессий: $e';
    }
  }

  /// Добавить игрока в сессию
  Future<void> addPlayerToSession(String sessionId, String userId) async {
    try {
      await _firestore.collection('sessions').doc(sessionId).update({
        'players': FieldValue.arrayUnion([userId]),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
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
    } catch (e) {
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
    } catch (e) {
      throw 'Ошибка завершения сессии: $e';
    }
  }

  // ==================== СЛУШАТЕЛИ (Real-time updates) ====================

  /// Слушать сессию в реальном времени
  Stream<Map<String, dynamic>?> getSessionStream(String sessionId) {
    return _firestore.collection('sessions').doc(sessionId).snapshots().map(
      (doc) => doc.exists ? doc.data() : null,
    );
  }

   /// Слушать персонажей пользователя в реальном времени
   Stream<List<Character>> getUserCharactersStream(String userId) {
     return _firestore
         .collection('users')
         .doc(userId)
         .collection('characters')
         .snapshots()
         .map(
           (querySnapshot) => querySnapshot.docs
               .map((doc) => Character.fromMap({
                     ...doc.data(),
                     'id': doc.id,
                   }))
               .toList(),
         );
   }

  // ==================== ИНВЕНТАРЬ ====================

  /// Сохранить инвентарь персонажа
  Future<void> saveInventory(String userId, String charId, Map<String, dynamic> inventoryData) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('characters')
          .doc(charId)
          .collection('inventory')
          .doc('data')
          .set(inventoryData, SetOptions(merge: true));
    } catch (e) {
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
  Future<void> saveEquippedItems(String userId, String charId, Map<String, dynamic> equippedData) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('characters')
          .doc(charId)
          .collection('equipped')
          .doc('current')
          .set(equippedData, SetOptions(merge: true));
    } catch (e) {
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

