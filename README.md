# Dice & Dragons - D&D 5E Companion App

Flutter приложение для ведения листа персонажа в системе D&D 5e.

## 📦 Установленные зависимости

### Основные библиотеки:
- **Flutter** - фреймворк для разработки приложения
- **Material Design** - система дизайна для UI

### База данных:
- **Hive** (^2.2.3) - локальная база данных для Flutter
  - Быстрая и легкая в использовании
  - Сохраняет данные персонажей и инвентаря на устройстве
  - Не требует SQL знаний
- **hive_flutter** (^1.1.0) - интеграция Hive с Flutter
- **hive_generator** (^2.0.0) - генератор кода адаптеров для Hive
- **build_runner** (^2.4.0) - инструмент для кода генерации

## 🎮 Возможности приложения

### ✅ Реализовано:
- Лист персонажа с основными характеристиками (6 основных статов D&D)
- Модификаторы характеристик
- 18 навыков, связанных с характеристиками
- Пассивная внимательность (Passive Perception)
- Инвентарь с поддержкой:
  - Оружия (с типом и уроном)
  - Брони (с классом брони и типом)
  - Аксессуаров
  - Расходуемых предметов
  - Прочих предметов
- Навигация между 5 экранами:
  1. Характеристики и навыки
  2. Инвентарь
  3. Информация о персонаже
  4. Заклинания (заготовка)
  5. Заметки (заготовка)
- Сохранение данных с помощью Hive

## 🏗️ Архитектура

```
lib/
├── main.dart                    # Точка входа приложения
├── models/
│   ├── character.dart          # Модель персонажа
│   ├── item.dart              # Модель предмета
│   └── inventory.dart         # Модель инвентаря
├── services/
│   └── storage_service.dart   # Сервис сохранения данных в Hive
├── screens/
│   ├── character_screen.dart
│   ├── inventory_screen.dart
│   ├── info_screen.dart
│   ├── spells_screen.dart
│   ├── notes_screen.dart
│   └── main_navigation_screen.dart
└── widgets/
    ├── stat_card.dart
    └── item_card.dart
```

## 💾 Работа с Hive

Все данные сохраняются локально на устройстве в Hive базе данных.

### StorageService предоставляет методы:

```dart
// Сохранить персонажа
await StorageService.saveCharacter(character);

// Загрузить персонажа
Character? char = await StorageService.loadCharacter('имя персонажа');

// Получить всех персонажей
List<Character> characters = await StorageService.getAllCharacters();

// Удалить персонажа
await StorageService.deleteCharacter('имя персонажа');

// Сохранить инвентарь
await StorageService.saveInventory('имя персонажа', inventory);

// Загрузить инвентарь
Inventory? inv = await StorageService.loadInventory('имя персонажа');
```

## 🚀 Запуск проекта

```bash
# Загрузить зависимости
flutter pub get

# Сгенерировать адаптеры Hive
flutter pub run build_runner build

# Запустить приложение
flutter run

# Собрать APK (debug)
flutter build apk --debug

# Собрать APK (release)
flutter build apk --release
```

## 📝 Модели данных

### Character (Персонаж)
- name: String
- level: int
- hp: int (здоровье)
- ac: int (класс брони)
- strength, dexterity, constitution, intelligence, wisdom, charisma: int
- skills: Map<Skill, SkillModifier> (18 навыков)

### Item (Предмет)
- name: String
- type: ItemType (оружие, броня, аксессуар, расходуемое, прочее)
- description: String
- bonus: int
- damage: String? (для оружия, например "1d8")
- damageType: DamageType?
- armorClass: int? (для брони)
- armorType: ArmorType?

### Inventory (Инвентарь)
- items: List<Item>

## 🔧 Генерирование кода

Hive использует код генерацию для создания адаптеров enum'ов. При изменении enum'ов в `item.dart` запустите:

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

Это создаст файл `item.g.dart` с адаптерами.

