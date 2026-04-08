enum Skill {
  acrobatics,          // Ловкость - Акробатика
  animalHandling,      // Мудрость - Обращение с животными
  arcana,              // Интеллект - Магия
  athletics,           // Сила - Атлетика
  deception,           // Харизма - Обман
  history,             // Интеллект - История
  insight,             // Мудрость - Проницательность
  intimidation,        // Харизма - Запугивание
  investigation,       // Интеллект - Расследование
  medicine,            // Мудрость - Медицина
  nature,              // Интеллект - Природа
  perception,          // Мудрость - Восприятие
  performance,         // Харизма - Выступление
  persuasion,          // Харизма - Убеждение
  religion,            // Интеллект - Религия
  sleightOfHand,       // Ловкость - Ловкость рук
  stealth,             // Ловкость - Скрытность
  survival,            // Мудрость - Выживание
}

class SkillModifier {
  final Skill skill;
  final String name;
  bool isProficient;

  SkillModifier({
    required this.skill,
    required this.name,
    this.isProficient = false,
  });
}

class Character {
  String name;
  int level;
  int hp;
  int ac; // Armor Class (Класс брони)
  int proficiencyBonus = 2; // Бонус мастерства (зависит от уровня)

  // Шесть основных характеристик D&D
  int strength;      // Сила
  int dexterity;     // Ловкость
  int constitution;  // Телосложение
  int intelligence;  // Интеллект
  int wisdom;        // Мудрость
  int charisma;      // Харизма

  // Навыки
  late Map<Skill, SkillModifier> skills;

  Character({
    required this.name,
    required this.level,
    required this.hp,
    required this.ac,
    this.strength = 10,
    this.dexterity = 10,
    this.constitution = 10,
    this.intelligence = 10,
    this.wisdom = 10,
    this.charisma = 10,
  }) {
    _initializeSkills();
    _updateProficiencyBonus();
  }

  void _initializeSkills() {
    skills = {
      Skill.acrobatics: SkillModifier(skill: Skill.acrobatics, name: 'Акробатика'),
      Skill.animalHandling: SkillModifier(skill: Skill.animalHandling, name: 'Обращение с животными'),
      Skill.arcana: SkillModifier(skill: Skill.arcana, name: 'Магия'),
      Skill.athletics: SkillModifier(skill: Skill.athletics, name: 'Атлетика'),
      Skill.deception: SkillModifier(skill: Skill.deception, name: 'Обман'),
      Skill.history: SkillModifier(skill: Skill.history, name: 'История'),
      Skill.insight: SkillModifier(skill: Skill.insight, name: 'Проницательность'),
      Skill.intimidation: SkillModifier(skill: Skill.intimidation, name: 'Запугивание'),
      Skill.investigation: SkillModifier(skill: Skill.investigation, name: 'Расследование'),
      Skill.medicine: SkillModifier(skill: Skill.medicine, name: 'Медицина'),
      Skill.nature: SkillModifier(skill: Skill.nature, name: 'Природа'),
      Skill.perception: SkillModifier(skill: Skill.perception, name: 'Восприятие'),
      Skill.performance: SkillModifier(skill: Skill.performance, name: 'Выступление'),
      Skill.persuasion: SkillModifier(skill: Skill.persuasion, name: 'Убеждение'),
      Skill.religion: SkillModifier(skill: Skill.religion, name: 'Религия'),
      Skill.sleightOfHand: SkillModifier(skill: Skill.sleightOfHand, name: 'Ловкость рук'),
      Skill.stealth: SkillModifier(skill: Skill.stealth, name: 'Скрытность'),
      Skill.survival: SkillModifier(skill: Skill.survival, name: 'Выживание'),
    };
  }

  void _updateProficiencyBonus() {
    proficiencyBonus = ((level - 1) ~/ 4) + 2;
  }

  /// Получить связанную с навыком характеристику
  int _getAbilityForSkill(Skill skill) {
    switch (skill) {
      case Skill.acrobatics:
      case Skill.sleightOfHand:
      case Skill.stealth:
        return dexterity;
      case Skill.animalHandling:
      case Skill.insight:
      case Skill.medicine:
      case Skill.perception:
      case Skill.survival:
        return wisdom;
      case Skill.arcana:
      case Skill.history:
      case Skill.investigation:
      case Skill.nature:
      case Skill.religion:
        return intelligence;
      case Skill.athletics:
        return strength;
      case Skill.deception:
      case Skill.intimidation:
      case Skill.performance:
      case Skill.persuasion:
        return charisma;
    }
  }

  /// Получить бонус навыка
  int getSkillBonus(Skill skill) {
    final ability = _getAbilityForSkill(skill);
    final abilityModifier = getAbilityModifier(ability);
    final skillModifier = skills[skill]!;
    final profBonus = skillModifier.isProficient ? proficiencyBonus : 0;
    return abilityModifier + profBonus;
  }

  /// Установить мастерство навыка
  void setProficiency(Skill skill, bool isProficient) {
    skills[skill]!.isProficient = isProficient;
  }

  // Метод для получения модификатора характеристики (полезен для D&D)
  int getAbilityModifier(int abilityScore) {
    return (abilityScore - 10) ~/ 2;
  }

  // Методы для получения модификаторов каждой характеристики
  int getStrengthModifier() => getAbilityModifier(strength);
  int getDexterityModifier() => getAbilityModifier(dexterity);
  int getConstitutionModifier() => getAbilityModifier(constitution);
  int getIntelligenceModifier() => getAbilityModifier(intelligence);
  int getWisdomModifier() => getAbilityModifier(wisdom);
  int getCharismaModifier() => getAbilityModifier(charisma);

  // Для сериализации/десериализации
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'level': level,
      'hp': hp,
      'ac': ac,
      'strength': strength,
      'dexterity': dexterity,
      'constitution': constitution,
      'intelligence': intelligence,
      'wisdom': wisdom,
      'charisma': charisma,
    };
  }

  factory Character.fromMap(Map<String, dynamic> map) {
    return Character(
      name: map['name'] as String,
      level: map['level'] as int,
      hp: map['hp'] as int,
      ac: map['ac'] as int,
      strength: map['strength'] as int? ?? 10,
      dexterity: map['dexterity'] as int? ?? 10,
      constitution: map['constitution'] as int? ?? 10,
      intelligence: map['intelligence'] as int? ?? 10,
      wisdom: map['wisdom'] as int? ?? 10,
      charisma: map['charisma'] as int? ?? 10,
    );
  }
}

