import 'character.dart';

enum RequestType {
  initiative,  // Инициатива: 1d20 + DEX
  attack,      // Атака: 1d20 + STR/DEX
  damage,      // Урон: XdY + модификатор
  check,       // Проверка: 1d20 + модификатор характеристики
  save,        // Спасбросок: 1d20 + модификатор спасброска
}

enum AbilityType {
  strength,
  dexterity,
  constitution,
  intelligence,
  wisdom,
  charisma,
}

class Request {
  final String? id;
  final String sessionId;
  final String dmId;
  final String characterId;
  final String characterName;
  final RequestType type;
  final String formula;          // Финальная формула (например "1d20+5")
  final int modifier;             // Автоматически рассчитанный модификатор
  final int? targetAc;           // Для атак
  final String? note;            // Описание (например "по гоблину", "проверка Атлетики")
  final AbilityType? abilityType; // Для проверок и спасбросков
  final AbilityType? dmAbilityType; // Характеристика, выбранная ДМ для применения к броску
  final String? createdAt;
  final String? dmMode; // 'normal' | 'advantage' | 'disadvantage' - chosen by DM; overrides player choice if set
  final String status;           // "open" или "closed"
  final String audience;         // "all" или "subset"
  final List<String> targetUids; // Целевые игроки (если subset)

  Request({
    this.id,
    required this.sessionId,
    required this.dmId,
    required this.characterId,
    required this.characterName,
    required this.type,
    required this.formula,
    required this.modifier,
    this.targetAc,
    this.note,
    this.abilityType,
    this.dmAbilityType,
    this.createdAt,
    this.dmMode,
    this.status = 'open',
    this.audience = 'all',
    this.targetUids = const [],
  });

  /// Создать Request с автоматическим расчетом модификатора
  factory Request.createWithAutoModifier({
    required String sessionId,
    required String dmId,
    required Character character,
    required RequestType type,
    required String baseFormula,  // Например "1d20" или "2d6"
    int? targetAc,
    String? note,
    AbilityType? abilityType,
  }) {
    // Рассчитываем модификатор в зависимости от типа проверки
    int modifier = 0;

    switch (type) {
      case RequestType.initiative:
        // Инициатива: DEX модификатор
        modifier = character.getDexterityModifier();
        break;

      case RequestType.attack:
        // Атака: STR или DEX модификатор (по умолчанию STR)
        modifier = character.getStrengthModifier();
        break;

      case RequestType.damage:
        // Урон: обычно STR модификатор (для оружия в ближнем бою)
        modifier = character.getStrengthModifier();
        break;

      case RequestType.check:
        // Проверка: зависит от abilityType
        if (abilityType != null) {
          modifier = _getAbilityModifier(character, abilityType);
        }
        break;

      case RequestType.save:
        // Спасбросок: зависит от abilityType (используем модификатор + мастерство если есть)
        if (abilityType != null) {
          modifier = _getSaveModifier(character, abilityType);
        }
        break;
    }

    // Формируем финальную формулу с модификатором
    final modifierStr = modifier >= 0 ? '+$modifier' : '$modifier';
    final finalFormula = '$baseFormula$modifierStr';

    return Request(
      sessionId: sessionId,
      dmId: dmId,
      characterId: character.id ?? character.name,
      characterName: character.name,
      type: type,
      formula: finalFormula,
      modifier: modifier,
      targetAc: targetAc,
      note: note,
      abilityType: abilityType,
      dmAbilityType: null,
      createdAt: DateTime.now().toIso8601String(),
      dmMode: null,
      status: 'open',
    );
  }

  /// Получить модификатор характеристики
  static int _getAbilityModifier(Character character, AbilityType abilityType) {
    switch (abilityType) {
      case AbilityType.strength:
        return character.getStrengthModifier();
      case AbilityType.dexterity:
        return character.getDexterityModifier();
      case AbilityType.constitution:
        return character.getConstitutionModifier();
      case AbilityType.intelligence:
        return character.getIntelligenceModifier();
      case AbilityType.wisdom:
        return character.getWisdomModifier();
      case AbilityType.charisma:
        return character.getCharismaModifier();
    }
  }

  /// Получить модификатор спасброска (характеристика + мастерство если есть)
  static int _getSaveModifier(Character character, AbilityType abilityType) {
    int baseMod = _getAbilityModifier(character, abilityType);
    int profBonus = 0;

    // Проверяем мастерство спасброска
    switch (abilityType) {
      case AbilityType.strength:
        profBonus = character.strengthSaveProficiency ? character.proficiencyBonus : 0;
        break;
      case AbilityType.dexterity:
        profBonus = character.dexteritySaveProficiency ? character.proficiencyBonus : 0;
        break;
      case AbilityType.constitution:
        profBonus = character.constitutionSaveProficiency ? character.proficiencyBonus : 0;
        break;
      case AbilityType.intelligence:
        profBonus = character.intelligenceSaveProficiency ? character.proficiencyBonus : 0;
        break;
      case AbilityType.wisdom:
        profBonus = character.wisdomSaveProficiency ? character.proficiencyBonus : 0;
        break;
      case AbilityType.charisma:
        profBonus = character.charismaSaveProficiency ? character.proficiencyBonus : 0;
        break;
    }

    return baseMod + profBonus;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'sessionId': sessionId,
      'dmId': dmId,
      'characterId': characterId,
      'characterName': characterName,
      'type': type.toString().split('.').last,
      'formula': formula,
      'modifier': modifier,
      'targetAc': targetAc,
      'note': note,
      'abilityType': abilityType?.toString().split('.').last,
      'dmAbilityType': dmAbilityType?.toString().split('.').last,
      'createdAt': createdAt,
      'dmMode': dmMode,
      'status': status,
      'audience': audience,
      'targetUids': targetUids,
    };
  }

  factory Request.fromMap(Map<String, dynamic> map) {
    RequestType parseRequestType(String str) {
      switch (str) {
        case 'initiative':
          return RequestType.initiative;
        case 'attack':
          return RequestType.attack;
        case 'damage':
          return RequestType.damage;
        case 'check':
          return RequestType.check;
        case 'save':
          return RequestType.save;
        default:
          return RequestType.check;
      }
    }

    AbilityType? parseAbilityType(String? str) {
      if (str == null) return null;
      switch (str) {
        case 'strength':
          return AbilityType.strength;
        case 'dexterity':
          return AbilityType.dexterity;
        case 'constitution':
          return AbilityType.constitution;
        case 'intelligence':
          return AbilityType.intelligence;
        case 'wisdom':
          return AbilityType.wisdom;
        case 'charisma':
          return AbilityType.charisma;
        default:
          return null;
      }
    }

    return Request(
      id: map['id'] as String?,
      sessionId: map['sessionId'] as String? ?? '',
      dmId: map['dmId'] as String? ?? '',
      characterId: map['characterId'] as String? ?? '',
      characterName: map['characterName'] as String? ?? '',
      type: parseRequestType(map['type'] as String? ?? 'check'),
      formula: map['formula'] as String? ?? '1d20',
      modifier: map['modifier'] as int? ?? 0,
      targetAc: map['targetAc'] as int?,
      note: map['note'] as String?,
      abilityType: parseAbilityType(map['abilityType'] as String?),
      dmAbilityType: parseAbilityType(map['dmAbilityType'] as String?),
      createdAt: map['createdAt'] as String?,
      dmMode: map['dmMode'] as String?,
      status: map['status'] as String? ?? 'open',
      audience: map['audience'] as String? ?? 'all',
      targetUids: List<String>.from(map['targetUids'] as List<dynamic>? ?? []),
    );
  }

  Request copyWith({
    String? id,
    String? sessionId,
    String? dmId,
    String? characterId,
    String? characterName,
    RequestType? type,
    String? formula,
    int? modifier,
    int? targetAc,
    String? note,
    AbilityType? abilityType,
    AbilityType? dmAbilityType,
    String? createdAt,
    String? status,
    String? audience,
    List<String>? targetUids,
    String? dmMode,
  }) {
    return Request(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      dmId: dmId ?? this.dmId,
      characterId: characterId ?? this.characterId,
      characterName: characterName ?? this.characterName,
      type: type ?? this.type,
      formula: formula ?? this.formula,
      modifier: modifier ?? this.modifier,
      targetAc: targetAc ?? this.targetAc,
      note: note ?? this.note,
      abilityType: abilityType ?? this.abilityType,
      dmAbilityType: dmAbilityType ?? this.dmAbilityType,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
      audience: audience ?? this.audience,
      targetUids: targetUids ?? this.targetUids,
      dmMode: dmMode ?? this.dmMode,
    );
  }
}







