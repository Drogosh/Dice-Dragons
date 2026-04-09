class CharacterClass {
  final String id;
  final String name;
  final String description;
  final int hitDice; // d6, d8, d10, d12 (число после d)
  final String primaryAbility; // STR, DEX, INT, WIS, CHA

  CharacterClass({
    required this.id,
    required this.name,
    required this.description,
    required this.hitDice,
    required this.primaryAbility,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'hitDice': hitDice,
      'primaryAbility': primaryAbility,
    };
  }

  factory CharacterClass.fromMap(Map<String, dynamic> map) {
    return CharacterClass(
      id: map['id'] as String,
      name: map['name'] as String,
      description: map['description'] as String,
      hitDice: map['hitDice'] as int,
      primaryAbility: map['primaryAbility'] as String,
    );
  }
}

/// Стандартные классы D&D 5e
final standardClasses = [
  CharacterClass(
    id: 'barbarian',
    name: 'Варвар',
    description: 'Воины первобытной ярости, впадающие в боевой транс',
    hitDice: 12,
    primaryAbility: 'STR',
  ),
  CharacterClass(
    id: 'bard',
    name: 'Бард',
    description: 'Музыканты и артисты, использующие магию музыки',
    hitDice: 8,
    primaryAbility: 'CHA',
  ),
  CharacterClass(
    id: 'cleric',
    name: 'Клирик',
    description: 'Святые воины, черпающие мощь из божественного источника',
    hitDice: 8,
    primaryAbility: 'WIS',
  ),
  CharacterClass(
    id: 'druid',
    name: 'Друид',
    description: 'Хранители природы, способные превращаться в животных',
    hitDice: 8,
    primaryAbility: 'WIS',
  ),
  CharacterClass(
    id: 'fighter',
    name: 'Боец',
    description: 'Опытные воины, мастера боевого искусства',
    hitDice: 10,
    primaryAbility: 'STR',
  ),
  CharacterClass(
    id: 'monk',
    name: 'Монах',
    description: 'Эксперты боевых искусств, обладающие внутренней силой',
    hitDice: 8,
    primaryAbility: 'DEX',
  ),
  CharacterClass(
    id: 'paladin',
    name: 'Паладин',
    description: 'Святые рыцари, связанные священной клятвой',
    hitDice: 10,
    primaryAbility: 'STR',
  ),
  CharacterClass(
    id: 'ranger',
    name: 'Рейнджер',
    description: 'Охотники и следопыты, связанные с природой',
    hitDice: 10,
    primaryAbility: 'DEX',
  ),
  CharacterClass(
    id: 'rogue',
    name: 'Плут',
    description: 'Ловкие преступники и мастера скрытности',
    hitDice: 8,
    primaryAbility: 'DEX',
  ),
  CharacterClass(
    id: 'sorcerer',
    name: 'Чародей',
    description: 'Маги с врождённой магической силой',
    hitDice: 6,
    primaryAbility: 'CHA',
  ),
  CharacterClass(
    id: 'warlock',
    name: 'Чернокнижник',
    description: 'Колдуны, заключившие сделки с могущественными сущностями',
    hitDice: 8,
    primaryAbility: 'CHA',
  ),
  CharacterClass(
    id: 'wizard',
    name: 'Волшебник',
    description: 'Учёные маги, овладевшие магией через знания',
    hitDice: 6,
    primaryAbility: 'INT',
  ),
];

