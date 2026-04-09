import 'package:hive/hive.dart';

part 'item.g.dart';

@HiveType(typeId: 0)
enum ItemType {
  @HiveField(0)
  weapon,
  @HiveField(1)
  armor,
  @HiveField(2)
  accessory,
  @HiveField(3)
  consumable,
  @HiveField(4)
  miscellaneous,
}

@HiveType(typeId: 1)
enum DamageType {
  @HiveField(0)
  slashing,     // Рубящий
  @HiveField(1)
  piercing,     // Колющий
  @HiveField(2)
  bludgeoning,  // Дробящий
  @HiveField(3)
  fire,         // Огонь
  @HiveField(4)
  cold,         // Холод
  @HiveField(5)
  lightning,    // Молния
  @HiveField(6)
  poison,       // Яд
  @HiveField(7)
  psychic,      // Психический
  @HiveField(8)
  radiant,      // Лучистый
  @HiveField(9)
  necrotic,     // Некротический
  @HiveField(10)
  force,        // Силовое поле
}

@HiveType(typeId: 2)
enum ArmorType {
  @HiveField(0)
  light,   // Легкая броня
  @HiveField(1)
  medium,  // Средняя броня
  @HiveField(2)
  heavy,   // Тяжелая броня
  @HiveField(3)
  shield,  // Щит
}

class Item {
  String name;
  ItemType type;
  String description;
  int bonus; // Бонус к атаке, броне и т.д.

  // Поля для оружия
  String? damage;       // Например: "1d8" или "2d6"
  DamageType? damageType;

  // Поля для брони
  int? armorClass;
  ArmorType? armorType;

  Item({
    required this.name,
    required this.type,
    required this.description,
    this.bonus = 0,
    this.damage,
    this.damageType,
    this.armorClass,
    this.armorType,
  });

  // Для сериализации/десериализации
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'type': type.toString(),
      'description': description,
      'bonus': bonus,
      'damage': damage,
      'damageType': damageType?.toString(),
      'armorClass': armorClass,
      'armorType': armorType?.toString(),
    };
  }

  factory Item.fromMap(Map<String, dynamic> map) {
    return Item(
      name: map['name'] as String,
      type: ItemType.values.firstWhere(
        (e) => e.toString() == map['type'],
        orElse: () => ItemType.miscellaneous,
      ),
      description: map['description'] as String,
      bonus: map['bonus'] as int? ?? 0,
      damage: map['damage'] as String?,
      damageType: map['damageType'] != null
          ? DamageType.values.firstWhere(
              (e) => e.toString() == map['damageType'],
              orElse: () => DamageType.slashing,
            )
          : null,
      armorClass: map['armorClass'] as int?,
      armorType: map['armorType'] != null
          ? ArmorType.values.firstWhere(
              (e) => e.toString() == map['armorType'],
              orElse: () => ArmorType.light,
            )
          : null,
    );
  }

  @override
  String toString() {
    return 'Item: $name (Type: ${type.name}, Bonus: $bonus)';
  }

  /// Создать копию предмета
  Item copy() {
    return Item(
      name: name,
      type: type,
      description: description,
      bonus: bonus,
      damage: damage,
      damageType: damageType,
      armorClass: armorClass,
      armorType: armorType,
    );
  }
}

