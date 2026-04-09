import 'package:hive_flutter/hive_flutter.dart';
import '../models/character.dart';
import '../models/inventory.dart';

class StorageService {
  static const String _characterBoxName = 'characters';
  static const String _inventoryBoxName = 'inventories';

  // Получить Box для персонажей
  static Future<Box<String>> get characterBox async {
    return await Hive.openBox<String>(_characterBoxName);
  }

  // Получить Box для инвентарей
  static Future<Box<String>> get inventoryBox async {
    return await Hive.openBox<String>(_inventoryBoxName);
  }

  // Сохранить персонажа
  static Future<void> saveCharacter(Character character) async {
    final box = await characterBox;
    await box.put(character.name, character.toJsonString());
  }

  // Загрузить персонажа по имени
  static Future<Character?> loadCharacter(String name) async {
    final box = await characterBox;
    final json = box.get(name);
    if (json != null) {
      return Character.fromJsonString(json);
    }
    return null;
  }

  // Получить все персонажей
  static Future<List<Character>> getAllCharacters() async {
    final box = await characterBox;
    final characters = <Character>[];
    for (final json in box.values) {
      characters.add(Character.fromJsonString(json));
    }
    return characters;
  }

  // Удалить персонажа
  static Future<void> deleteCharacter(String name) async {
    final box = await characterBox;
    await box.delete(name);
  }

  // Сохранить инвентарь
  static Future<void> saveInventory(String characterName, Inventory inventory) async {
    final box = await inventoryBox;
    await box.put(characterName, inventory.toJsonString());
  }

  // Загрузить инвентарь
  static Future<Inventory?> loadInventory(String characterName) async {
    final box = await inventoryBox;
    final json = box.get(characterName);
    if (json != null) {
      return Inventory.fromJsonString(json);
    }
    return null;
  }

  // Очистить все данные
  static Future<void> clearAll() async {
    final charBox = await characterBox;
    final invBox = await inventoryBox;
    await charBox.clear();
    await invBox.clear();
  }
}

