// Примеры использования Hive Storage Service

import 'models/character.dart';
import 'models/item.dart';
import 'models/inventory.dart';
import 'services/storage_service.dart';

// ====================
// 1. СОХРАНЕНИЕ ПЕРСОНАЖА
// ====================
Future<void> exampleSaveCharacter() async {
  // Создаем персонажа
  final character = Character(
    name: 'Артур Пенбраун',
    level: 3,
    hp: 27,
    ac: 15,
    strength: 16,
    dexterity: 14,
    constitution: 15,
    intelligence: 13,
    wisdom: 12,
    charisma: 10,
  );

  // Сохраняем его
  await StorageService.saveCharacter(character);
  print('Персонаж сохранен!');
}

// ====================
// 2. ЗАГРУЗКА ПЕРСОНАЖА
// ====================
Future<void> exampleLoadCharacter() async {
  final character = await StorageService.loadCharacter('Артур Пенбраун');

  if (character != null) {
    print('Персонаж загружен: ${character.name}, уровень ${character.level}');
  } else {
    print('Персонаж не найден');
  }
}

// ====================
// 3. ПОЛУЧИТЬ ВСЕХ ПЕРСОНАЖЕЙ
// ====================
Future<void> exampleGetAllCharacters() async {
  final characters = await StorageService.getAllCharacters();

  print('Всего персонажей: ${characters.length}');
  for (final char in characters) {
    print('- ${char.name} (уровень ${char.level})');
  }
}

// ====================
// 4. СОХРАНЕНИЕ ИНВЕНТАРЯ
// ====================
Future<void> exampleSaveInventory() async {
  // Создаем инвентарь
  final inventory = Inventory();
  inventory.addItem(Item(
    name: 'Длинный меч',
    type: ItemType.weapon,
    description: 'Классическое оружие',
    damage: '1d8',
    damageType: DamageType.slashing,
    bonus: 1,
  ));
  inventory.addItem(Item(
    name: 'Кожаная броня',
    type: ItemType.armor,
    description: 'Легкая броня',
    armorClass: 11,
    armorType: ArmorType.light,
  ));

  // Сохраняем инвентарь для персонажа
  await StorageService.saveInventory('Артур Пенбраун', inventory);
  print('Инвентарь сохранен!');
}

// ====================
// 5. ЗАГРУЗКА ИНВЕНТАРЯ
// ====================
Future<void> exampleLoadInventory() async {
  final inventory = await StorageService.loadInventory('Артур Пенбраун');

  if (inventory != null) {
    print('Инвентарь загружен!');
    print('Предметов в инвентаре: ${inventory.getItemCount()}');

    // Получить оружие
    final weapons = inventory.getWeapons();
    print('Оружие: ${weapons.map((w) => w.name).join(", ")}');

    // Получить броню
    final armor = inventory.getArmor();
    print('Броня: ${armor.map((a) => a.name).join(", ")}');
  } else {
    print('Инвентарь не найден');
  }
}

// ====================
// 6. УДАЛЕНИЕ ПЕРСОНАЖА
// ====================
Future<void> exampleDeleteCharacter() async {
  await StorageService.deleteCharacter('Артур Пенбраун');
  print('Персонаж удален!');
}

// ====================
// 7. ПОЛНЫЙ СЦЕНАРИЙ
// ====================
Future<void> exampleFullScenario() async {
  // 1. Создаем и сохраняем персонажа
  final character = Character(
    name: 'Герой',
    level: 5,
    hp: 45,
    ac: 16,
    strength: 18,
    dexterity: 14,
    constitution: 16,
    intelligence: 12,
    wisdom: 13,
    charisma: 14,
  );
  await StorageService.saveCharacter(character);
  print('✓ Персонаж создан и сохранен');

  // 2. Создаем инвентарь
  final inventory = Inventory();
  inventory.addItem(Item(
    name: 'Великий меч',
    type: ItemType.weapon,
    description: 'Мощное оружие',
    damage: '2d6',
    damageType: DamageType.slashing,
    bonus: 2,
  ));
  await StorageService.saveInventory('Герой', inventory);
  print('✓ Инвентарь сохранен');

  // 3. Загружаем данные
  final loadedChar = await StorageService.loadCharacter('Герой');
  final loadedInv = await StorageService.loadInventory('Герой');
  print('✓ Данные загружены из Hive');

  // 4. Выводим информацию
  if (loadedChar != null) {
    print('Персонаж: ${loadedChar.name}');
    print('Уровень: ${loadedChar.level}');
    print('HP: ${loadedChar.hp}');
    print('AC: ${loadedChar.ac}');
  }

  if (loadedInv != null) {
    print('Предметы в инвентаре: ${loadedInv.getItemCount()}');
    for (final item in loadedInv.getAllItems()) {
      print('  - ${item.name}');
    }
  }
}

// ====================
// ИСПОЛЬЗОВАНИЕ В main()
// ====================
/*
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Инициализация Hive
  await Hive.initFlutter();

  // Регистрация адаптеров
  Hive.registerAdapter(ItemTypeAdapter());
  Hive.registerAdapter(DamageTypeAdapter());
  Hive.registerAdapter(ArmorTypeAdapter());

  // Ваш код здесь
  await exampleFullScenario();

  runApp(const MyApp());
}
*/

