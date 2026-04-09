class Race {
  final String id;
  final String name;
  final String description;
  final bool isStandard; // true для стандартных рас, false для пользовательских

  // Бонусы к характеристикам
  final int strengthBonus;
  final int dexterityBonus;
  final int constitutionBonus;
  final int intelligenceBonus;
  final int wisdomBonus;
  final int charismaBonus;

  Race({
    required this.id,
    required this.name,
    required this.description,
    this.isStandard = true,
    this.strengthBonus = 0,
    this.dexterityBonus = 0,
    this.constitutionBonus = 0,
    this.intelligenceBonus = 0,
    this.wisdomBonus = 0,
    this.charismaBonus = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'isStandard': isStandard,
      'strengthBonus': strengthBonus,
      'dexterityBonus': dexterityBonus,
      'constitutionBonus': constitutionBonus,
      'intelligenceBonus': intelligenceBonus,
      'wisdomBonus': wisdomBonus,
      'charismaBonus': charismaBonus,
    };
  }

  factory Race.fromMap(Map<String, dynamic> map) {
    return Race(
      id: map['id'] as String,
      name: map['name'] as String,
      description: map['description'] as String,
      isStandard: map['isStandard'] as bool? ?? true,
      strengthBonus: map['strengthBonus'] as int? ?? 0,
      dexterityBonus: map['dexterityBonus'] as int? ?? 0,
      constitutionBonus: map['constitutionBonus'] as int? ?? 0,
      intelligenceBonus: map['intelligenceBonus'] as int? ?? 0,
      wisdomBonus: map['wisdomBonus'] as int? ?? 0,
      charismaBonus: map['charismaBonus'] as int? ?? 0,
    );
  }

  Race copyWith({
    String? id,
    String? name,
    String? description,
    bool? isStandard,
    int? strengthBonus,
    int? dexterityBonus,
    int? constitutionBonus,
    int? intelligenceBonus,
    int? wisdomBonus,
    int? charismaBonus,
  }) {
    return Race(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      isStandard: isStandard ?? this.isStandard,
      strengthBonus: strengthBonus ?? this.strengthBonus,
      dexterityBonus: dexterityBonus ?? this.dexterityBonus,
      constitutionBonus: constitutionBonus ?? this.constitutionBonus,
      intelligenceBonus: intelligenceBonus ?? this.intelligenceBonus,
      wisdomBonus: wisdomBonus ?? this.wisdomBonus,
      charismaBonus: charismaBonus ?? this.charismaBonus,
    );
  }
}

/// Стандартные расы D&D 5e
final standardRaces = [
  Race(
    id: 'dragonborn',
    name: 'Драконорождённый',
    description: 'Потомки драконов, обладающие силой и харизмой',
    isStandard: true,
    strengthBonus: 2,
    charismaBonus: 1,
  ),
  Race(
    id: 'dwarf',
    name: 'Гном',
    description: 'Коротышки, известные своей стойкостью и боевым мастерством',
    isStandard: true,
    constitutionBonus: 2,
    wisdomBonus: 1,
  ),
  Race(
    id: 'elf',
    name: 'Эльф',
    description: 'Грациозные и долгоживущие существа с острым умом',
    isStandard: true,
    dexterityBonus: 2,
    intelligenceBonus: 1,
  ),
  Race(
    id: 'gnome',
    name: 'Лесной гном',
    description: 'Маленькие изобретатели, известные своей хитростью',
    isStandard: true,
    intelligenceBonus: 2,
    dexterityBonus: 1,
  ),
  Race(
    id: 'halfling',
    name: 'Полурослик',
    description: 'Маленькие, удачливые и ловкие существа',
    isStandard: true,
    dexterityBonus: 2,
    charismaBonus: 1,
  ),
  Race(
    id: 'human',
    name: 'Человек',
    description: 'Универсальные и амбициозные существа',
    isStandard: true,
    strengthBonus: 1,
    dexterityBonus: 1,
    constitutionBonus: 1,
    intelligenceBonus: 1,
    wisdomBonus: 1,
    charismaBonus: 1,
  ),
  Race(
    id: 'tiefling',
    name: 'Тифлинг',
    description: 'Обладатели инфернального происхождения с магической силой',
    isStandard: true,
    intelligenceBonus: 1,
    charismaBonus: 2,
  ),
];

