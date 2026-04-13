import 'package:flutter/material.dart';
import '../models/session.dart';
import '../models/request.dart';
import '../models/character.dart';
import '../services/session_service.dart';

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

  @override
  void initState() {
    super.initState();
    requests = [];
    members = [];
    formulaController.text = '1d20';
    _loadData();
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

          // Форма создания запроса
          if (showRequestForm)
            Padding(
              padding: const EdgeInsets.all(16),
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

                        // Формула
                        const Text('Формула:', style: TextStyle(fontWeight: FontWeight.bold)),
                        TextField(
                          controller: formulaController,
                          decoration: const InputDecoration(
                            hintText: '1d20',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Target AC (только для attack)
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

                        // Note
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

                        // Кнопки
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
            ),

          // Список запросов
          Expanded(
            child: requests.isEmpty
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




