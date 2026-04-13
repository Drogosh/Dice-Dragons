import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/session.dart';
import '../services/session_service.dart';
import '../services/presence_service.dart';
import '../services/firestore_service.dart';
import 'character_screen.dart';
import 'character_selection_screen.dart';
import '../models/inventory.dart';
import 'main_navigation_screen.dart';
import 'character_selection_screen.dart';

class SessionScreen extends StatefulWidget {
  final Session session;

  const SessionScreen({
    super.key,
    required this.session,
  });

  @override
  State<SessionScreen> createState() => _SessionScreenState();
}

class _SessionScreenState extends State<SessionScreen> {
  late final SessionService _sessionService;
  late final PresenceService _presenceService;
  late Session _currentSession;

  @override
  void initState() {
    super.initState();
    _sessionService = SessionService();
    _presenceService = PresenceService();
    _currentSession = widget.session;

    // Войти в сессию (установить online=true)
    _presenceService.enterSession(_currentSession.id).then((_) {
      debugPrint('✅ Presence set to online');
    }).catchError((e) {
      debugPrint('❌ Error setting presence: $e');
    });
  }

  @override
  void dispose() {
    // Покинуть сессию при выходе со экрана
    _presenceService.leaveSession(_currentSession.id);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        title: Text(_currentSession.name),
        backgroundColor: Colors.grey[800],
        actions: [
          // Кнопка быстрого открытия персонажа текущего пользователя (если привязан)
          IconButton(
            icon: const Icon(Icons.person_search),
            tooltip: 'Открыть мой персонаж',
            onPressed: () async {
              final user = FirebaseAuth.instance.currentUser;
              final messenger = ScaffoldMessenger.of(context);
              final navigator = Navigator.of(context);

              if (user == null) {
                messenger.showSnackBar(const SnackBar(content: Text('Пользователь не авторизован')));
                return;
              }

              final member = _currentSession.members[user.uid];
              var charId = member?.characterId;

              // Попытка загрузить первый персонаж пользователя как fallback
              if (charId == null) {
                try {
                  final sessionService = SessionService();
                  final char = await sessionService.loadUserCharacter();
                  if (char != null) {
                    if (!mounted) return;
                    navigator.push(MaterialPageRoute(builder: (_) => MainNavigationScreen(character: char, inventory: Inventory(), originSession: _currentSession)));
                    return;
                  }
                } catch (e) {
                  debugPrint('Ошибка загрузки локального персонажа: $e');
                }
                messenger.showSnackBar(const SnackBar(content: Text('У вас не привязан персонаж в этой сессии')));
                return;
              }

              // Загружаем персонажа по ID
              try {
                final firestore = FirestoreService();
                final char = await firestore.getCharacterById(user.uid, charId);
                if (char == null) {
                  messenger.showSnackBar(const SnackBar(content: Text('Персонаж не найден')));
                  return;
                }
                if (!mounted) return;
                navigator.push(MaterialPageRoute(builder: (_) => MainNavigationScreen(character: char, inventory: Inventory(), originSession: _currentSession)));
              } catch (e) {
                if (!mounted) return;
                messenger.showSnackBar(SnackBar(content: Text('Ошибка: $e')));
              }
            },
          ),

          // Дополнительная кнопка: открыть список персонажей (для DM и игроков)
          IconButton(
            icon: const Icon(Icons.person),
            tooltip: 'Открыть список персонажей',
            onPressed: () {
              // Открываем общий экран выбора персонажа
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CharacterSelectionScreen()),
              );
            },
          ),
          if (_currentSession.isDM(_currentSession.dmId))
            PopupMenuButton(
              itemBuilder: (context) => [
                PopupMenuItem(
                  child: const Text('Изменить название'),
                  onTap: () => _showEditDialog(),
                ),
                PopupMenuItem(
                  child: const Text('Закончить сессию'),
                  onTap: () => _endSession(),
                ),
                PopupMenuItem(
                  child: const Text('Удалить сессию'),
                  onTap: () => _deleteSession(),
                ),
              ],
            )
          else
            PopupMenuButton(
              itemBuilder: (context) => [
                PopupMenuItem(
                  child: const Text('Покинуть сессию'),
                  onTap: () => _leaveSession(),
                ),
              ],
            ),
        ],
      ),
      body: SafeArea(
        child: StreamBuilder<Session?>(
          stream: _sessionService.watchSession(_currentSession.id),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(
                child: Text(
                  'Ошибка: ${snapshot.error}',
                  style: const TextStyle(color: Colors.white),
                ),
              );
            }

            if (!snapshot.hasData || snapshot.data == null) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            _currentSession = snapshot.data!;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Информация о сессии
                  _buildSessionInfo(),
                  const SizedBox(height: 24),

                  // Ведущий
                  _buildDMInfo(),
                  const SizedBox(height: 24),

                  // Участники (игроки)
                  _buildPlayersList(),
                  const SizedBox(height: 24),

                  // Статус сессии
                  _buildStatusInfo(),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSessionInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Информация',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getStatusColor(_currentSession.status),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  _getStatusText(_currentSession.status),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildInfoRow('Название:', _currentSession.name),
          if (_currentSession.campaignName != null)
            _buildInfoRow('Кампания:', _currentSession.campaignName!),
          _buildInfoRow(
            'Код присоединения:',
            _currentSession.joinCode,
            isBold: true,
          ),
          _buildInfoRow(
            'Участников:',
            '${_currentSession.getMemberCount()}'
            '${_currentSession.maxPlayers > 0 ? '/${_currentSession.maxPlayers}' : ''}',
          ),
          _buildInfoRow(
            'Создана:',
            _formatDateTime(_currentSession.createdAt),
          ),
        ],
      ),
    );
  }

  Widget _buildDMInfo() {
    final dm = _currentSession.getDM();
    if (dm == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.purple[900],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Ведущий (DM)',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.shield, color: Colors.purple[300]),
              const SizedBox(width: 8),
              Text(
                dm.displayName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPlayersList() {
    final players = _currentSession.getPlayers();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Игроки (${players.length})',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          if (players.isEmpty)
            Text(
              'Нет игроков',
              style: TextStyle(color: Colors.grey[500]),
            )
          else
            // Слушаем изменения presence в реальном времени
            StreamBuilder<List<PresenceStatus>>(
              stream: _presenceService.watchPresence(_currentSession.id),
              builder: (context, snapshot) {
                // Создаём map presence для быстрого поиска
                final presenceMap = <String, PresenceStatus>{};
                if (snapshot.hasData) {
                  for (final presence in snapshot.data!) {
                    presenceMap[presence.uid] = presence;
                  }
                }

                return Column(
                  children: players.map((player) {
                    final presence = presenceMap[player.uid];
                    final isOnline = presence?.online ?? false;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey[700],
                          border: Border.all(
                            color: isOnline ? Colors.green[400]! : Colors.transparent,
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          children: [
                            // Online статус индикатор
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: isOnline ? Colors.green : Colors.grey,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Icon(Icons.person, color: Colors.blue[300]),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        player.displayName,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      // Online/Offline статус текст
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: isOnline
                                              ? Colors.green[900]
                                              : Colors.grey[700],
                                          borderRadius: BorderRadius.circular(3),
                                        ),
                                        child: Text(
                                          isOnline ? 'Онлайн' : 'Офлайн',
                                          style: TextStyle(
                                            color: isOnline
                                                ? Colors.green[300]
                                                : Colors.grey[400],
                                            fontSize: 10,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  if (player.characterId != null)
                                    Text(
                                      'Персонаж: ${player.characterId}',
                                      style: TextStyle(
                                        color: Colors.grey[400],
                                        fontSize: 12,
                                      ),
                                    ),
                                  // Показываем время последнего видения
                                  if (presence != null)
                                    Text(
                                      isOnline
                                          ? 'Онлайн'
                                          : 'Вышел: ${_presenceService.getLastSeenText(presence.lastSeen)}',
                                      style: TextStyle(
                                        color: Colors.grey[500],
                                        fontSize: 11,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                             Row(
                               children: [
                                 Text(
                                   _formatDateTime(player.joinedAt),
                                   style: TextStyle(
                                     color: Colors.grey[500],
                                     fontSize: 12,
                                   ),
                                 ),
                                 const SizedBox(width: 8),
                                 if (player.characterId != null)
                                   IconButton(
                                     icon: const Icon(Icons.person),
                                     color: Colors.white,
                                     tooltip: 'Открыть персонажа',
                                     onPressed: () => _openCharacter(player.uid, player.characterId!),
                                   ),
                               ],
                             ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildStatusInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Последнее обновление',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _formatDateTime(_currentSession.updatedAt),
            style: TextStyle(color: Colors.grey[400]),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(color: Colors.grey[400]),
          ),
          Text(
            value,
            style: TextStyle(
              color: Colors.white,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(SessionStatus status) {
    switch (status) {
      case SessionStatus.active:
        return Colors.green[700]!;
      case SessionStatus.paused:
        return Colors.orange[700]!;
      case SessionStatus.ended:
        return Colors.red[700]!;
    }
  }

  String _getStatusText(SessionStatus status) {
    switch (status) {
      case SessionStatus.active:
        return 'Активна';
      case SessionStatus.paused:
        return 'На паузе';
      case SessionStatus.ended:
        return 'Завершена';
    }
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 60) {
      return 'только что';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} мин назад';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} ч назад';
    } else {
      return '${dateTime.day}.${dateTime.month}.${dateTime.year}';
    }
  }

  /// Открыть экран персонажа по ownerUid и charId
  Future<void> _openCharacter(String ownerUid, String charId) async {
    final messenger = ScaffoldMessenger.of(context);
    // Показываем индикатор загрузки
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final firestore = FirestoreService();
      final character = await firestore.getCharacterById(ownerUid, charId);
      if (!mounted) return;
      Navigator.pop(context); // закрываем диалог загрузки

      if (character == null) {
        messenger.showSnackBar(const SnackBar(content: Text('Персонаж не найден')));
        return;
      }

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => MainNavigationScreen(character: character, inventory: Inventory(), originSession: _currentSession),
        ),
      );
    } catch (e) {
      if (mounted) Navigator.pop(context);
      messenger.showSnackBar(SnackBar(content: Text('Ошибка: $e')));
    }
  }

  void _showEditDialog() {
    final nameController = TextEditingController(text: _currentSession.name);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[850],
        title: const Text(
          'Изменить название',
          style: TextStyle(color: Colors.white),
        ),
        content: TextField(
          controller: nameController,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.grey[700],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () async {
              await _sessionService.updateSession(
                _currentSession.id,
                name: nameController.text,
              );
              if (mounted) Navigator.pop(context);
            },
            child: const Text('Сохранить'),
          ),
        ],
      ),
    );
  }

  Future<void> _endSession() async {
    await _sessionService.updateSession(
      _currentSession.id,
      status: SessionStatus.ended,
    );
  }

  Future<void> _deleteSession() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[850],
        title: const Text(
          'Удалить сессию?',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Это действие нельзя отменить.',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );

    if (confirmed ?? false) {
      await _sessionService.deleteSession(_currentSession.id);
      if (mounted) Navigator.pop(context);
    }
  }

  Future<void> _leaveSession() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[850],
        title: const Text(
          'Покинуть сессию?',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Покинуть'),
          ),
        ],
      ),
    );

    if (confirmed ?? false) {
      await _sessionService.leaveSession(_currentSession.id);
      if (mounted) Navigator.pop(context);
    }
  }
}



