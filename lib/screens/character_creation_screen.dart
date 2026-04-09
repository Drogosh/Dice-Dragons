import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import '../models/character.dart';
import '../models/race.dart';
import '../models/character_class.dart';
import '../services/firestore_service.dart';

class CharacterCreationScreen extends StatefulWidget {
  const CharacterCreationScreen({super.key});

  @override
  State<CharacterCreationScreen> createState() => _CharacterCreationScreenState();
}

class _CharacterCreationScreenState extends State<CharacterCreationScreen> {
  final _firestoreService = FirestoreService();
  late String _userId;

  final _nameController = TextEditingController();

  // Атрибуты
  int _hp = 10;
  int _strength = 10;
  int _dexterity = 10;
  int _constitution = 10;
  int _intelligence = 10;
  int _wisdom = 10;
  int _charisma = 10;

  // Выбранные навыки (с профессиональностью)
  final Map<Skill, bool> _selectedSkills = {};

  // Раса и Класс
  Race? _selectedRace;
  CharacterClass? _selectedClass;

  // PointBuy система
  bool _usePointBuy = false;
  static const int POINTBUY_LIMIT = 27;

  bool _isLoading = false;
  String? _errorMessage;

  /// Таблица стоимости PointBuy
  /// Ключ - значение характеристики (8-15)
  /// Значение - стоимость в очках
  static const Map<int, int> pointBuyCost = {
    8: 0,
    9: 1,
    10: 2,
    11: 3,
    12: 4,
    13: 5,
    14: 7,
    15: 9,
  };

  /// Получить стоимость PointBuy для значения характеристики
  int _getPointBuyCost(int baseValue) {
    if (baseValue < 8 || baseValue > 15) return 0;
    return pointBuyCost[baseValue] ?? 0;
  }

  /// Получить общую стоимость PointBuy (без расовых бонусов)
  int _getTotalPointBuyCost() {
    int total = 0;
    total += _getPointBuyCost(_strength);
    total += _getPointBuyCost(_dexterity);
    total += _getPointBuyCost(_constitution);
    total += _getPointBuyCost(_intelligence);
    total += _getPointBuyCost(_wisdom);
    total += _getPointBuyCost(_charisma);
    return total;
  }

  /// Проверить, может ли быть установлено новое значение характеристики (PointBuy)
  bool _canSetAbilityScorePointBuy(int currentValue, int newValue) {
    int currentCost = _getPointBuyCost(currentValue);
    int newCost = _getPointBuyCost(newValue);
    int costDiff = newCost - currentCost;

    int currentTotal = _getTotalPointBuyCost();
    int newTotal = currentTotal + costDiff;

    return newTotal <= POINTBUY_LIMIT;
  }

  /// Получить сумму модификаторов
  int _getTotalModifierSum() {
    int total = 0;
    total += ((_strength + (_selectedRace?.strengthBonus ?? 0) - 10) ~/ 2);
    total += ((_dexterity + (_selectedRace?.dexterityBonus ?? 0) - 10) ~/ 2);
    total += ((_constitution + (_selectedRace?.constitutionBonus ?? 0) - 10) ~/ 2);
    total += ((_intelligence + (_selectedRace?.intelligenceBonus ?? 0) - 10) ~/ 2);
    total += ((_wisdom + (_selectedRace?.wisdomBonus ?? 0) - 10) ~/ 2);
    total += ((_charisma + (_selectedRace?.charismaBonus ?? 0) - 10) ~/ 2);
    return total;
  }

  /// Проверить, может ли быть установлено новое значение характеристики
  bool _canSetAbilityScore(int currentValue, int newValue, int raceBonus) {
    // Если режим PointBuy - проверяем ограничение 27 очков
    if (_usePointBuy) {
      return _canSetAbilityScorePointBuy(currentValue, newValue);
    }

    // Режим 1: БЕЗ ОГРАНИЧЕНИЙ
    return true;
  }

  @override
  void initState() {
    super.initState();
    _userId = fb.FirebaseAuth.instance.currentUser!.uid;

    // Инициализируем все навыки как неполученные
    for (final skill in Skill.values) {
      _selectedSkills[skill] = false;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _createCharacter() async {
    if (_nameController.text.isEmpty) {
      setState(() => _errorMessage = 'Введите имя персонажа');
      return;
    }

    if (_selectedRace == null) {
      setState(() => _errorMessage = 'Выберите расу');
      return;
    }

    if (_selectedClass == null) {
      setState(() => _errorMessage = 'Выберите класс');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Применяем бонусы расы к атрибутам
      int finalStrength = _strength + _selectedRace!.strengthBonus;
      int finalDexterity = _dexterity + _selectedRace!.dexterityBonus;
      int finalConstitution = _constitution + _selectedRace!.constitutionBonus;
      int finalIntelligence = _intelligence + _selectedRace!.intelligenceBonus;
      int finalWisdom = _wisdom + _selectedRace!.wisdomBonus;
      int finalCharisma = _charisma + _selectedRace!.charismaBonus;

      // Уровень по умолчанию = 1, AC будет рассчитываться автоматически
      final character = Character(
        name: _nameController.text,
        level: 1, // По умолчанию 1 уровень
        hp: _hp,
        ac: 10, // Базовый AC, будет пересчитываться с экипировкой
        strength: finalStrength,
        dexterity: finalDexterity,
        constitution: finalConstitution,
        intelligence: finalIntelligence,
        wisdom: finalWisdom,
        charisma: finalCharisma,
        raceId: _selectedRace!.id,
        raceName: _selectedRace!.name,
        className: _selectedClass!.id,
        classNameDisplay: _selectedClass!.name,
      );

      // Устанавливаем профессиональность выбранных навыков
      for (final skill in Skill.values) {
        if (_selectedSkills[skill] == true) {
          character.setProficiency(skill, true);
        }
      }

      // Сохраняем персонажа
      final charId = await _firestoreService.saveCharacter(_userId, character);

      // Создаем объект персонажа с ID
      final savedCharacter = character.copyWith(id: charId);

      if (mounted) {
        Navigator.of(context).pop(savedCharacter);
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Ошибка: $e';
        _isLoading = false;
      });
    }
  }

  /// Построить слайдер характеристики с отображением бонуса расы
  Widget _buildAttributeSliderWithRaceBonus(
    String label,
    int value,
    int raceBonus,
    Function(int) onChanged,
  ) {
    int effectiveValue = value + raceBonus;

    // Для PointBuy показываем стоимость вместо модификатора
    String costText = '';
    if (_usePointBuy) {
      int cost = _getPointBuyCost(value);
      costText = ' ($cost очков)';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label + costText,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
              ),
              Row(
                children: [
                  // Базовое значение
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '$value',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Бонус расы
                  if (raceBonus != 0)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green[800],
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '+$raceBonus',
                        style: const TextStyle(
                          color: Colors.greenAccent,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  const SizedBox(width: 8),
                  // Итоговое значение
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.purple[700],
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '= $effectiveValue',
                      style: const TextStyle(
                        color: Colors.purpleAccent,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          Slider(
            value: value.toDouble(),
            min: _usePointBuy ? 8 : 1,  // 8-15 для PointBuy, 1-20 для обычного
            max: _usePointBuy ? 15 : 20,
            divisions: _usePointBuy ? 7 : 19,
            activeColor: Colors.blue,
            inactiveColor: Colors.grey[600],
            onChanged: (val) {
              int newValue = val.toInt();
              if (_canSetAbilityScore(value, newValue, raceBonus)) {
                onChanged(newValue);
                setState(() => _errorMessage = null);
              } else {
                setState(() => _errorMessage = 'Недостаточно очков PointBuy (макс 27)');
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAttributeSlider(String label, int value, Function(int) onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
              ),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '$value',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Показываем бонус расы если она выбрана
                  if (_selectedRace != null)
                    Builder(
                      builder: (context) {
                        int raceBonus = 0;
                        if (label.contains('STR')) raceBonus = _selectedRace!.strengthBonus;
                        else if (label.contains('DEX')) raceBonus = _selectedRace!.dexterityBonus;
                        else if (label.contains('CON')) raceBonus = _selectedRace!.constitutionBonus;
                        else if (label.contains('INT')) raceBonus = _selectedRace!.intelligenceBonus;
                        else if (label.contains('WIS')) raceBonus = _selectedRace!.wisdomBonus;
                        else if (label.contains('CHA')) raceBonus = _selectedRace!.charismaBonus;

                        if (raceBonus == 0) return const SizedBox.shrink();

                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.green[800],
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '+$raceBonus',
                            style: const TextStyle(
                              color: Colors.greenAccent,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        );
                      },
                    ),
                ],
              ),
            ],
          ),
          Slider(
            value: value.toDouble(),
            min: 1,
            max: 20,
            divisions: 19,
            activeColor: Colors.blue,
            inactiveColor: Colors.grey[600],
            onChanged: (val) {
              int newValue = val.toInt();
              // Определяем бонус расы для этой характеристики
              int raceBonus = 0;
              if (label.contains('STR')) raceBonus = _selectedRace?.strengthBonus ?? 0;
              else if (label.contains('DEX')) raceBonus = _selectedRace?.dexterityBonus ?? 0;
              else if (label.contains('CON')) raceBonus = _selectedRace?.constitutionBonus ?? 0;
              else if (label.contains('INT')) raceBonus = _selectedRace?.intelligenceBonus ?? 0;
              else if (label.contains('WIS')) raceBonus = _selectedRace?.wisdomBonus ?? 0;
              else if (label.contains('CHA')) raceBonus = _selectedRace?.charismaBonus ?? 0;

              // Проверяем сумму модификаторов
              if (_canSetAbilityScore(value, newValue, raceBonus)) {
                onChanged(newValue);
                setState(() => _errorMessage = null);
              } else {
                setState(() => _errorMessage = 'Максимальная сумма модификаторов: 27');
              }
            },
          ),
        ],
      ),
    );
  }

  /// Получить навыки, связанные с характеристикой
  List<Skill> _getSkillsForAbility(String ability) {
    switch (ability) {
      case 'STR':
        return [Skill.athletics];
      case 'DEX':
        return [Skill.acrobatics, Skill.sleightOfHand, Skill.stealth];
      case 'CON':
        return []; // Телосложение напрямую не связано с навыками
      case 'INT':
        return [Skill.arcana, Skill.history, Skill.investigation, Skill.nature, Skill.religion];
      case 'WIS':
        return [
          Skill.animalHandling,
          Skill.insight,
          Skill.medicine,
          Skill.perception,
          Skill.survival,
        ];
      case 'CHA':
        return [Skill.deception, Skill.intimidation, Skill.performance, Skill.persuasion];
      default:
        return [];
    }
  }

  /// Получить русское название навыка
  String _getSkillName(Skill skill) {
    const skillNames = {
      Skill.acrobatics: 'Акробатика',
      Skill.animalHandling: 'Обращение с животными',
      Skill.arcana: 'Магия',
      Skill.athletics: 'Атлетика',
      Skill.deception: 'Обман',
      Skill.history: 'История',
      Skill.insight: 'Проницательность',
      Skill.intimidation: 'Запугивание',
      Skill.investigation: 'Расследование',
      Skill.medicine: 'Медицина',
      Skill.nature: 'Природа',
      Skill.perception: 'Восприятие',
      Skill.performance: 'Выступление',
      Skill.persuasion: 'Убеждение',
      Skill.religion: 'Религия',
      Skill.sleightOfHand: 'Ловкость рук',
      Skill.stealth: 'Скрытность',
      Skill.survival: 'Выживание',
    };
    return skillNames[skill] ?? skill.name;
  }

  /// Построить сворачиваемую секцию с выбором навыков
  Widget _buildSkillsExpansion(String abilityCode, String abilityName, int abilityValue) {
    final skills = _getSkillsForAbility(abilityCode);

    if (skills.isEmpty) {
      return const SizedBox.shrink();
    }

    final modifier = (abilityValue - 10) ~/ 2;
    final modifierStr = '${modifier > 0 ? '+' : ''}$modifier';

    return ExpansionTile(
      title: Text(
        'Навыки $abilityName ($abilityCode) $modifierStr',
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
      ),
      collapsedBackgroundColor: Colors.grey[850],
      backgroundColor: Colors.grey[800],
      childrenPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: skills.map((skill) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: CheckboxListTile(
                title: Text(
                  _getSkillName(skill),
                  style: const TextStyle(color: Colors.white),
                ),
                value: _selectedSkills[skill] ?? false,
                onChanged: (value) {
                  setState(() {
                    _selectedSkills[skill] = value ?? false;
                  });
                },
                activeColor: Colors.blue,
                checkColor: Colors.white,
                contentPadding: EdgeInsets.zero,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  /// Выбор расы
  void _showRaceSelectionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[850],
        title: const Text(
          'Выбор расы',
          style: TextStyle(color: Colors.white),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            itemCount: standardRaces.length,
            itemBuilder: (context, index) {
              final race = standardRaces[index];
              return GestureDetector(
                onTap: () {
                  setState(() => _selectedRace = race);
                  Navigator.pop(context);
                },
                child: Card(
                  color: Colors.grey[800],
                  margin: const EdgeInsets.only(bottom: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          race.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          race.description,
                          style: TextStyle(color: Colors.grey[400], fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Закрыть'),
          ),
        ],
      ),
    );
  }

  /// Выбор класса
  void _showClassSelectionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[850],
        title: const Text(
          'Выбор класса',
          style: TextStyle(color: Colors.white),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            itemCount: standardClasses.length,
            itemBuilder: (context, index) {
              final charClass = standardClasses[index];
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedClass = charClass;
                    // Авторасчет HP: кость хитов + модификатор телосложения на 1 уровне
                    int conModifier = (_constitution + (_selectedRace?.constitutionBonus ?? 0) - 10) ~/ 2;
                    _hp = charClass.hitDice + conModifier;
                  });
                  Navigator.pop(context);
                },
                child: Card(
                  color: Colors.grey[800],
                  margin: const EdgeInsets.only(bottom: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              charClass.name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.purple[700],
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                charClass.primaryAbility,
                                style: const TextStyle(
                                  color: Colors.purpleAccent,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          charClass.description,
                          style: TextStyle(color: Colors.grey[400], fontSize: 12),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Кость здоровья: d${charClass.hitDice}',
                          style: TextStyle(color: Colors.blue[300], fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Закрыть'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        title: const Text('Создание персонажа'),
        backgroundColor: Colors.grey[800],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
             children: [
               // PointBuy галочка и имя персонажа на одной строке
               Row(
                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
                 children: [
                   Text(
                     'Имя персонажа',
                     style: Theme.of(context).textTheme.titleMedium?.copyWith(
                           color: Colors.white,
                         ),
                   ),
                   Row(
                     children: [
                       Checkbox(
                         value: _usePointBuy,
                         onChanged: (value) {
                           setState(() {
                             _usePointBuy = value ?? false;
                             _errorMessage = null;
                           });
                         },
                         activeColor: Colors.orange,
                         checkColor: Colors.white,
                       ),
                       Text(
                         'PointBuy 27',
                         style: TextStyle(
                           color: _usePointBuy ? Colors.orange : Colors.grey[400],
                           fontSize: 12,
                           fontWeight: FontWeight.w500,
                         ),
                       ),
                     ],
                   ),
                 ],
               ),
               const SizedBox(height: 8),
               TextField(
                 controller: _nameController,
                 decoration: InputDecoration(
                   hintText: 'Введите имя',
                   border: OutlineInputBorder(
                     borderRadius: BorderRadius.circular(8),
                   ),
                   filled: true,
                   fillColor: Colors.grey[800],
                   hintStyle: TextStyle(color: Colors.grey[500]),
                 ),
               ),
              const SizedBox(height: 24),

              // Раса и Класс
              Text(
                'Раса и Класс',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                    ),
              ),
              const SizedBox(height: 12),

              // Выбор расы
              GestureDetector(
                onTap: _showRaceSelectionDialog,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: _selectedRace == null ? Colors.grey[600]! : Colors.blue,
                    ),
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.grey[800],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Раса',
                            style: TextStyle(color: Colors.grey[500], fontSize: 12),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _selectedRace?.name ?? 'Выбрать расу',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                      Icon(Icons.arrow_forward, color: Colors.grey[500]),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Выбор класса
              GestureDetector(
                onTap: _showClassSelectionDialog,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: _selectedClass == null ? Colors.grey[600]! : Colors.blue,
                    ),
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.grey[800],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Класс',
                            style: TextStyle(color: Colors.grey[500], fontSize: 12),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Text(
                                _selectedClass?.name ?? 'Выбрать класс',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500,
                                  fontSize: 16,
                                ),
                              ),
                              if (_selectedClass != null) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.purple[700],
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    _selectedClass!.primaryAbility,
                                    style: const TextStyle(
                                      color: Colors.purpleAccent,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                      Icon(Icons.arrow_forward, color: Colors.grey[500]),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Атрибуты с навыками
              Text(
                'Характеристики и навыки',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                    ),
              ),
              const SizedBox(height: 8),

              // Отображение суммы PointBuy (только если включен)
              if (_usePointBuy)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[800],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _getTotalPointBuyCost() > POINTBUY_LIMIT ? Colors.red : Colors.blue,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'PointBuy очки:',
                        style: TextStyle(color: Colors.grey[400]),
                      ),
                      Text(
                        '${_getTotalPointBuyCost()} / $POINTBUY_LIMIT',
                        style: TextStyle(
                          color: _getTotalPointBuyCost() > POINTBUY_LIMIT
                              ? Colors.red
                              : Colors.greenAccent,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              if (_usePointBuy) const SizedBox(height: 12),

              // Сила (STR)
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey[800],
                  borderRadius: BorderRadius.circular(8),
                ),
                margin: const EdgeInsets.only(bottom: 12),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: _buildAttributeSliderWithRaceBonus(
                        'Сила (STR)',
                        _strength,
                        _selectedRace?.strengthBonus ?? 0,
                        (value) => setState(() => _strength = value),
                      ),
                    ),
                    _buildSkillsExpansion(
                      'STR',
                      'Сила',
                      _strength + (_selectedRace?.strengthBonus ?? 0),
                    ),
                  ],
                ),
              ),

              // Ловкость (DEX)
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey[800],
                  borderRadius: BorderRadius.circular(8),
                ),
                margin: const EdgeInsets.only(bottom: 12),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: _buildAttributeSliderWithRaceBonus(
                        'Ловкость (DEX)',
                        _dexterity,
                        _selectedRace?.dexterityBonus ?? 0,
                        (value) => setState(() => _dexterity = value),
                      ),
                    ),
                    _buildSkillsExpansion(
                      'DEX',
                      'Ловкость',
                      _dexterity + (_selectedRace?.dexterityBonus ?? 0),
                    ),
                  ],
                ),
              ),

              // Телосложение (CON)
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey[800],
                  borderRadius: BorderRadius.circular(8),
                ),
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                child: _buildAttributeSliderWithRaceBonus(
                  'Телосложение (CON)',
                  _constitution,
                  _selectedRace?.constitutionBonus ?? 0,
                  (value) => setState(() => _constitution = value),
                ),
              ),

              // Интеллект (INT)
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey[800],
                  borderRadius: BorderRadius.circular(8),
                ),
                margin: const EdgeInsets.only(bottom: 12),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: _buildAttributeSliderWithRaceBonus(
                        'Интеллект (INT)',
                        _intelligence,
                        _selectedRace?.intelligenceBonus ?? 0,
                        (value) => setState(() => _intelligence = value),
                      ),
                    ),
                    _buildSkillsExpansion(
                      'INT',
                      'Интеллект',
                      _intelligence + (_selectedRace?.intelligenceBonus ?? 0),
                    ),
                  ],
                ),
              ),

              // Мудрость (WIS)
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey[800],
                  borderRadius: BorderRadius.circular(8),
                ),
                margin: const EdgeInsets.only(bottom: 12),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: _buildAttributeSliderWithRaceBonus(
                        'Мудрость (WIS)',
                        _wisdom,
                        _selectedRace?.wisdomBonus ?? 0,
                        (value) => setState(() => _wisdom = value),
                      ),
                    ),
                    _buildSkillsExpansion(
                      'WIS',
                      'Мудрость',
                      _wisdom + (_selectedRace?.wisdomBonus ?? 0),
                    ),
                  ],
                ),
              ),

              // Харизма (CHA)
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey[800],
                  borderRadius: BorderRadius.circular(8),
                ),
                margin: const EdgeInsets.only(bottom: 12),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: _buildAttributeSliderWithRaceBonus(
                        'Харизма (CHA)',
                        _charisma,
                        _selectedRace?.charismaBonus ?? 0,
                        (value) => setState(() => _charisma = value),
                      ),
                    ),
                    _buildSkillsExpansion(
                      'CHA',
                      'Харизма',
                      _charisma + (_selectedRace?.charismaBonus ?? 0),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Ошибка
              if (_errorMessage != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red[900],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              const SizedBox(height: 16),

              // Кнопки
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[700],
                      ),
                      child: const Text('Отмена'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _createCharacter,
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Создать'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}













