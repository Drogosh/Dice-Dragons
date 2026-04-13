import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import '../models/session.dart';
import '../models/character.dart';
import '../services/session_service.dart';
// Removed unused imports
import 'session_home_screen.dart';

class SessionsListScreen extends StatefulWidget {
  const SessionsListScreen({super.key});

  @override
  State<SessionsListScreen> createState() => _SessionsListScreenState();
}

class _SessionsListScreenState extends State<SessionsListScreen> {
  late final SessionService _sessionService;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _sessionService = SessionService();
  }

  void _showCreateSessionDialog() {
    debugPrint('🔥 Открываю диалог создания сессии');
    final nameController = TextEditingController();
    final maxPlayersController = TextEditingController();
    final campaignController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[850],
        title: const Text(
          'Создать сессию',
          style: TextStyle(color: Colors.white),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Название сессии',
                  hintStyle: TextStyle(color: Colors.grey[600]),
                  filled: true,
                  fillColor: Colors.grey[700],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: campaignController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Название кампании (опционально)',
                  hintStyle: TextStyle(color: Colors.grey[600]),
                  filled: true,
                  fillColor: Colors.grey[700],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: maxPlayersController,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Макс игроков (0 = без лимита)',
                  hintStyle: TextStyle(color: Colors.grey[600]),
                  filled: true,
                  fillColor: Colors.grey[700],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
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
              debugPrint('🔥🔥🔥 Начало создания сессии - нажата кнопка Создать');
              if (nameController.text.isEmpty) {
                setState(() => _errorMessage = 'Введите название сессии');
                return;
              }

              try {
                setState(() => _isLoading = true);

                // capture navigator before async gap
                final navigator = Navigator.of(context);

                final session = await _sessionService.createSession(
                  name: nameController.text,
                  campaignName:
                      campaignController.text.isEmpty ? null : campaignController.text,
                  maxPlayers: int.tryParse(maxPlayersController.text) ?? 0,
                );

                debugPrint('✅✅✅ Сессия создана: ${session.id}, код: ${session.joinCode}');

                // Закрыть диалог создания и сразу перейти на DM экран
                if (!mounted) return;
                navigator.pop();
                debugPrint('✅ Dialog закрыт');

                // Прямой переход на DM экран (без промежуточного диалога)
                debugPrint('✅ Готов к навигации на DM');
                Future.delayed(const Duration(milliseconds: 300), () {
                  debugPrint('✅ Delayed callback вызван, вызываю _navigateToDMScreen');
                  if (mounted) {
                    _navigateToDMScreen(session);
                  } else {
                    debugPrint('❌ Widget не mounted!');
                  }
                });
              } catch (e) {
                debugPrint('❌ Ошибка создания сессии: $e');
                if (mounted) {
                  setState(() => _errorMessage = 'Ошибка: $e');
                }
              } finally {
                if (mounted) {
                  setState(() => _isLoading = false);
                }
              }
            },
            child: const Text('Создать'),
          ),
        ],
      ),
    );
  }



  void _navigateToDMScreen(Session session) async {
    debugPrint('🚀🚀🚀 _navigateToDMScreen вызван для сессии: ${session.id}, код: ${session.joinCode}');

    try {
      final currentUser = fb.FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('❌ Ошибка: пользователь не авторизирован')),
        );
        return;
      }

      // Загрузить персонаж DM
      Character? dmCharacter;
      try {
        dmCharacter = await _sessionService.loadUserCharacter();
      } catch (e) {
        debugPrint('⚠️ Не удалось загрузить персонажа DM: $e');
      }

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SessionHomeScreen(
              session: session,
              dmCharacter: dmCharacter,
              currentUserId: currentUser.uid,
              currentUserDisplayName: currentUser.displayName ?? 'DM',
            ),
          ),
        );
      }
      debugPrint('🚀🚀🚀 Navigator.push вызван');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Ошибка: $e')),
        );
      }
    }
  }

  void _showJoinSessionDialog() {
    final codeController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[850],
        title: const Text(
          'Присоединиться к сессии',
          style: TextStyle(color: Colors.white),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Введите код присоединения:',
                style: TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: codeController,
                style: const TextStyle(color: Colors.white),
                inputFormatters: [
                  UpperCaseTextFormatter(),
                ],
                decoration: InputDecoration(
                  hintText: 'например: AB12CD',
                  hintStyle: TextStyle(color: Colors.grey[600]),
                  filled: true,
                  fillColor: Colors.grey[700],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                maxLength: 6,
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
              if (codeController.text.length != 6) {
                setState(
                    () => _errorMessage = 'Введите правильный код (6 символов)');
                return;
              }

              try {
                setState(() => _isLoading = true);

                // capture navigator before async gap
                final navigator = Navigator.of(context);

                final session = await _sessionService.joinSessionByCode(
                  codeController.text,
                );
                if (mounted) {
                  navigator.pop();

                  // Перейти в сессию
                  _navigateToSession(session);
                }
              } catch (e) {
                setState(() => _errorMessage = 'Ошибка: $e');
              } finally {
                if (mounted) {
                  setState(() => _isLoading = false);
                }
              }
            },
            child: const Text('Присоединиться'),
          ),
        ],
      ),
    );
  }

  void _navigateToSession(Session session) async {
    try {
      final currentUser = fb.FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('❌ Ошибка: пользователь не авторизирован')),
        );
        return;
      }

      // Загрузить персонажа текущего пользователя
      Character? userCharacter;
      try {
        userCharacter = await _sessionService.loadUserCharacter();
      } catch (e) {
        debugPrint('⚠️ Не удалось загрузить персонажа: $e');
      }

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SessionHomeScreen(
              session: session,
              dmCharacter: session.isDM(currentUser.uid) ? userCharacter : null,
              playerCharacter: !session.isDM(currentUser.uid) ? userCharacter : null,
              currentUserId: currentUser.uid,
              currentUserDisplayName: currentUser.displayName ?? 'Unknown',
            ),
          ),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        title: const Text('Сессии D&D'),
        backgroundColor: Colors.grey[800],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Ошибка (если есть)
            if (_errorMessage != null)
              Container(
                padding: const EdgeInsets.all(12),
                color: Colors.red[900],
                child: Row(
                  children: [
                    Icon(Icons.error, color: Colors.red[300]),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      color: Colors.white,
                      onPressed: () =>
                          setState(() => _errorMessage = null),
                    ),
                  ],
                ),
              ),

            // Контент — используем ListView чтобы обеспечить корректную прокрутку
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Заголовок
                  const SizedBox(height: 16),
                  const Text(
                    'Управление Сессиями',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Кнопки
                  ElevatedButton.icon(
                    onPressed: _isLoading ? null : _showCreateSessionDialog,
                    icon: const Icon(Icons.add),
                    label: const Text('Создать Сессию (DM)'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.all(16),
                      backgroundColor: Colors.blue[700],
                    ),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: _isLoading ? null : _showJoinSessionDialog,
                    icon: const Icon(Icons.login),
                    label: const Text('Присоединиться к Сессии'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.all(16),
                      backgroundColor: Colors.green[700],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Информация
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[800],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Что это?',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Сессии позволяют нескольким игрокам присоединиться '
                          'к одной игре. '
                          'DM (ведущий) создаёт сессию и делится кодом. '
                          'Игроки вводят код для присоединения.',
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Форматер для преобразования текста в прописные буквы
class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return newValue.copyWith(
      text: newValue.text.toUpperCase(),
    );
  }
}

