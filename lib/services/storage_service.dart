import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/character.dart';
import '../models/inventory.dart';
import '../models/item_database.dart';

class StorageService {
  static const String _characterBoxName = 'characters';
  static const String _inventoryBoxName = 'inventories';
  static const String _itemDatabaseBoxName = 'item_database';

  // Получить Box для персонажей
  static Future<Box<String>> get characterBox async {
    return await Hive.openBox<String>(_characterBoxName);
  }

  // Получить Box для инвентарей
  static Future<Box<String>> get inventoryBox async {
    return await Hive.openBox<String>(_inventoryBoxName);
  }

  // Получить Box для базы предметов
  static Future<Box<String>> get itemDatabaseBox async {
    return await Hive.openBox<String>(_itemDatabaseBoxName);
  }

  // Сохранить персонажа (использует стабильный ID вместо имени)
  static Future<void> saveCharacter(Character character) async {
    final box = await characterBox;
    final characterId = character.id ?? character.name;
    await box.put(characterId, character.toJsonString());
    debugPrint('✅ Персонаж сохранён локально с ID: $characterId');
  }

  // Загрузить персонажа по ID (или имени для обратной совместимости)
  static Future<Character?> loadCharacter(String characterId) async {
    final box = await characterBox;
    final json = box.get(characterId);
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

  // Сохранить инвентарь (использует стабильный ID)
  static Future<void> saveInventory(String characterId, Inventory inventory) async {
    try {
      debugPrint('💾 StorageService.saveInventory ВЫЗВАН');
      debugPrint('   characterId: $characterId');
      debugPrint('   items: ${inventory.getItemCount()}');

      final box = await inventoryBox;
      debugPrint('   ✓ Box открыт');

      final jsonString = inventory.toJsonString();
      debugPrint('   ✓ JSON создан: ${jsonString.length} символов');

      await box.put(characterId, jsonString);
      debugPrint('   ✅ СОХРАНЕНО В HIVE!');
    } catch (e) {
      debugPrint('   ❌ ОШИБКА СОХРАНЕНИЯ: $e');
    }
  }

  // Загрузить инвентарь
  static Future<Inventory?> loadInventory(String characterId) async {
    try {
      debugPrint('📖 StorageService.loadInventory ВЫЗВАН');
      debugPrint('   characterId: $characterId');

      final box = await inventoryBox;
      debugPrint('   ✓ Box открыт');

      final json = box.get(characterId);
      if (json != null) {
        debugPrint('   ✓ JSON найден: ${json.length} символов');
        final inventory = Inventory.fromJsonString(json);
        debugPrint('   ✅ ЗАГРУЖЕНО: ${inventory.getItemCount()} предметов');
        return inventory;
      } else {
        debugPrint('   ℹ️  JSON не найден для $characterId');
        debugPrint('   Доступные ключи: ${box.keys.toList()}');
        return null;
      }
    } catch (e) {
      debugPrint('   ❌ ОШИБКА ЗАГРУЗКИ: $e');
      return null;
    }
  }

   // Очистить все данные
   static Future<void> clearAll() async {
     final charBox = await characterBox;
     final invBox = await inventoryBox;
     final dbBox = await itemDatabaseBox;
     await charBox.clear();
     await invBox.clear();
     await dbBox.clear();
   }

   // ==================== БАЗА ПРЕДМЕТОВ ====================

    /// Сохранить базу предметов
    static Future<void> saveItemDatabase(ItemDatabase database) async {
      try {
        debugPrint('💾 StorageService.saveItemDatabase ВЫЗВАН');
        debugPrint('   items: ${database.getItemCount()}');

        final box = await itemDatabaseBox;
        debugPrint('   ✓ Box открыт');

        final jsonString = database.toJsonString();
        debugPrint('   ✓ JSON создан: ${jsonString.length} символов');

        await box.put('items', jsonString);
        debugPrint('   ✅ СОХРАНЕНО В HIVE!');
      } catch (e) {
        debugPrint('   ❌ ОШИБКА СОХРАНЕНИЯ: $e');
      }
    }

    /// Загрузить базу предметов
    static Future<void> loadItemDatabase(ItemDatabase database) async {
      try {
        debugPrint('📖 StorageService.loadItemDatabase ВЫЗВАН');

        final box = await itemDatabaseBox;
        debugPrint('   ✓ Box открыт');

        final json = box.get('items');
        if (json != null) {
          debugPrint('   ✓ JSON найден: ${json.length} символов');
          database.fromJsonString(json);
          debugPrint('   ✅ ЗАГРУЖЕНО: ${database.getItemCount()} предметов');
        } else {
          debugPrint('   ℹ️  База предметов еще не сохранялась (используются по умолчанию)');
        }
      } catch (e) {
        debugPrint('   ❌ ОШИБКА ЗАГРУЗКИ: $e');
      }
    }
 }

