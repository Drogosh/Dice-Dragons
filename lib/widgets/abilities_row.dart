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

  const AbilitiesRow({
    super.key,
    required this.character,
  });

  @override
  Widget build(BuildContext context) {
    // Контент ряда
    final content = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _StatCardWrapper(
          child: StrengthCard(
            strength: character.strength,
            modifier: character.getStrengthModifier(),
            savingThrow: character.getStrengthSave(),
          ),
        ),
        const SizedBox(width: 8.0),
        _StatCardWrapper(
          child: DexterityCard(
            dexterity: character.dexterity,
            modifier: character.getDexterityModifier(),
            savingThrow: character.getDexteritySave(),
          ),
        ),
        const SizedBox(width: 8.0),
        _StatCardWrapper(
          child: ConstitutionCard(
            constitution: character.constitution,
            modifier: character.getConstitutionModifier(),
            savingThrow: character.getConstitutionSave(),
          ),
        ),
        const SizedBox(width: 8.0),
        _StatCardWrapper(
          child: IntelligenceCard(
            intelligence: character.intelligence,
            modifier: character.getIntelligenceModifier(),
            savingThrow: character.getIntelligenceSave(),
          ),
        ),
        const SizedBox(width: 8.0),
        _StatCardWrapper(
          child: WisdomCard(
            wisdom: character.wisdom,
            modifier: character.getWisdomModifier(),
            savingThrow: character.getWisdomSave(),
          ),
        ),
        const SizedBox(width: 8.0),
        _StatCardWrapper(
          child: CharismaCard(
            charisma: character.charisma,
            modifier: character.getCharismaModifier(),
            savingThrow: character.getCharismaSave(),
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
