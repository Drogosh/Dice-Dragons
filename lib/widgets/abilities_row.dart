import 'package:flutter/material.dart';
import '../models/character.dart';
import 'strength_card.dart';
import 'dexterity_card.dart';
import 'constitution_card.dart';
import 'intelligence_card.dart';
import 'wisdom_card.dart';
import 'charisma_card.dart';

class AbilitiesRow extends StatelessWidget {
  final Character character;
  final String? selectedAbility;
  final Function(String?)? onAbilityTap;

  const AbilitiesRow({
    super.key,
    required this.character,
    this.selectedAbility,
    this.onAbilityTap,
  });

  @override
  Widget build(BuildContext context) {
    // Контент ряда
    final content = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        GestureDetector(
          onTap: () => onAbilityTap?.call(selectedAbility == 'STR' ? null : 'STR'),
          child: _StatCardWrapper(
            child: StrengthCard(
              strength: character.strength,
              modifier: character.getStrengthModifier(),
              savingThrow: character.getStrengthSave(),
              isSelected: selectedAbility == 'STR',
            ),
          ),
        ),
        const SizedBox(width: 8.0),
        GestureDetector(
          onTap: () => onAbilityTap?.call(selectedAbility == 'DEX' ? null : 'DEX'),
          child: _StatCardWrapper(
            child: DexterityCard(
              dexterity: character.dexterity,
              modifier: character.getDexterityModifier(),
              savingThrow: character.getDexteritySave(),
              isSelected: selectedAbility == 'DEX',
            ),
          ),
        ),
        const SizedBox(width: 8.0),
        GestureDetector(
          onTap: () => onAbilityTap?.call(selectedAbility == 'CON' ? null : 'CON'),
          child: _StatCardWrapper(
            child: ConstitutionCard(
              constitution: character.constitution,
              modifier: character.getConstitutionModifier(),
              savingThrow: character.getConstitutionSave(),
              isSelected: selectedAbility == 'CON',
            ),
          ),
        ),
        const SizedBox(width: 8.0),
        GestureDetector(
          onTap: () => onAbilityTap?.call(selectedAbility == 'INT' ? null : 'INT'),
          child: _StatCardWrapper(
            child: IntelligenceCard(
              intelligence: character.intelligence,
              modifier: character.getIntelligenceModifier(),
              savingThrow: character.getIntelligenceSave(),
              isSelected: selectedAbility == 'INT',
            ),
          ),
        ),
        const SizedBox(width: 8.0),
        GestureDetector(
          onTap: () => onAbilityTap?.call(selectedAbility == 'WIS' ? null : 'WIS'),
          child: _StatCardWrapper(
            child: WisdomCard(
              wisdom: character.wisdom,
              modifier: character.getWisdomModifier(),
              savingThrow: character.getWisdomSave(),
              isSelected: selectedAbility == 'WIS',
            ),
          ),
        ),
        const SizedBox(width: 8.0),
        GestureDetector(
          onTap: () => onAbilityTap?.call(selectedAbility == 'CHA' ? null : 'CHA'),
          child: _StatCardWrapper(
            child: CharismaCard(
              charisma: character.charisma,
              modifier: character.getCharismaModifier(),
              savingThrow: character.getCharismaSave(),
              isSelected: selectedAbility == 'CHA',
            ),
          ),
        ),
      ],
    );

    // FittedBox автоматически масштабирует содержимое, чтобы оно влезло
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: FittedBox(
          fit: BoxFit.scaleDown, // Масштабирует вниз, не растягивает
          child: content,
        ),
      ),
    );
  }
}

/// Вспомогательный виджет для фиксирования размера карточки
class _StatCardWrapper extends StatelessWidget {
  final Widget child;

  const _StatCardWrapper({required this.child});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 59.12,
      height: 126,
      child: child,
    );
  }
}
