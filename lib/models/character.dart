import 'dart:convert';
import 'item.dart';

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
  String? id;  // ID в Firestore
  String name;
  int level;
  int hp;
  int ac; // Armor Class (Класс брони)
  int proficiencyBonus = 2; // Бонус мастерства (зависит от уровня)

  String? raceId;    // ID выбранной расы
  String? className; // Класс персонажа
  String? raceName;  // Имя расы
  String? classNameDisplay; // Имя класса для отображения

  // Шесть основных характеристик D&D
  int strength;      // Сила
  int dexterity;     // Ловкость
  int constitution;  // Телосложение
  int intelligence;  // Интеллект
  int wisdom;        // Мудрость
  int charisma;      // Харизма

  // Навыки
  late Map<Skill, SkillModifier> skills;

  // Надетые предметы
  Item? equippedArmor;        // Броня
  Item? equippedShield;       // Щит
  List<Item?> equippedWeapons = [null, null, null]; // 3 оружия (слоты 0, 1, 2)

  Character({
    this.id,
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
    this.raceId,
    this.className,
    this.raceName,
    this.classNameDisplay,
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

   /// Получить пассивную внимательность (Passive Perception)
   int getPassivePerception() {
     final wisdomMod = getWisdomModifier();
     final perceptionSkill = skills[Skill.perception];
     final profBonus = perceptionSkill!.isProficient ? proficiencyBonus : 0;
     return 10 + wisdomMod + profBonus;
   }

   /// Надеть броню
   void equipArmor(Item? armor) {
     if (armor == null || armor.type == ItemType.armor) {
       equippedArmor = armor;
     }
   }

   /// Надеть щит
   void equipShield(Item? shield) {
     if (shield == null || (shield.type == ItemType.armor && shield.armorType == ArmorType.shield)) {
       equippedShield = shield;
     }
   }

   /// Надеть оружие в слот (0, 1, или 2)
   void equipWeapon(int slot, Item? weapon) {
     if (slot >= 0 && slot < 3) {
       if (weapon == null || weapon.type == ItemType.weapon) {
         equippedWeapons[slot] = weapon;
       }
     }
   }

   /// Снять оружие из слота
   void unequipWeapon(int slot) {
     if (slot >= 0 && slot < 3) {
       equippedWeapons[slot] = null;
     }
   }

     /// Получить текущий AC (на основе надетых предметов)
     int getCalculatedAC() {
       int baseAC = 10;
       final dexMod = getDexterityModifier();

       // Если броня надета
       if (equippedArmor != null && equippedArmor!.armorClass != null) {
         final armorAC = equippedArmor!.armorClass!;

         // В зависимости от типа брони
         if (equippedArmor!.armorType == ArmorType.light) {
           // Легкая броня: её КБ + мод ловкости
           baseAC = armorAC + dexMod;
         } else if (equippedArmor!.armorType == ArmorType.medium) {
           // Средняя броня: её КБ + мод ловкости (макс +2)
           baseAC = armorAC + (dexMod > 2 ? 2 : dexMod);
         } else if (equippedArmor!.armorType == ArmorType.heavy) {
           // Тяжелая броня: просто её КБ
           baseAC = armorAC;
         }
       } else {
         // Без брони: 10 + мод ловкости
         baseAC = 10 + dexMod;
       }

        // Добавляем AC щита если надет
        // Щит обычно имеет AC 10, то есть дает +2 бонус
        // Но берем реальное значение: AC щита минус 10 (базовый AC без щита)
        if (equippedShield != null && equippedShield!.armorClass != null) {
          baseAC += equippedShield!.armorClass!;
        }

       return baseAC;
     }

      /// Получить расшифровку расчета AC (для отображения)
      String getACCalculationDetails() {
        final dexMod = getDexterityModifier();
        final dexModStr = '${dexMod > 0 ? '+' : ''}$dexMod';
        final ac = getCalculatedAC();

        String calculation = '';

        if (equippedArmor != null && equippedArmor!.armorClass != null) {
          final armorAC = equippedArmor!.armorClass!;

          if (equippedArmor!.armorType == ArmorType.light) {
            calculation = 'КБ $armorAC $dexModStr(ловк)';
          } else if (equippedArmor!.armorType == ArmorType.medium) {
            final effectiveDex = dexMod > 2 ? 2 : dexMod;
            final effectiveDexStr = '${effectiveDex > 0 ? '+' : ''}$effectiveDex';
            calculation = 'КБ $armorAC $effectiveDexStr(ловк м.+2)';
          } else if (equippedArmor!.armorType == ArmorType.heavy) {
            calculation = 'КБ $armorAC';
          }
        } else {
          calculation = 'КБ 10 $dexModStr(ловк)';
        }

         if (equippedShield != null) {
           final shieldBonus = equippedShield!.armorClass != null
               ? equippedShield!.armorClass!
               : 2;
           calculation += ' +$shieldBonus(щит)';
         }

        calculation += ' = $ac';

        return calculation;
      }

   /// Получить список надетых предметов
   List<Item?> getEquippedItems() {
     return [equippedArmor, equippedShield, ...equippedWeapons];
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
    // Сохраняем профессиональности навыков
    Map<String, bool> skillProficiencies = {};
    skills.forEach((skill, modifier) {
      skillProficiencies[skill.toString()] = modifier.isProficient;
    });

    return {
      'id': id ?? name,
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
      'raceId': raceId,
      'className': className,
      'raceName': raceName,
      'classNameDisplay': classNameDisplay,
      'skillProficiencies': skillProficiencies,
    };
  }

  factory Character.fromMap(Map<String, dynamic> map) {
    final character = Character(
      id: map['id'] as String?,
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
      raceId: map['raceId'] as String?,
      className: map['className'] as String?,
      raceName: map['raceName'] as String?,
      classNameDisplay: map['classNameDisplay'] as String?,
    );

    // Восстанавливаем профессиональности навыков
    if (map['skillProficiencies'] is Map) {
      final profs = map['skillProficiencies'] as Map<String, dynamic>;
      profs.forEach((skillStr, isProficient) {
        // Преобразуем строку обратно в Skill enum
        try {
          final skillName = skillStr.replaceFirst('Skill.', '');
          for (final skill in Skill.values) {
            if (skill.toString() == 'Skill.$skillName') {
              if (character.skills.containsKey(skill)) {
                character.skills[skill]!.isProficient = isProficient as bool;
              }
              break;
            }
          }
        } catch (e) {
          // Игнорируем ошибки при преобразовании
        }
      });
    }

    return character;
  }

  /// Копирование с изменениями
  Character copyWith({
    String? id,
    String? name,
    int? level,
    int? hp,
    int? ac,
    int? strength,
    int? dexterity,
    int? constitution,
    int? intelligence,
    int? wisdom,
    int? charisma,
    String? raceId,
    String? className,
    String? raceName,
    String? classNameDisplay,
  }) {
    return Character(
      id: id ?? this.id,
      name: name ?? this.name,
      level: level ?? this.level,
      hp: hp ?? this.hp,
      ac: ac ?? this.ac,
      strength: strength ?? this.strength,
      dexterity: dexterity ?? this.dexterity,
      constitution: constitution ?? this.constitution,
      intelligence: intelligence ?? this.intelligence,
      wisdom: wisdom ?? this.wisdom,
      charisma: charisma ?? this.charisma,
      raceId: raceId ?? this.raceId,
      className: className ?? this.className,
      raceName: raceName ?? this.raceName,
      classNameDisplay: classNameDisplay ?? this.classNameDisplay,
    );
  }

  String toJsonString() {
    return jsonEncode(toMap());
  }

  factory Character.fromJsonString(String jsonString) {
    final map = jsonDecode(jsonString) as Map<String, dynamic>;
    return Character.fromMap(map);
  }
}
