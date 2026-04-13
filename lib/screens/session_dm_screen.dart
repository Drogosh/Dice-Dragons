import 'package:flutter/material.dart';
import '../models/session.dart';
import '../models/request.dart';
import '../models/character.dart';
import '../models/roll_response.dart';
import '../services/realtime_requests_service.dart';
import '../services/realtime_responses_service.dart';

class SessionDMScreen extends StatefulWidget {
  final Session session;
  final Character? dmCharacter;
  final RealtimeRequestsService requestsService;
  final RealtimeResponsesService responsesService;

  const SessionDMScreen({
    super.key,
    required this.session,
    this.dmCharacter,
    required this.requestsService,
    required this.responsesService,
  });

  @override
  State<SessionDMScreen> createState() => _SessionDMScreenState();
}

class _SessionDMScreenState extends State<SessionDMScreen> {
  bool showRequestForm = false;
  late RequestType selectedType;

  final formulaController = TextEditingController();
  final targetAcController = TextEditingController();
  final noteController = TextEditingController();
  Set<String> selectedPlayerUids = {};
  String audience = 'all';

  @override
  void initState() {
    super.initState();
    selectedType = RequestType.check;
    formulaController.text = '1d20';
  }

  @override
  void dispose() {
    formulaController.dispose();
    targetAcController.dispose();
    noteController.dispose();
    super.dispose();
  }

  void _updateFormula() {
    // Просто используем введенную формулу
    debugPrint('Formula: ${formulaController.text}');
  }

  String _getTypeLabel(RequestType type) {
    switch (type) {
      case RequestType.initiative:
        return 'Инициатива';
      case RequestType.attack:
        return 'Атака';
      case RequestType.damage:
        return 'Урон';
      case RequestType.check:
        return 'Проверка';
      case RequestType.save:
        return 'Спасбросок';
    }
  }

  String _getAbilityLabel(AbilityType? ability) {
    if (ability == null) return 'нет';
    switch (ability) {
      case AbilityType.strength:
        return 'STR';
      case AbilityType.dexterity:
        return 'DEX';
      case AbilityType.constitution:
        return 'CON';
      case AbilityType.intelligence:
        return 'INT';
      case AbilityType.wisdom:
        return 'WIS';
      case AbilityType.charisma:
        return 'CHA';
    }
  }

  Future<void> _createRequest() async {
    if (widget.dmCharacter == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('❌ Ошибка: персонаж DM не найден')),
      );
      return;
    }

    try {
      final request = Request(
        id: null,
        sessionId: widget.session.id,
        dmId: widget.session.dmId,
        characterId: widget.dmCharacter!.id ?? '',
        characterName: widget.dmCharacter!.name,
        type: selectedType,
        formula: formulaController.text,
        modifier: widget.dmCharacter!.getStrengthModifier(),
        targetAc: int.tryParse(targetAcController.text),
        note: noteController.text.isNotEmpty ? noteController.text : null,
        status: 'open',
        audience: audience,
        targetUids: selectedPlayerUids.toList(),
      );

      await widget.requestsService.createRequest(
        sessionId: widget.session.id,
        dmId: widget.session.dmId,
        request: request,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Запрос создан')),
        );
      }

      _resetForm();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Ошибка: $e')),
        );
      }
    }
  }

  void _resetForm() {
    setState(() {
      showRequestForm = false;
      formulaController.text = '1d20';
      targetAcController.clear();
      noteController.clear();
      selectedPlayerUids.clear();
      audience = 'all';
      selectedType = RequestType.check;
    });
  }

  Future<void> _closeRequest(String requestId) async {
    try {
      await widget.requestsService.closeRequest(widget.session.id, requestId);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Запрос закрыт')),
      );
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
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Кнопка создать запрос
          ElevatedButton.icon(
            icon: const Icon(Icons.add),
            label: const Text('Новый запрос'),
            onPressed: () {
              setState(() {
                showRequestForm = !showRequestForm;
              });
            },
          ),
          const SizedBox(height: 16),

          // Форма создания запроса
          if (showRequestForm)
            Card(
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
                            label: Text(_getTypeLabel(type)),
                            selected: selectedType == type,
                            onSelected: (selected) {
                              setState(() {
                                selectedType = selected ? type : RequestType.check;
                              });
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),

                      // Формула
                      const Text('Формула:', style: TextStyle(fontWeight: FontWeight.bold)),
                      TextField(
                        controller: formulaController,
                        decoration: const InputDecoration(
                          hintText: '1d20, 2d6+3, и т.д.',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Target AC (только для атак)
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

                      // Заметка
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

                      // Аудитория
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

                      // Выбор игроков
                      if (audience == 'subset') ...[
                        const SizedBox(height: 8),
                        const Text('Выберите игроков:'),
                        ...widget.session.getPlayers().map((member) {
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

                      // Кнопки
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          ElevatedButton(
                            onPressed: _createRequest,
                            child: const Text('Создать'),
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

          // Список открытых запросов
          if (!showRequestForm) ...[
            const SizedBox(height: 16),
            const Text('Открытые запросы:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            StreamBuilder<List<Request>>(
              stream: widget.requestsService.watchDMRequests(widget.session.id),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const CircularProgressIndicator();
                }

                final requests = snapshot.data ?? [];
                if (requests.isEmpty) {
                  return const Center(child: Text('Нет открытых запросов'));
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: requests.length,
                  itemBuilder: (context, index) {
                    final request = requests[index];
                    return _buildRequestCard(request);
                  },
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRequestCard(Request request) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Заголовок
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getTypeLabel(request.type),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      if (request.note != null)
                        Text(
                          request.note!,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                    ],
                  ),
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

            if (request.targetAc != null) ...[
              const SizedBox(height: 8),
              Text('AC: ${request.targetAc}', style: const TextStyle(fontSize: 12)),
            ],

            // Ответы игроков
            const SizedBox(height: 12),
            StreamBuilder<Map<String, RollResponse>>(
              stream: widget.responsesService.watchResponses(widget.session.id, request.id ?? ''),
              builder: (context, snapshot) {
                final responses = snapshot.data ?? {};
                final expectedCount = request.audience == 'all'
                    ? widget.session.getPlayers().length
                    : request.targetUids.length;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ответы: ${responses.length}/$expectedCount',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                    const SizedBox(height: 8),
                    ...responses.values.map((response) {
                      final hit = response.success;
                      return Container(
                        padding: const EdgeInsets.all(8),
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              response.displayName,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              'Бросок: ${response.baseRoll} (${response.mode}) + ${response.modifier} = ${response.total}',
                              style: const TextStyle(fontSize: 12),
                            ),
                            if (hit != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                hit ? '✅ HIT' : '❌ MISS',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: hit ? Colors.green : Colors.red,
                                ),
                              ),
                            ],
                          ],
                        ),
                      );
                    }),
                  ],
                );
              },
            ),

            // Кнопка закрыть
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () => _closeRequest(request.id ?? ''),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              child: const Text('Закрыть'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    formulaController.dispose();
    targetAcController.dispose();
    noteController.dispose();
    super.dispose();
  }
}













