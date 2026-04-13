import 'package:flutter/foundation.dart';
import '../models/request.dart';
import '../models/character.dart';
import '../services/session_service.dart';

/// Примеры использования Request API для различных типов проверок
class RequestExamples {
  /// Пример 1: Инициатива
  /// Модификатор: DEX модификатор персонажа
  static Future<Request> exampleInitiative(
    SessionService sessionService,
    Character character,
    String sessionId,
  ) async {
    return sessionService.createRequest(
      sessionId: sessionId,
      character: character,
      type: RequestType.initiative,
      baseFormula: '1d20',
      note: 'Боевая инициатива',
    );
    // Результат: formula = "1d20+${character.getDexterityModifier()}"
  }

  /// Пример 2: Атака в ближнем бою
  /// Модификатор: STR модификатор персонажа
  static Future<Request> exampleMeleeAttack(
    SessionService sessionService,
    Character character,
    String sessionId,
  ) async {
    return sessionService.createRequest(
      sessionId: sessionId,
      character: character,
      type: RequestType.attack,
      baseFormula: '1d20',
      targetAc: 15, // Целевой AC врага
      note: 'Удар длинным мечом по орку',
    );
    // Результат: formula = "1d20+${character.getStrengthModifier()}"
  }

  /// Пример 3: Атака издалека (ловкостью)
  /// Это требует пока ручной обработки - API не различает STR/DEX атаку
  /// Может быть расширено позже
  static Future<Request> exampleRangedAttack(
    SessionService sessionService,
    Character character,
    String sessionId,
  ) async {
    // Пока используем STR, но можно добавить поле weaponType
    return sessionService.createRequest(
      sessionId: sessionId,
      character: character,
      type: RequestType.attack,
      baseFormula: '1d20',
      targetAc: 13,
      note: 'Выстрел из лука',
    );
  }

  /// Пример 4: Урон от оружия
  /// Модификатор: STR модификатор (для ближнего боя)
  static Future<Request> exampleWeaponDamage(
    SessionService sessionService,
    Character character,
    String sessionId,
    String weaponDamageDice, // например "1d8", "2d6"
  ) async {
    return sessionService.createRequest(
      sessionId: sessionId,
      character: character,
      type: RequestType.damage,
      baseFormula: weaponDamageDice,
      note: 'Урон от длинного меча',
    );
    // Результат: formula = "${weaponDamageDice}+${character.getStrengthModifier()}"
  }

  /// Пример 5: Проверка Акробатики (DEX)
  static Future<Request> exampleAcrobaticsCheck(
    SessionService sessionService,
    Character character,
    String sessionId,
  ) async {
    return sessionService.createRequest(
      sessionId: sessionId,
      character: character,
      type: RequestType.check,
      baseFormula: '1d20',
      note: 'Проверка Акробатики - прыгнуть через пропасть',
      abilityType: AbilityType.dexterity,
    );
    // Результат: formula = "1d20+${character.getDexterityModifier()}"
  }

  /// Пример 6: Проверка Атлетики (STR)
  static Future<Request> exampleAthleticsCheck(
    SessionService sessionService,
    Character character,
    String sessionId,
  ) async {
    return sessionService.createRequest(
      sessionId: sessionId,
      character: character,
      type: RequestType.check,
      baseFormula: '1d20',
      note: 'Проверка Атлетики - забраться на стену',
      abilityType: AbilityType.strength,
    );
    // Результат: formula = "1d20+${character.getStrengthModifier()}"
  }

  /// Пример 7: Проверка Магии (INT)
  static Future<Request> exampleArcanaCheck(
    SessionService sessionService,
    Character character,
    String sessionId,
  ) async {
    return sessionService.createRequest(
      sessionId: sessionId,
      character: character,
      type: RequestType.check,
      baseFormula: '1d20',
      note: 'Проверка Магии - узнать информацию о заклинании',
      abilityType: AbilityType.intelligence,
    );
    // Результат: formula = "1d20+${character.getIntelligenceModifier()}"
  }

  /// Пример 8: Проверка Восприятия (WIS)
  static Future<Request> examplePerceptionCheck(
    SessionService sessionService,
    Character character,
    String sessionId,
  ) async {
    return sessionService.createRequest(
      sessionId: sessionId,
      character: character,
      type: RequestType.check,
      baseFormula: '1d20',
      note: 'Проверка Восприятия - заметить ловушку',
      abilityType: AbilityType.wisdom,
    );
    // Результат: formula = "1d20+${character.getWisdomModifier()}"
  }

  /// Пример 9: Спасбросок Телосложения (CON)
  /// Модификатор: CON мод + мастерство спасброска CON (если есть)
  static Future<Request> exampleConstitutionSave(
    SessionService sessionService,
    Character character,
    String sessionId,
  ) async {
    return sessionService.createRequest(
      sessionId: sessionId,
      character: character,
      type: RequestType.save,
      baseFormula: '1d20',
      note: 'Спасбросок против яда - DC 14',
      abilityType: AbilityType.constitution,
    );
    // Результат:
    // modifier = CON_MOD + (character.constitutionSaveProficiency ? profBonus : 0)
    // formula = "1d20+$modifier"
  }

  /// Пример 10: Спасбросок Ловкости (DEX)
  static Future<Request> exampleDexteritySave(
    SessionService sessionService,
    Character character,
    String sessionId,
  ) async {
    return sessionService.createRequest(
      sessionId: sessionId,
      character: character,
      type: RequestType.save,
      baseFormula: '1d20',
      note: 'Спасбросок против огненного шара - DC 15',
      abilityType: AbilityType.dexterity,
    );
  }

  /// Пример 11: Проверка Обмана (CHA)
  static Future<Request> exampleDeceptionCheck(
    SessionService sessionService,
    Character character,
    String sessionId,
  ) async {
    return sessionService.createRequest(
      sessionId: sessionId,
      character: character,
      type: RequestType.check,
      baseFormula: '1d20',
      note: 'Проверка Обмана - убедить торговца в низкую цену',
      abilityType: AbilityType.charisma,
    );
    // Результат: formula = "1d20+${character.getCharismaModifier()}"
  }

  /// Пример 12: Слушать все запросы сессии в реальном времени
  static void listenToRequests(
    SessionService sessionService,
    String sessionId,
  ) {
    sessionService.watchRequests(sessionId).listen((requests) {
      if (kDebugMode) {
        debugPrint('═══════════════════════════════════════');
        debugPrint('Запросы в сессии: ${requests.length}');
        for (final request in requests) {
          debugPrint('');
          debugPrint('👤 ${request.characterName}');
          debugPrint('📋 ${request.type.toString().split('.').last}');
          debugPrint('🎲 Формула: ${request.formula}');
          if (request.note != null) {
            debugPrint('📝 ${request.note}');
          }
          if (request.targetAc != null) {
            debugPrint('🎯 AC: ${request.targetAc}');
          }
          debugPrint('⏰ ${request.status}');
        }
        debugPrint('═══════════════════════════════════════');
      }
    });
  }
}




