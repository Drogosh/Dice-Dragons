import '../models/character.dart';
import '../models/character_class.dart';

/// Слой правил D&D для расчётов AC, HP, скиллов и спасбросков
class RulesEngine {
  /// Расчёт модификатора из значения характеристики
  /// Формула: (значение - 10) / 2
  static int calculateAbilityModifier(int abilityScore) {
    return (abilityScore - 10) ~/ 2;
  }

  /// Расчёт класса брони
  /// AC = 10 + модификатор Ловкости + (броня может её переопределить)
  static int calculateAC(Character character) {
    int ac = 10;

    // Если есть надетая броня, она определяет базовый AC
    if (character.equippedArmor != null) {
      ac = character.equippedArmor!.armorClass ?? 10;
    }

    // Добавляем модификатор Ловкости (зависит от типа брони)
    int dexModifier = calculateAbilityModifier(character.dexterity);

    // Если нет брони, добавляем весь модификатор
    if (character.equippedArmor == null) {
      ac += dexModifier;
    } else {
      // Если лёгкая броня, добавляем весь модификатор
      // Если средняя броня, добавляем минимум +2
      // Если тяжёлая броня, вообще не добавляем
      ac += dexModifier; // Упрощённо для демо
    }

    // Щит добавляет +2
    if (character.equippedShield != null) {
      ac += 2;
    }

    return ac;
  }

  /// Расчёт HP (здоровья)
  /// HP = maxHP костей класса + (уровень - 1) * средний результат HD + (модификатор Телосложения * уровень)
  static int calculateHP(Character character, CharacterClass? characterClass) {
    int conModifier = calculateAbilityModifier(character.constitution);

    if (characterClass == null) {
      // Если класс не определён, используем базовый расчёт (d8)
      int hpPerLevel = 5; // Средний результат d8
      int totalHP = 8 + (character.level - 1) * hpPerLevel + (conModifier * character.level);
      return totalHP.clamp(character.level, 9999);
    }

    // На 1м уровне: максимум костей + модификатор
    int baseHP = characterClass.hitDice + conModifier;

    // На остальных уровнях: средний результат костей + модификатор
    // d6 = 4, d8 = 5, d10 = 6, d12 = 7
    int hpPerLevel = (characterClass.hitDice / 2).ceil(); // Средний результат
    int totalHP = baseHP + (character.level - 1) * hpPerLevel + ((character.level - 1) * conModifier);

    // HP не может быть меньше уровня
    return totalHP.clamp(character.level, 9999);
  }

  /// Расчёт бонуса мастерства в зависимости от уровня
  static int calculateProficiencyBonus(int level) {
    if (level < 5) return 2;
    if (level < 9) return 3;
    if (level < 13) return 4;
    if (level < 17) return 5;
    return 6;
  }

  /// Расчёт модификатора навыка
  /// базовый модификатор характеристики + (бонус мастерства если владеет)
  static int calculateSkillModifier(
    Character character,
    Skill skill,
    int proficiencyBonus,
  ) {
    // Определяем характеристику для навыка
    final abilityScore = _getAbilityForSkill(character, skill);
    int modifier = calculateAbilityModifier(abilityScore);

    // Добавляем бонус мастерства если владеет
    final skillData = character.skills[skill];
    if (skillData?.isProficient ?? false) {
      modifier += proficiencyBonus;
    }

    return modifier;
  }

  /// Расчёт модификатора спасброска
  /// базовый модификатор характеристики + (бонус мастерства если владеет)
  static int calculateSavingThrow(
    Character character,
    String ability,
    int proficiencyBonus,
  ) {
    int abilityScore = 0;
    bool hasProficiency = false;

    switch (ability) {
      case 'STR':
        abilityScore = character.strength;
        hasProficiency = character.strengthSaveProficiency;
        break;
      case 'DEX':
        abilityScore = character.dexterity;
        hasProficiency = character.dexteritySaveProficiency;
        break;
      case 'CON':
        abilityScore = character.constitution;
        hasProficiency = character.constitutionSaveProficiency;
        break;
      case 'INT':
        abilityScore = character.intelligence;
        hasProficiency = character.intelligenceSaveProficiency;
        break;
      case 'WIS':
        abilityScore = character.wisdom;
        hasProficiency = character.wisdomSaveProficiency;
        break;
      case 'CHA':
        abilityScore = character.charisma;
        hasProficiency = character.charismaSaveProficiency;
        break;
    }

    int modifier = calculateAbilityModifier(abilityScore);
    if (hasProficiency) {
      modifier += proficiencyBonus;
    }

    return modifier;
  }

  /// Получить оценку характеристики для навыка
  static int _getAbilityForSkill(Character character, Skill skill) {
    switch (skill) {
      case Skill.acrobatics:
      case Skill.sleightOfHand:
      case Skill.stealth:
        return character.dexterity;
      case Skill.animalHandling:
      case Skill.insight:
      case Skill.medicine:
      case Skill.perception:
      case Skill.survival:
        return character.wisdom;
      case Skill.arcana:
      case Skill.history:
      case Skill.investigation:
      case Skill.nature:
      case Skill.religion:
        return character.intelligence;
      case Skill.athletics:
        return character.strength;
      case Skill.deception:
      case Skill.intimidation:
      case Skill.performance:
      case Skill.persuasion:
        return character.charisma;
    }
  }

  /// Расчёт пассивной внимательности (Passive Perception)
  /// 10 + модификатор восприятия
  static int calculatePassivePerception(Character character, int proficiencyBonus) {
    final perceptionModifier = calculateSkillModifier(
      character,
      Skill.perception,
      proficiencyBonus,
    );
    return 10 + perceptionModifier;
  }

  /// Получить описание кубика для класса
  /// Например: "d8" для паладина, "d6" для чародея
  static String getHitDiceString(CharacterClass characterClass) {
    return 'd${characterClass.hitDice}';
  }

  /// Расчёт увеличения HP при повышении уровня
  /// HP += результат кубика + модификатор Телосложения
  static int calculateHPGain(int diceResult, int conModifier) {
    return diceResult + conModifier;
  }

  /// Проверяет, находится ли значение характеристики в допустимых пределах (3-20)
  static bool isValidAbilityScore(int score) {
    return score >= 3 && score <= 20;
  }

  /// Проверяет, находится ли уровень в допустимых пределах (1-20)
  static bool isValidLevel(int level) {
    return level >= 1 && level <= 20;
  }
}


