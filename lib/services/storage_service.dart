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
    try {
      print('💾 StorageService.saveInventory ВЫЗВАН');
      print('   characterName: $characterName');
      print('   items: ${inventory.getItemCount()}');
      
      final box = await inventoryBox;
      print('   ✓ Box открыт');
      
      final jsonString = inventory.toJsonString();
      print('   ✓ JSON создан: ${jsonString.length} символов');
      
      await box.put(characterName, jsonString);
      print('   ✅ СОХРАНЕНО В HIVE!');
    } catch (e) {
      print('   ❌ ОШИБКА СОХРАНЕНИЯ: $e');
    }
  }

  // Загрузить инвентарь
  static Future<Inventory?> loadInventory(String characterName) async {
    try {
      print('📖 StorageService.loadInventory ВЫЗВАН');
      print('   characterName: $characterName');
      
      final box = await inventoryBox;
      print('   ✓ Box открыт');
      
      final json = box.get(characterName);
      if (json != null) {
        print('   ✓ JSON найден: ${json.length} символов');
        final inventory = Inventory.fromJsonString(json);
        print('   ✅ ЗАГРУЖЕНО: ${inventory.getItemCount()} предметов');
        return inventory;
      } else {
        print('   ℹ️  JSON не найден для $characterName');
        print('   Доступные ключи: ${box.keys.toList()}');
        return null;
      }
    } catch (e) {
      print('   ❌ ОШИБКА ЗАГРУЗКИ: $e');
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
       print('💾 StorageService.saveItemDatabase ВЫЗВАН');
       print('   items: ${database.getItemCount()}');
       
       final box = await itemDatabaseBox;
       print('   ✓ Box открыт');
       
       final jsonString = database.toJsonString();
       print('   ✓ JSON создан: ${jsonString.length} символов');
       
       await box.put('items', jsonString);
       print('   ✅ СОХРАНЕНО В HIVE!');
     } catch (e) {
       print('   ❌ ОШИБКА СОХРАНЕНИЯ: $e');
     }
   }

   /// Загрузить базу предметов
   static Future<void> loadItemDatabase(ItemDatabase database) async {
     try {
       print('📖 StorageService.loadItemDatabase ВЫЗВАН');
       
       final box = await itemDatabaseBox;
       print('   ✓ Box открыт');
       
       final json = box.get('items');
       if (json != null) {
         print('   ✓ JSON найден: ${json.length} символов');
         database.fromJsonString(json);
         print('   ✅ ЗАГРУЖЕНО: ${database.getItemCount()} предметов');
       } else {
         print('   ℹ️  База предметов еще не сохранялась (используются по умолчанию)');
       }
     } catch (e) {
       print('   ❌ ОШИБКА ЗАГРУЗКИ: $e');
     }
   }
 }

