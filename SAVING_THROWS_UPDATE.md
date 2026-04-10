# 🎲 Обновление: Спасброски и улучшение виджетов характеристик

## Что было добавлено

### 1. **Спасброски (Saving Throws)**
Добавлены поля и методы расчета спасбросков для каждой характеристики:

#### Новые поля в `Character`:
```dart
bool strengthSaveProficiency = false;
bool dexteritySaveProficiency = false;
bool constitutionSaveProficiency = false;
bool intelligenceSaveProficiency = false;
bool wisdomSaveProficiency = false;
bool charismaSaveProficiency = false;
```

#### Методы расчета спасбросков:
```dart
int getStrengthSave() => modifier + (proficiency ? bonus : 0);
int getDexteritySave() => modifier + (proficiency ? bonus : 0);
int getConstitutionSave() => modifier + (proficiency ? bonus : 0);
int getIntelligenceSave() => modifier + (proficiency ? bonus : 0);
int getWisdomSave() => modifier + (proficiency ? bonus : 0);
int getCharismaSave() => modifier + (proficiency ? bonus : 0);
```

Спасброски рассчитываются как:
- **Базовое значение** = модификатор характеристики
- **С мастерством** = модификатор + бонус мастерства

### 2. **Новый виджет AbilityCard**
Создан виджет `lib/widgets/ability_card.dart` для отображения характеристик с фоновыми изображениями.

**Особенности:**
- Размер: 59x162 px
- Показывает:
  - Основную характеристику (x=21, y=18, размер 16pt)
  - Модификатор (x=15, y=29, размер 25pt)
  - Спасбросок (x=20, y=93, размер 16pt)
- Поддерживает выделение (isSelected)
- Обработка тапа (onTap callback)

### 3. **Фоновые изображения**
Созданы 6 фоновых изображений для каждой характеристики:
- `ability_str.png` - Красный (Сила)
- `ability_dex.png` - Синий (Ловкость)
- `ability_con.png` - Зеленый (Телосложение)
- `ability_int.png` - Фиолетовый (Интеллект)
- `ability_wis.png` - Оранжевый (Мудрость)
- `ability_cha.png` - Розовый (Харизма)

### 4. **Обновления файлов**

#### `character.dart`
- Добавлены поля спасбросков
- Добавлены методы расчета спасбросков
- Обновлены методы `toMap()` и `fromMap()` для сохранения спасбросков

#### `character_screen.dart`
- Заменены виджеты `StatCard` на новые `AbilityCard`
- Импорт изменён с `stat_card.dart` на `ability_card.dart`
- GridView настроен на новые размеры (59x162)

#### `pubspec.yaml`
- Добавлены все новые изображения в раздел `assets`

## Использование

### Как показать спасбросок персонажа:
```dart
// Получить спасбросок Силы с мастерством
final strSave = character.getStrengthSave();

// Получить спасбросок Ловкости
final dexSave = character.getDexteritySave();
```

### Как установить мастерство в спасброске:
```dart
character.strengthSaveProficiency = true;
character.dexteritySaveProficiency = true;
// и т.д.
```

### Использование AbilityCard:
```dart
AbilityCard(
  backgroundAsset: 'assets/images/ability_str.png',
  abilityScore: 18,
  modifier: 4,
  savingThrow: 7,  // 4 (модификатор) + 3 (бонус мастерства)
  isSelected: false,
  onTap: () { /* обработка */ },
)
```

## Файлы, которые были изменены
- ✅ `lib/models/character.dart` - спасброски и методы
- ✅ `lib/screens/character_screen.dart` - замена виджетов
- ✅ `lib/widgets/ability_card.dart` - новый виджет
- ✅ `pubspec.yaml` - добавлены изображения

## Файлы, которые были добавлены
- ✅ `lib/widgets/ability_card.dart`
- ✅ `assets/images/ability_str.png`
- ✅ `assets/images/ability_dex.png`
- ✅ `assets/images/ability_con.png`
- ✅ `assets/images/ability_int.png`
- ✅ `assets/images/ability_wis.png`
- ✅ `assets/images/ability_cha.png`
- ✅ `create_ability_backgrounds.py` - скрипт создания фонов

## Следующие шаги
1. Добавить UI для редактирования спасбросков (мастерства)
2. Добавить отображение спасбросков в других экранах
3. Улучшить фоновые изображения (добавить текстуры, эффекты)
4. Добавить звуки при нажатии на характеристики

---
**Дата:** 2026-04-10
**Статус:** ✅ Завершено и закоммичено

