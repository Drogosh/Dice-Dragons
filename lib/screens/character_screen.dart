import 'package:dice_and_dragons/widgets/skill_item_widget.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/character.dart';
import '../services/firestore_service.dart';
import '../widgets/stat_card.dart';
import '../widgets/abilities_row.dart';
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
  String? selectedAbility;
  bool _isEditingSkills = false;

  @override
  void initState() {
    super.initState();
    character = widget.character;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/stats_widget/background.png'),
          fit: BoxFit.cover,
        ),
      ),
      child: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/stats_widget/background.png'),
            fit: BoxFit.cover,
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
                    AbilitiesRow(
                      character: character,
                      selectedAbility: selectedAbility,
                      onAbilityTap: (ability) {
                        setState(() {
                          selectedAbility = ability;
                          if (ability != null) {
                            selectedSkillFilter = _getFirstSkillForAbility(ability);
                          } else {
                            selectedSkillFilter = null;
                          }
                        });
                      },
                    ),
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
      ),
    );
  }

  // ...existing code...

  // ...existing code...

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

  // Преобразует английские сокращения в русские
  String _getRussianAbilityAbbr(String ability) {
    switch (ability) {
      case 'STR':
        return 'СИЛ';
      case 'DEX':
        return 'ЛОВ';
      case 'CON':
        return 'ТЕЛ';
      case 'INT':
        return 'ИНТ';
      case 'WIS':
        return 'МУД';
      case 'CHA':
        return 'ХАР';
      default:
        return ability;
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
          Row(
            children: [
              Text(
                '$passivePerception',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 12),
              Container(
                decoration: BoxDecoration(
                  color: _isEditingSkills ? Colors.orange : Colors.grey[700],
                  borderRadius: BorderRadius.circular(6),
                ),
                child: IconButton(
                  icon: Icon(
                    _isEditingSkills ? Icons.check : Icons.edit,
                    color: Colors.white,
                    size: 18,
                  ),
                  iconSize: 18,
                  padding: const EdgeInsets.all(6),
                  constraints: const BoxConstraints(
                    minHeight: 32,
                    minWidth: 32,
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
                  tooltip: _isEditingSkills ? 'Сохранить' : 'Редактировать навыки',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }


  Widget _buildSkillsSection(BuildContext context) {
    final filteredSkills = _getFilteredSkills();

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        image: const DecorationImage(
          image: AssetImage('assets/stats_widget/skills_bg.png'),
          fit: BoxFit.cover,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 🔹 Заголовок
          Text(
            'Навыки (${filteredSkills.length}/${character.skills.length})',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: const Color(0xFF3E2C1C),
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 12),

          // 🔹 Список навыков
          SizedBox(
            height: 300,
            child: ListView.builder(
              itemCount: filteredSkills.length,
              itemBuilder: (context, index) {
                final skill = filteredSkills[index];
                final bonus = character.getSkillBonus(skill.skill);

                return SkillItemWidget(
                  name: skill.name,
                  ability: _getRussianAbilityAbbr(_getAbilityForSkill(skill.skill)),
                  bonus: bonus,
                  isProficient: skill.isProficient,
                  isEditing: _isEditingSkills,
                  isFiltered: _isAbilityFiltered(_getAbilityForSkill(skill.skill)),
                  onToggle: () {
                    setState(() {
                      character.setProficiency(
                        skill.skill,
                        !skill.isProficient,
                      );
                    });
                  },
                );
              },
            ),
          ),
        ],
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

  // Получает первый навык для характеристики
  Skill _getFirstSkillForAbility(String abilityCode) {
    final allSkills = character.skills.keys.toList();
    return allSkills.firstWhere((skill) =>
        _getAbilityForSkill(skill) == abilityCode);
  }

  // Проверяет, отфильтрована ли эта характеристика
  bool _isAbilityFiltered(String ability) {
    return selectedAbility == ability;
  }
}

