enum ItemType {
  weapon,
  armor,
  accessory,
  consumable,
  miscellaneous,
}

enum DamageType {
  slashing,     // Рубящий
  piercing,     // Колющий
  bludgeoning,  // Дробящий
  fire,         // Огонь
  cold,         // Холод
  lightning,    // Молния
  poison,       // Яд
  psychic,      // Психический
  radiant,      // Лучистый
  necrotic,     // Некротический
  force,        // Силовое поле
}

enum ArmorType {
  light,   // Легкая броня
  medium,  // Средняя броня
  heavy,   // Тяжелая броня
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
}

