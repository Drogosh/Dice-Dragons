import 'package:flutter/material.dart';
import '../models/character.dart';
import '../models/request.dart';
import '../services/session_service.dart';

/// Виджет для создания и отправки запросов (requests) в сессию
class RequestsPanel extends StatefulWidget {
  final SessionService sessionService;
  final String sessionId;
  final Character character;

  const RequestsPanel({
    super.key,
    required this.sessionService,
    required this.sessionId,
    required this.character,
  });

  @override
  State<RequestsPanel> createState() => _RequestsPanelState();
}

class _RequestsPanelState extends State<RequestsPanel> {
  List<Request> requests = [];

  @override
  void initState() {
    super.initState();
    _loadRequests();
    // Слушаем обновления запросов в реальном времени
    widget.sessionService.watchRequests(widget.sessionId).listen((newRequests) {
      setState(() {
        requests = newRequests;
      });
    });
  }

  Future<void> _loadRequests() async {
    final loadedRequests = await widget.sessionService.getRequests(widget.sessionId);
    setState(() {
      requests = loadedRequests;
    });
  }

  Future<void> _createRequest(RequestType type, AbilityType? abilityType) async {
    try {
      await widget.sessionService.createRequest(
        sessionId: widget.sessionId,
        character: widget.character,
        type: type,
        baseFormula: type == RequestType.damage ? '1d8' : '1d20',
        note: _getRequestNote(type),
        abilityType: abilityType,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: $e')),
        );
      }
    }
  }

  String _getRequestNote(RequestType type) {
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

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Кнопки для основных запросов
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                _buildRequestButton(
                  'Инициатива',
                  Icons.flash_on,
                  () => _createRequest(RequestType.initiative, null),
                ),
                _buildRequestButton(
                  'Атака',
                  Icons.sports_mma,
                  () => _createRequest(RequestType.attack, null),
                ),
                _buildRequestButton(
                  'Урон',
                  Icons.favorite,
                  () => _createRequest(RequestType.damage, null),
                ),
                PopupMenuButton<AbilityType>(
                  onSelected: (ability) {
                    _createRequest(RequestType.check, ability);
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: AbilityType.strength,
                      child: Row(
                        children: const [
                          Icon(Icons.fitness_center, size: 16),
                          SizedBox(width: 8),
                          Text('Сила'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: AbilityType.dexterity,
                      child: Row(
                        children: const [
                          Icon(Icons.directions_run, size: 16),
                          SizedBox(width: 8),
                          Text('Ловкость'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: AbilityType.constitution,
                      child: Row(
                        children: const [
                          Icon(Icons.shield, size: 16),
                          SizedBox(width: 8),
                          Text('Телосложение'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: AbilityType.intelligence,
                      child: Row(
                        children: const [
                          Icon(Icons.lightbulb, size: 16),
                          SizedBox(width: 8),
                          Text('Интеллект'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: AbilityType.wisdom,
                      child: Row(
                        children: const [
                          Icon(Icons.visibility, size: 16),
                          SizedBox(width: 8),
                          Text('Мудрость'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: AbilityType.charisma,
                      child: Row(
                        children: const [
                          Icon(Icons.person, size: 16),
                          SizedBox(width: 8),
                          Text('Харизма'),
                        ],
                      ),
                    ),
                  ],
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Row(
                      children: const [
                        Icon(Icons.check_circle_outline),
                        SizedBox(width: 4),
                        Text('Проверка'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        // Список запросов
        Expanded(
          child: requests.isEmpty
              ? Center(
                  child: Text(
                    'Нет запросов',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                )
              : ListView.builder(
                  itemCount: requests.length,
                  itemBuilder: (context, index) {
                    final request = requests[index];
                    return _buildRequestCard(request);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildRequestButton(
    String label,
    IconData icon,
    VoidCallback onPressed,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: ElevatedButton.icon(
        icon: Icon(icon, size: 16),
        label: Text(label),
        onPressed: onPressed,
      ),
    );
  }

  Widget _buildRequestCard(Request request) {
    final typeIcon = _getTypeIcon(request.type);
    final typeLabel = request.type.toString().split('.').last;

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
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        request.characterName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(typeIcon, size: 16),
                          const SizedBox(width: 8),
                          Text(
                            typeLabel,
                            style: const TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    request.formula,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
              ],
            ),
            if (request.note != null) ...[
              const SizedBox(height: 8),
              Text(
                request.note!,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
            if (request.targetAc != null) ...[
              const SizedBox(height: 8),
              Text(
                'AC: ${request.targetAc}',
                style: const TextStyle(fontSize: 12),
              ),
            ],
          ],
        ),
      ),
    );
  }

  IconData _getTypeIcon(RequestType type) {
    switch (type) {
      case RequestType.initiative:
        return Icons.flash_on;
      case RequestType.attack:
        return Icons.sports_mma;
      case RequestType.damage:
        return Icons.favorite;
      case RequestType.check:
        return Icons.check_circle;
      case RequestType.save:
        return Icons.shield;
    }
  }
}





