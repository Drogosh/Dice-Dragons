import 'package:flutter/material.dart';
import '../models/session.dart';
import '../models/request.dart';
import '../models/character.dart';
import '../services/session_service.dart';

enum DiceType { d4, d6, d8, d10, d12, d20 }
enum DiceModifier { normal, advantage, disadvantage }
enum AbilityModifier { none, strength, dexterity, constitution, intelligence, wisdom, charisma }
enum SkillType { none, acrobatics, animalHandling, arcana, athletics, deception, history, insight, intimidation, investigation, medicine, nature, perception, performance, persuasion, religion, sleightOfHand, stealth, survival }

class SessionDMScreen extends StatefulWidget {
  final Session session;
  final SessionService sessionService;
  final Character? dmCharacter;

  const SessionDMScreen({
    super.key,
    required this.session,
    required this.sessionService,
    this.dmCharacter,
  });

  @override
  State<SessionDMScreen> createState() => _SessionDMScreenState();
}

class _SessionDMScreenState extends State<SessionDMScreen> {
  late List<Request> requests;
  late List<SessionMember> members;
  bool showRequestForm = false;

  final typeController = TextEditingController();
  final formulaController = TextEditingController();
  final targetAcController = TextEditingController();
  final noteController = TextEditingController();
  Set<String> selectedPlayerUids = {};
  RequestType? selectedType;
  String audience = 'all';

  // Новые переменные для расширенного выбора кубиков
  DiceType selectedDice = DiceType.d20;
  DiceModifier diceModifier = DiceModifier.normal;
  AbilityModifier abilityModifier = AbilityModifier.none;
  SkillType skillType = SkillType.none;
  int modifierBonus = 0;

  @override
  void initState() {
    super.initState();
    requests = [];
    members = [];
    formulaController.text = '1d20';
    _loadData();
  }

  void _updateFormula() {
    String formula = '';

    // Основная формула с кубиком
    if (diceModifier == DiceModifier.normal) {
      formula = '1${_getDiceName(selectedDice)}';
    } else if (diceModifier == DiceModifier.advantage) {
      formula = '2${_getDiceName(selectedDice)}kh1';
    } else if (diceModifier == DiceModifier.disadvantage) {
      formula = '2${_getDiceName(selectedDice)}kl1';
    }

    // Добавить модификатор характеристики
    if (abilityModifier != AbilityModifier.none) {
      formula += ' + ${_getAbilityModifier(abilityModifier)}';
    }

    // Добавить бонус модификатора
    if (modifierBonus != 0) {
      formula += modifierBonus > 0 ? ' + $modifierBonus' : ' $modifierBonus';
    }

    setState(() {
      formulaController.text = formula;
    });
  }

  String _getDiceName(DiceType dice) {
    switch (dice) {
      case DiceType.d4:
        return 'd4';
      case DiceType.d6:
        return 'd6';
      case DiceType.d8:
        return 'd8';
      case DiceType.d10:
        return 'd10';
      case DiceType.d12:
        return 'd12';
      case DiceType.d20:
        return 'd20';
    }
  }

  String _getAbilityModifier(AbilityModifier ability) {
    switch (ability) {
      case AbilityModifier.none:
        return '';
      case AbilityModifier.strength:
        return 'STR';
      case AbilityModifier.dexterity:
        return 'DEX';
      case AbilityModifier.constitution:
        return 'CON';
      case AbilityModifier.intelligence:
        return 'INT';
      case AbilityModifier.wisdom:
        return 'WIS';
      case AbilityModifier.charisma:
        return 'CHA';
    }
  }

  String _getSkillName(SkillType skill) {
    switch (skill) {
      case SkillType.none:
        return 'Нет навыка';
      case SkillType.acrobatics:
        return 'Акробатика';
      case SkillType.animalHandling:
        return 'Обращение с животными';
      case SkillType.arcana:
        return 'Магия';
      case SkillType.athletics:
        return 'Атлетика';
      case SkillType.deception:
        return 'Обман';
      case SkillType.history:
        return 'История';
      case SkillType.insight:
        return 'Проницательность';
      case SkillType.intimidation:
        return 'Запугивание';
      case SkillType.investigation:
        return 'Расследование';
      case SkillType.medicine:
        return 'Медицина';
      case SkillType.nature:
        return 'Природа';
      case SkillType.perception:
        return 'Восприятие';
      case SkillType.performance:
        return 'Исполнение';
      case SkillType.persuasion:
        return 'Убеждение';
      case SkillType.religion:
        return 'Религия';
      case SkillType.sleightOfHand:
        return 'Ловкость рук';
      case SkillType.stealth:
        return 'Скрытность';
      case SkillType.survival:
        return 'Выживание';
    }
  }

  Future<void> _loadData() async {
    try {
      final loadedRequests = await widget.sessionService.getRequests(widget.session.id);
      final loadedMembers = await widget.sessionService.watchMembers(widget.session.id).first;

      setState(() {
        requests = loadedRequests;
        members = loadedMembers.where((m) => m.role == SessionRole.player).toList();
      });
    } catch (e) {
      debugPrint('Error loading data: $e');
    }
  }

  Future<void> _createRequest() async {
    if (selectedType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Выберите тип запроса')),
      );
      return;
    }

    if (audience == 'subset' && selectedPlayerUids.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Выберите хотя бы одного игрока')),
      );
      return;
    }

    if (widget.dmCharacter == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ошибка: персонаж DM не найден')),
      );
      return;
    }

    try {
      int? targetAc;
      if (selectedType == RequestType.attack && targetAcController.text.isNotEmpty) {
        targetAc = int.tryParse(targetAcController.text);
      }

      await widget.sessionService.createRequest(
        sessionId: widget.session.id,
        character: widget.dmCharacter!,
        type: selectedType!,
        baseFormula: formulaController.text,
        targetAc: targetAc,
        note: noteController.text.isNotEmpty ? noteController.text : null,
        abilityType: null,
        audience: audience,
        targetUids: audience == 'subset' ? selectedPlayerUids.toList() : [],
      );

      setState(() {
        showRequestForm = false;
        selectedPlayerUids.clear();
        audience = 'all';
        selectedType = null;
      });

      _loadData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Запрос отправлен')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Ошибка: $e')),
        );
      }
    }
  }

  Future<void> _closeRequest(String requestId) async {
    try {
      await widget.sessionService.closeRequest(widget.session.id, requestId);
      _loadData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Ошибка: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Сессия: ${widget.session.name} (DM)'),
      ),
      body: Column(
        children: [
          // Блок с кодом присоединения
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade900,
              border: Border(
                bottom: BorderSide(
                  color: Colors.blue.shade700,
                  width: 2,
                ),
              ),
            ),
            child: Column(
              children: [
                const Text(
                  'Код присоединения для игроков:',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Код ${widget.session.joinCode} скопирован'),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade800,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.blue.shade600,
                        width: 1,
                      ),
                    ),
                    child: Text(
                      widget.session.joinCode,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Кнопка новый бросок
          Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('Новый бросок'),
              onPressed: () {
                setState(() {
                  showRequestForm = !showRequestForm;
                });
              },
            ),
          ),

          // Форма или список
          Expanded(
            child: showRequestForm
                ? Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Тип запроса
                              const Text('Тип:', style: TextStyle(fontWeight: FontWeight.bold)),
                              Wrap(
                                spacing: 8,
                                children: RequestType.values.map((type) {
                                  return ChoiceChip(
                                    label: Text(type.toString().split('.').last),
                                    selected: selectedType == type,
                                    onSelected: (selected) {
                                      setState(() {
                                        selectedType = selected ? type : null;
                                      });
                                    },
                                  );
                                }).toList(),
                              ),
                              const SizedBox(height: 16),

                              // Кубик
                              const Text('Кубик:', style: TextStyle(fontWeight: FontWeight.bold)),
                              Wrap(
                                spacing: 8,
                                children: DiceType.values.map((dice) {
                                  return ChoiceChip(
                                    label: Text(_getDiceName(dice)),
                                    selected: selectedDice == dice,
                                    onSelected: (selected) {
                                      setState(() {
                                        selectedDice = selected ? dice : DiceType.d20;
                                        _updateFormula();
                                      });
                                    },
                                  );
                                }).toList(),
                              ),
                              const SizedBox(height: 16),

                              // Модификатор броска
                              const Text('Модификатор броска:', style: TextStyle(fontWeight: FontWeight.bold)),
                              Wrap(
                                spacing: 8,
                                children: [
                                  ChoiceChip(
                                    label: const Text('Обычный'),
                                    selected: diceModifier == DiceModifier.normal,
                                    onSelected: (selected) {
                                      setState(() {
                                        diceModifier = DiceModifier.normal;
                                        _updateFormula();
                                      });
                                    },
                                  ),
                                  ChoiceChip(
                                    label: const Text('✓ Преимущество'),
                                    selected: diceModifier == DiceModifier.advantage,
                                    onSelected: (selected) {
                                      setState(() {
                                        diceModifier = DiceModifier.advantage;
                                        _updateFormula();
                                      });
                                    },
                                  ),
                                  ChoiceChip(
                                    label: const Text('✗ Помеха'),
                                    selected: diceModifier == DiceModifier.disadvantage,
                                    onSelected: (selected) {
                                      setState(() {
                                        diceModifier = DiceModifier.disadvantage;
                                        _updateFormula();
                                      });
                                    },
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),

                              // Модификатор характеристики
                              const Text('Модификатор характеристики:', style: TextStyle(fontWeight: FontWeight.bold)),
                              Wrap(
                                spacing: 8,
                                children: AbilityModifier.values.map((ability) {
                                  String label = ability == AbilityModifier.none ? 'Нет' : _getAbilityModifier(ability);
                                  return ChoiceChip(
                                    label: Text(label),
                                    selected: abilityModifier == ability,
                                    onSelected: (selected) {
                                      setState(() {
                                        abilityModifier = selected ? ability : AbilityModifier.none;
                                        _updateFormula();
                                      });
                                    },
                                  );
                                }).toList(),
                              ),
                              const SizedBox(height: 16),

                              // Навык
                              const Text('Навык:', style: TextStyle(fontWeight: FontWeight.bold)),
                              DropdownButton<SkillType>(
                                value: skillType,
                                isExpanded: true,
                                onChanged: (newSkill) {
                                  setState(() {
                                    skillType = newSkill ?? SkillType.none;
                                  });
                                },
                                items: SkillType.values.map((skill) {
                                  return DropdownMenuItem(
                                    value: skill,
                                    child: Text(_getSkillName(skill)),
                                  );
                                }).toList(),
                              ),
                              const SizedBox(height: 16),

                              // Бонус
                              const Text('Бонус/Штраф:', style: TextStyle(fontWeight: FontWeight.bold)),
                              TextField(
                                keyboardType: TextInputType.number,
                                onChanged: (value) {
                                  setState(() {
                                    modifierBonus = int.tryParse(value) ?? 0;
                                    _updateFormula();
                                  });
                                },
                                decoration: const InputDecoration(
                                  hintText: '0',
                                  border: OutlineInputBorder(),
                                ),
                              ),
                              const SizedBox(height: 16),

                              // Формула
                              const Text('Итоговая формула:', style: TextStyle(fontWeight: FontWeight.bold)),
                              TextField(
                                controller: formulaController,
                                readOnly: true,
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                ),
                              ),
                              const SizedBox(height: 16),

                              if (selectedType == RequestType.attack) ...[
                                const Text('AC цели:', style: TextStyle(fontWeight: FontWeight.bold)),
                                TextField(
                                  controller: targetAcController,
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(
                                    hintText: '15',
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                                const SizedBox(height: 16),
                              ],

                              const Text('Заметка:', style: TextStyle(fontWeight: FontWeight.bold)),
                              TextField(
                                controller: noteController,
                                maxLines: 2,
                                decoration: const InputDecoration(
                                  hintText: 'Описание запроса',
                                  border: OutlineInputBorder(),
                                ),
                              ),
                              const SizedBox(height: 16),

                              const Text('Аудитория:', style: TextStyle(fontWeight: FontWeight.bold)),
                              Column(
                                children: [
                                  RadioListTile<String>(
                                    title: const Text('Всем игрокам'),
                                    value: 'all',
                                    groupValue: audience,
                                    onChanged: (value) {
                                      setState(() {
                                        audience = value ?? 'all';
                                        selectedPlayerUids.clear();
                                      });
                                    },
                                  ),
                                  RadioListTile<String>(
                                    title: const Text('Конкретным игрокам'),
                                    value: 'subset',
                                    groupValue: audience,
                                    onChanged: (value) {
                                      setState(() {
                                        audience = value ?? 'all';
                                      });
                                    },
                                  ),
                                ],
                              ),

                              if (audience == 'subset') ...[
                                const SizedBox(height: 8),
                                const Text('Выберите игроков:'),
                                ...members.map((member) {
                                  return CheckboxListTile(
                                    title: Text(member.displayName),
                                    value: selectedPlayerUids.contains(member.uid),
                                    onChanged: (selected) {
                                      setState(() {
                                        if (selected == true) {
                                          selectedPlayerUids.add(member.uid);
                                        } else {
                                          selectedPlayerUids.remove(member.uid);
                                        }
                                      });
                                    },
                                  );
                                }),
                              ],

                              const SizedBox(height: 16),

                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: [
                                  ElevatedButton(
                                    onPressed: _createRequest,
                                    child: const Text('Отправить'),
                                  ),
                                  ElevatedButton(
                                    onPressed: () {
                                      setState(() {
                                        showRequestForm = false;
                                      });
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.grey,
                                    ),
                                    child: const Text('Отмена'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  )
                : requests.isEmpty
                    ? const Center(child: Text('Нет запросов'))
                    : ListView.builder(
                        itemCount: requests.length,
                        itemBuilder: (context, index) {
                          final request = requests[index];
                          final isOpen = request.status == 'open';

                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            request.characterName,
                                            style: const TextStyle(fontWeight: FontWeight.bold),
                                          ),
                                          Text(
                                            request.type.toString().split('.').last,
                                            style: const TextStyle(fontSize: 12),
                                          ),
                                        ],
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: Colors.blue.shade100,
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          request.formula,
                                          style: const TextStyle(fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (request.note != null) ...[
                                    const SizedBox(height: 8),
                                    Text(
                                      request.note!,
                                      style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                                    ),
                                  ],
                                  if (request.audience == 'subset') ...[
                                    const SizedBox(height: 8),
                                    Text(
                                      '👥 Игроки: ${request.targetUids.length}',
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  ],
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        isOpen ? '🟢 ОТКРЫТ' : '🔴 ЗАКРЫТ',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: isOpen ? Colors.green : Colors.red,
                                        ),
                                      ),
                                      if (isOpen)
                                        ElevatedButton(
                                          onPressed: () => _closeRequest(request.id ?? ''),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.red,
                                          ),
                                          child: const Text('Закрыть'),
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    typeController.dispose();
    formulaController.dispose();
    targetAcController.dispose();
    noteController.dispose();
    super.dispose();
  }
}

















