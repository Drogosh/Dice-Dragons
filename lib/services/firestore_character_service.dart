import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/character.dart';

/// Сервис для работы с персонажами в Firestore
class FirestoreCharacterService {
  static final FirestoreCharacterService _instance = FirestoreCharacterService._internal();
  late final FirebaseFirestore _firestore;

  factory FirestoreCharacterService() {
    return _instance;
  }

  FirestoreCharacterService._internal() {
    _firestore = FirebaseFirestore.instance;
  }

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

      final characterData = _buildCharacterData(character);
      characterData['id'] = docRef.id;
      characterData['createdAt'] = FieldValue.serverTimestamp();
      characterData['updatedAt'] = FieldValue.serverTimestamp();

      await docRef.set(characterData);

      return docRef.id;
    } catch (e) {
      debugPrint('❌ Ошибка сохранения персонажа: $e');
      throw 'Ошибка сохранения персонажа: $e';
    }
  }

  /// Получить всех персонажей пользователя
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
      debugPrint('❌ Ошибка получения персонажей: $e');
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
      debugPrint('❌ Ошибка получения персонажа: $e');
      throw 'Ошибка получения персонажа: $e';
    }
  }

  /// Обновить персонажа
  Future<void> updateCharacter(String userId, String charId, Character character) async {
    try {
      final characterData = _buildCharacterData(character);
      characterData['updatedAt'] = FieldValue.serverTimestamp();

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('characters')
          .doc(charId)
          .update(characterData);
    } catch (e) {
      debugPrint('❌ Ошибка обновления персонажа: $e');
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
      debugPrint('❌ Ошибка удаления персонажа: $e');
      throw 'Ошибка удаления персонажа: $e';
    }
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

  /// Построить единую схему для персонажа
  Map<String, dynamic> _buildCharacterData(Character character) {
    Map<String, bool> skillProficiencies = {};
    character.skills.forEach((skill, modifier) {
      skillProficiencies[skill.toString()] = modifier.isProficient;
    });

    Map<String, dynamic> equippedItems = {};
    if (character.equippedArmor != null) {
      equippedItems['armor'] = character.equippedArmor!.toMap();
    }
    if (character.equippedShield != null) {
      equippedItems['shield'] = character.equippedShield!.toMap();
    }
    equippedItems['weapons'] = character.equippedWeapons
        .map((weapon) => weapon != null ? weapon.toMap() : null)
        .toList();

    return {
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
      'raceId': character.raceId,
      'className': character.className,
      'raceName': character.raceName,
      'classNameDisplay': character.classNameDisplay,
      'strengthSaveProficiency': character.strengthSaveProficiency,
      'dexteritySaveProficiency': character.dexteritySaveProficiency,
      'constitutionSaveProficiency': character.constitutionSaveProficiency,
      'intelligenceSaveProficiency': character.intelligenceSaveProficiency,
      'wisdomSaveProficiency': character.wisdomSaveProficiency,
      'charismaSaveProficiency': character.charismaSaveProficiency,
      'skillProficiencies': skillProficiencies,
      'equippedItems': equippedItems,
      'proficiencyBonus': character.proficiencyBonus,
    };
  }
}

