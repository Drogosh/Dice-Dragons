import 'package:flutter/material.dart';
import '../models/session.dart';
import '../models/request.dart';
import '../models/character.dart';
import '../services/realtime_requests_service.dart';
import '../services/realtime_responses_service.dart';

class SessionPlayerScreen extends StatefulWidget {
  final Session session;
  final String currentPlayerId;
  final String playerDisplayName;
  final Character? playerCharacter;
  final RealtimeRequestsService requestsService;
  final RealtimeResponsesService responsesService;

  const SessionPlayerScreen({
    super.key,
    required this.session,
    required this.currentPlayerId,
    required this.playerDisplayName,
    this.playerCharacter,
    required this.requestsService,
    required this.responsesService,
  });

  @override
  State<SessionPlayerScreen> createState() => _SessionPlayerScreenState();
}

class _SessionPlayerScreenState extends State<SessionPlayerScreen> {
  late Stream<List<Request>> _requestsStream;

  @override
  void initState() {
    super.initState();
    final playersCount = widget.session.getPlayers().length;
    _requestsStream = widget.requestsService.watchPlayerRequests(
      widget.session.id,
      widget.currentPlayerId,
      playersCount,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Мои запросы'),
      ),
      body: StreamBuilder<List<Request>>(
        stream: _requestsStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text('Нет открытых запросов'),
            );
          }

          final requests = snapshot.data!;
          return ListView.builder(
            itemCount: requests.length,
            itemBuilder: (context, index) {
              final request = requests[index];
              return RequestCard(
                request: request,
                sessionId: widget.session.id,
                currentPlayerId: widget.currentPlayerId,
                playerCharacter: widget.playerCharacter,
                playerDisplayName: widget.playerDisplayName,
                responsesService: widget.responsesService,
              );
            },
          );
        },
      ),
    );
  }
}

/// Карточка запроса с возможностью ответить
class RequestCard extends StatefulWidget {
  final Request request;
  final String sessionId;
  final String currentPlayerId;
  final Character? playerCharacter;
  final String playerDisplayName;
  final RealtimeResponsesService responsesService;

  const RequestCard({
    super.key,
    required this.request,
    required this.sessionId,
    required this.currentPlayerId,
    this.playerCharacter,
    required this.playerDisplayName,
    required this.responsesService,
  });

  @override
  State<RequestCard> createState() => _RequestCardState();
}

class _RequestCardState extends State<RequestCard> {
  late Future<bool> _hasResponded;

  @override
  void initState() {
    super.initState();
    _checkResponse();
  }

  void _checkResponse() {
    _hasResponded = widget.responsesService.hasPlayerResponded(
      widget.sessionId,
      widget.request.id ?? '',
      widget.currentPlayerId,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(8),
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
                      widget.request.type.name.toUpperCase(),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    if (widget.request.note != null)
                      Text(
                        widget.request.note!,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
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
                    widget.request.formula,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            FutureBuilder<bool>(
              future: _hasResponded,
              builder: (context, snapshot) {
                final responded = snapshot.data ?? false;
                
                if (responded) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.green.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.green.shade700, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          'Ответ отправлен',
                          style: TextStyle(
                            color: Colors.green.shade700,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  );
                }
                
                return ElevatedButton(
                  onPressed: () {
                    _showResponseDialog(context);
                  },
                  child: const Text('Ответить'),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showResponseDialog(BuildContext context) {
    final rollController = TextEditingController();
    String selectedMode = 'normal';

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Ответить на ${widget.request.type.name}'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Выберите значение на кубике:'),
                    const SizedBox(height: 8),
                    TextField(
                      controller: rollController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        hintText: 'Например: 15',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text('Режим броска:'),
                    const SizedBox(height: 8),
                    // Две CheckboxListTile - взаимоисключающие
                    CheckboxListTile(
                      title: const Text('✓ Преимущество'),
                      value: selectedMode == 'advantage',
                      onChanged: (value) {
                        setState(() {
                          selectedMode = value ?? false ? 'advantage' : 'normal';
                        });
                      },
                    ),
                    CheckboxListTile(
                      title: const Text('✗ Помеха'),
                      value: selectedMode == 'disadvantage',
                      onChanged: (value) {
                        setState(() {
                          selectedMode = value ?? false ? 'disadvantage' : 'normal';
                        });
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Отмена'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    await _submitResponse(selectedMode, rollController.text);
                    if (context.mounted) {
                      Navigator.pop(context);
                    }
                  },
                  child: const Text('Отправить'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _submitResponse(String mode, String rollText) async {
    final baseRoll = int.tryParse(rollText);
    if (baseRoll == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('❌ Введите число')),
        );
      }
      return;
    }

    if (widget.playerCharacter == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('❌ Персонаж не найден')),
        );
      }
      return;
    }

    try {
      // Вычислить модификатор на основе типа запроса и способности
      final modifier = _calculateModifier(
        widget.request.type,
        widget.request.abilityType,
        widget.playerCharacter!,
      );

      final total = baseRoll + modifier;

      // Проверить HIT/MISS для атак
      final success = widget.request.targetAc != null ? total >= widget.request.targetAc! : null;

      await widget.responsesService.submitResponse(
        sessionId: widget.sessionId,
        requestId: widget.request.id ?? '',
        uid: widget.currentPlayerId,
        displayName: widget.playerDisplayName,
        characterId: widget.playerCharacter!.id,
        characterName: widget.playerCharacter!.name,
        baseRoll: baseRoll,
        mode: mode,
        modifier: modifier,
        total: total,
        success: success,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Ответ отправлен')),
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

  /// Вычислить модификатор на основе типа запроса
  int _calculateModifier(
    RequestType type,
    AbilityType? abilityType,
    Character character,
  ) {
    switch (type) {
      case RequestType.initiative:
        return character.getDexterityModifier();

      case RequestType.attack:
        // По умолчанию STR, но можно переопределить в abilityType
        if (abilityType == AbilityType.dexterity) {
          return character.getDexterityModifier();
        }
        return character.getStrengthModifier();

      case RequestType.damage:
        // Для урона обычно используется STR
        return character.getStrengthModifier();

      case RequestType.check:
        // Для проверки используется указанная характеристика
        if (abilityType == null) return 0;
        switch (abilityType) {
          case AbilityType.strength:
            return character.getStrengthModifier();
          case AbilityType.dexterity:
            return character.getDexterityModifier();
          case AbilityType.constitution:
            return character.getConstitutionModifier();
          case AbilityType.intelligence:
            return character.getIntelligenceModifier();
          case AbilityType.wisdom:
            return character.getWisdomModifier();
          case AbilityType.charisma:
            return character.getCharismaModifier();
        }

      case RequestType.save:
        // Для спасброска используется характеристика спасброска с proficiency
        if (abilityType == null) return 0;
        switch (abilityType) {
          case AbilityType.strength:
            return character.getStrengthSave();
          case AbilityType.dexterity:
            return character.getDexteritySave();
          case AbilityType.constitution:
            return character.getConstitutionSave();
          case AbilityType.intelligence:
            return character.getIntelligenceSave();
          case AbilityType.wisdom:
            return character.getWisdomSave();
          case AbilityType.charisma:
            return character.getCharismaSave();
        }
    }
  }
}






