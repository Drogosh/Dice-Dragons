// QUICK START - Быстрое начало работы с Hive
// Этот файл содержит примеры и не должен анализироваться как часть основного приложения
// ignore_for_file: uri_does_not_exist, undefined_function, undefined_identifier, avoid_print

import 'models/character.dart';
import 'models/item.dart';
import 'models/inventory.dart';
import 'services/storage_service.dart';

// ========================================
// ПРИМЕР 1: Сохранить и загрузить персонажа
// ========================================
Future<void> quickStart() async {
  // Создаем персонажа
  final myCharacter = Character(
    name: 'Герой',
    level: 1,
    hp: 12,
    ac: 10,
    strength: 10,
    dexterity: 10,
    constitution: 10,
    intelligence: 10,
    wisdom: 10,
    charisma: 10,
  );

  // Сохраняем
  await StorageService.saveCharacter(myCharacter);
  print('✓ Персонаж сохранен');

  // Загружаем
  final loaded = await StorageService.loadCharacter('Герой');
  if (loaded != null) {
    print('✓ Персонаж загружен: ${loaded.name}, уровень ${loaded.level}');
  }
}

// ========================================
// ПРИМЕР 2: Работа с инвентарем
// ========================================
Future<void> quickStartInventory() async {
  // Создаем инвентарь
  final inventory = Inventory();

  // Добавляем предметы
  inventory.addItem(Item(
    name: 'Меч',
    type: ItemType.weapon,
    description: 'Острое оружие',
    damage: '1d8',
    damageType: DamageType.slashing,
    bonus: 1,
  ));

  // Сохраняем
  await StorageService.saveInventory('Герой', inventory);
  print('✓ Инвентарь сохранен');

  // Загружаем
  final loaded = await StorageService.loadInventory('Герой');
  if (loaded != null) {
    print('✓ Инвентарь загружен');
    print('✓ Предметов: ${loaded.getItemCount()}');

    for (final item in loaded.getAllItems()) {
      print('  - ${item.name}');
    }
  }
}

// ========================================
// ПРИМЕР 3: Получить всех персонажей
// ========================================
Future<void> quickStartGetAll() async {
  final characters = await StorageService.getAllCharacters();

  print('Всего персонажей: ${characters.length}');
  for (final char in characters) {
    print('- ${char.name} (уровень ${char.level}, HP: ${char.hp})');
  }
}

// ========================================
// ПРИМЕР 4: Интеграция в main()
// ========================================
/*
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'models/character.dart';
import 'models/item.dart';
import 'models/inventory.dart';

void main() async {
  // Инициализация Hive
  await Hive.initFlutter();

  // Регистрация адаптеров
  Hive.registerAdapter(ItemTypeAdapter());
  Hive.registerAdapter(DamageTypeAdapter());
  Hive.registerAdapter(ArmorTypeAdapter());

  runApp(const MyApp());
}
*/

// ========================================
// Используйте эти функции в вашем коде:
// ========================================
// await quickStart();
// await quickStartInventory();
// await quickStartGetAll();

