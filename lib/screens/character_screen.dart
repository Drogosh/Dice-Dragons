import 'package:flutter/material.dart';
import '../models/character.dart';
import '../models/item.dart';

class CharacterScreen extends StatefulWidget {
  final Character character;

  const CharacterScreen({
    super.key,
    required this.character,
  });

  @override
  State<CharacterScreen> createState() => _CharacterScreenState();
}

class _CharacterScreenState extends State<CharacterScreen> {
  late Character character;
  Skill? selectedSkillFilter;

  @override
  void initState() {
    super.initState();
    character = widget.character;
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Информация о персонаже (имя, уровень, ХП, КБ)
            _buildCharacterInfo(context),
            const SizedBox(height: 24),
            // Характеристики и модификаторы
            _buildAbilitiesSection(context),
            const SizedBox(height: 24),
            // Навыки
            _buildSkillsSection(context),
          ],
        ),
      ),
    );
  }

  // Информация о персонаже
  Widget _buildCharacterInfo(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Информация о персонаже',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            _buildInfoRow('Имя:', character.name),
            _buildInfoRow('Уровень:', '${character.level}'),
            _buildInfoRow('Здоровье (ХП):', '${character.hp}'),
            _buildInfoRow('Класс брони (КБ):', '${character.ac}'),
          ],
        ),
      ),
    );
  }

  // Строка информации
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  // Секция характеристик
  Widget _buildAbilitiesSection(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Характеристики и модификаторы',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.9,
              children: [
                _buildAbilityCard(
                  'Сила',
                  'STR',
                  character.strength,
                  character.getStrengthModifier(),
                ),
                _buildAbilityCard(
                  'Ловкость',
                  'DEX',
                  character.dexterity,
                  character.getDexterityModifier(),
                ),
                _buildAbilityCard(
                  'Телосложение',
                  'CON',
                  character.constitution,
                  character.getConstitutionModifier(),
                ),
                _buildAbilityCard(
                  'Интеллект',
                  'INT',
                  character.intelligence,
                  character.getIntelligenceModifier(),
                ),
                _buildAbilityCard(
                  'Мудрость',
                  'WIS',
                  character.wisdom,
                  character.getWisdomModifier(),
                ),
                _buildAbilityCard(
                  'Харизма',
                  'CHA',
                  character.charisma,
                  character.getCharismaModifier(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Карточка характеристики
  Widget _buildAbilityCard(
    String name,
    String abbreviation,
    int score,
    int modifier,
  ) {
    final modifierColor = modifier >= 0 ? Colors.green : Colors.red;
    final isSelected = selectedSkillFilter != null &&
        _getAbilityForSkill(selectedSkillFilter!) == _getAbilityNameForSkill(selectedSkillFilter!).split('(')[1].replaceAll(')', '');

    return GestureDetector(
      onTap: () {
        setState(() {
          // Если уже выбрана эта характеристика, снимаем фильтр
          if (_isAbilitySelected(name)) {
            selectedSkillFilter = null;
          } else {
            // Иначе устанавливаем фильтр на навыки этой характеристики
            selectedSkillFilter = _getFirstSkillForAbility(name);
          }
        });
      },
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(
            color: _isAbilitySelected(name)
                ? Colors.amber[700]!
                : Theme.of(context).colorScheme.primary,
            width: _isAbilitySelected(name) ? 3 : 2,
          ),
          borderRadius: BorderRadius.circular(8),
          color: _isAbilitySelected(name) ? Colors.amber[50] : null,
        ),
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              abbreviation,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              name,
              style: const TextStyle(fontSize: 10),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(4),
            ),
            padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 6),
            child: RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: '$score',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                  TextSpan(
                    text: ' (${modifier >= 0 ? '+' : ''}$modifier)',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: modifierColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
            const SizedBox(height: 4),
          ],
        ),
      ),
    );
  }

  // Проверяет, выбрана ли характеристика
  bool _isAbilitySelected(String abilityName) {
    if (selectedSkillFilter == null) return false;
    return _getAbilityNameForSkill(selectedSkillFilter!).contains(abilityName);
  }

  // Получает первый навык для характеристики
  Skill _getFirstSkillForAbility(String abilityName) {
    final allSkills = character.skills.keys.toList();
    return allSkills.firstWhere((skill) =>
        _getAbilityNameForSkill(skill).contains(abilityName));
  }

  // Получает характеристику для навыка
  String _getAbilityForSkill(Skill skill) {
    switch (skill) {
      case Skill.acrobatics:
      case Skill.sleightOfHand:
      case Skill.stealth:
        return 'DEX';
      case Skill.animalHandling:
      case Skill.insight:
      case Skill.medicine:
      case Skill.perception:
      case Skill.survival:
        return 'WIS';
      case Skill.arcana:
      case Skill.history:
      case Skill.investigation:
      case Skill.nature:
      case Skill.religion:
        return 'INT';
      case Skill.athletics:
        return 'STR';
      case Skill.deception:
      case Skill.intimidation:
      case Skill.performance:
      case Skill.persuasion:
        return 'CHA';
    }
  }

  // Фильтрует навыки по выбранной характеристике
  List<SkillModifier> _getFilteredSkills() {
    if (selectedSkillFilter == null) {
      return character.skills.values.toList();
    }
    final selectedAbility = _getAbilityForSkill(selectedSkillFilter!);
    return character.skills.values
        .where((skill) => _getAbilityForSkill(skill.skill) == selectedAbility)
        .toList();
  }

  // Секция навыков
  Widget _buildSkillsSection(BuildContext context) {
    final filteredSkills = _getFilteredSkills();

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Навыки (${filteredSkills.length}/${character.skills.length})',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                if (selectedSkillFilter != null)
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedSkillFilter = null;
                      });
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.amber[100],
                        borderRadius: BorderRadius.circular(4),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      child: Text(
                        'Сброс фильтра',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.amber[900],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            // Контейнер с прокруткой для навыков
            SizedBox(
              height: 300,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: filteredSkills.length,
                itemBuilder: (context, index) {
                  final skill = filteredSkills[index];
                  final bonus = character.getSkillBonus(skill.skill);
                  final abilityForSkill = _getAbilityNameForSkill(skill.skill);

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6.0),
                    child: Row(
                      children: [
                        // Чекбокс для мастерства
                        SizedBox(
                          width: 24,
                          height: 24,
                          child: Checkbox(
                            value: skill.isProficient,
                            onChanged: (value) {
                              setState(() {
                                character.setProficiency(
                                    skill.skill, value ?? false);
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Название и характеристика
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                skill.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                  fontSize: 13,
                                ),
                              ),
                              Text(
                                abilityForSkill,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Бонус навыка
                        Container(
                          decoration: BoxDecoration(
                            color: bonus >= 0
                                ? Colors.green[100]
                                : Colors.red[100],
                            borderRadius: BorderRadius.circular(4),
                          ),
                          padding: const EdgeInsets.symmetric(
                            vertical: 4,
                            horizontal: 10,
                          ),
                          child: Text(
                            bonus >= 0 ? '+$bonus' : '$bonus',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: bonus >= 0
                                  ? Colors.green[900]
                                  : Colors.red[900],
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getAbilityNameForSkill(Skill skill) {
    switch (skill) {
      case Skill.acrobatics:
      case Skill.sleightOfHand:
      case Skill.stealth:
        return 'Ловкость (DEX)';
      case Skill.animalHandling:
      case Skill.insight:
      case Skill.medicine:
      case Skill.perception:
      case Skill.survival:
        return 'Мудрость (WIS)';
      case Skill.arcana:
      case Skill.history:
      case Skill.investigation:
      case Skill.nature:
      case Skill.religion:
        return 'Интеллект (INT)';
      case Skill.athletics:
        return 'Сила (STR)';
      case Skill.deception:
      case Skill.intimidation:
      case Skill.performance:
      case Skill.persuasion:
        return 'Харизма (CHA)';
    }
  }
}

