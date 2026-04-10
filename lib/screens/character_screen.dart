import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/character.dart';
import '../services/firestore_service.dart';
import '../widgets/stat_card.dart';
import '../widgets/strength_card.dart';

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
  bool _isEditingSkills = false;

  @override
  void initState() {
    super.initState();
    character = widget.character;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/images/stats_bg.png'),
          fit: BoxFit.cover,
          opacity: 0.15, // Прозрачность фона
        ),
      ),
      child: Column(
        children: [

          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Карточка Силы
                    Center(
                      child: StrengthCard(
                        strength: character.strength,
                        modifier: character.getStrengthModifier(),
                        savingThrow: character.getStrengthSave(),
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Характеристики и модификаторы
                    _buildAbilitiesSection(context),
                    const SizedBox(height: 24),
                    // Пассивная внимательность
                    _buildPassivePerceptionSection(context),
                    const SizedBox(height: 24),
                    // Навыки
                    _buildSkillsSection(context),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ...existing code...

  Widget _buildAbilitiesSection(BuildContext context) {
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
                  'Характеристики: ',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                Container(
                  decoration: BoxDecoration(
                    color: _isEditingSkills ? Colors.orange : Colors.grey[700],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: IconButton(
                    icon: Icon(
                      _isEditingSkills ? Icons.check : Icons.edit,
                      color: Colors.white,
                    ),
                    onPressed: () async {
                      if (_isEditingSkills) {
                        // Сохраняем на Firebase
                        try {
                          final firestoreService = FirestoreService();
                          final userId = FirebaseAuth.instance.currentUser!.uid;
                          await firestoreService.saveCharacter(userId, character);
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Навыки сохранены')),
                            );
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Ошибка: $e')),
                            );
                          }
                        }
                      }
                      setState(() => _isEditingSkills = !_isEditingSkills);
                    },
                    tooltip: _isEditingSkills ? 'Сохранить' : 'Редактировать',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.95,
              children: [
                StatCard(
                  name: 'Сила',
                  abbreviation: 'STR',
                  value: character.strength,
                  modifier: character.getStrengthModifier(),
                  isSelected: _isAbilitySelected('Сила'),
                  onTap: () {
                    setState(() {
                      if (_isAbilitySelected('Сила')) {
                        selectedSkillFilter = null;
                      } else {
                        selectedSkillFilter = _getFirstSkillForAbility('Сила');
                      }
                    });
                  },
                ),
                StatCard(
                  name: 'Ловкость',
                  abbreviation: 'DEX',
                  value: character.dexterity,
                  modifier: character.getDexterityModifier(),
                  isSelected: _isAbilitySelected('Ловкость'),
                  onTap: () {
                    setState(() {
                      if (_isAbilitySelected('Ловкость')) {
                        selectedSkillFilter = null;
                      } else {
                        selectedSkillFilter = _getFirstSkillForAbility('Ловкость');
                      }
                    });
                  },
                ),
                StatCard(
                  name: 'Телоc.',
                  abbreviation: 'CON',
                  value: character.constitution,
                  modifier: character.getConstitutionModifier(),
                  isSelected: _isAbilitySelected('Телосложение'),
                  onTap: () {
                    setState(() {
                      if (_isAbilitySelected('Телосложение')) {
                        selectedSkillFilter = null;
                      } else {
                        selectedSkillFilter = _getFirstSkillForAbility('Телосложение');
                      }
                    });
                  },
                ),
                StatCard(
                  name: 'Интел.',
                  abbreviation: 'INT',
                  value: character.intelligence,
                  modifier: character.getIntelligenceModifier(),
                  isSelected: _isAbilitySelected('Интеллект'),
                  onTap: () {
                    setState(() {
                      if (_isAbilitySelected('Интеллект')) {
                        selectedSkillFilter = null;
                      } else {
                        selectedSkillFilter = _getFirstSkillForAbility('Интеллект');
                      }
                    });
                  },
                ),
                StatCard(
                  name: 'Мудрость',
                  abbreviation: 'WIS',
                  value: character.wisdom,
                  modifier: character.getWisdomModifier(),
                  isSelected: _isAbilitySelected('Мудрость'),
                  onTap: () {
                    setState(() {
                      if (_isAbilitySelected('Мудрость')) {
                        selectedSkillFilter = null;
                      } else {
                        selectedSkillFilter = _getFirstSkillForAbility('Мудрость');
                      }
                    });
                  },
                ),
                StatCard(
                  name: 'Харизма',
                  abbreviation: 'CHA',
                  value: character.charisma,
                  modifier: character.getCharismaModifier(),
                  isSelected: _isAbilitySelected('Харизма'),
                  onTap: () {
                    setState(() {
                      if (_isAbilitySelected('Харизма')) {
                        selectedSkillFilter = null;
                      } else {
                        selectedSkillFilter = _getFirstSkillForAbility('Харизма');
                      }
                    });
                  },
                ),
              ],
            ),
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

  // Секция пассивной внимательности
  Widget _buildPassivePerceptionSection(BuildContext context) {
    final passivePerception = character.getPassivePerception();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Пассивная внимательность:',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          Text(
            '$passivePerception',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }


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
                         // Чекбокс для мастерства (только если включен режим редактирования)
                         if (_isEditingSkills)
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
                           )
                         else
                           SizedBox(
                             width: 24,
                             height: 24,
                             child: Icon(
                               skill.isProficient ? Icons.check_circle : Icons.circle_outlined,
                               size: 20,
                               color: skill.isProficient ? Colors.green : Colors.grey,
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

