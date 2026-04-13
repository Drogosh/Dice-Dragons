import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/session.dart';
import '../services/session_service.dart';
import 'session_dm_screen.dart';

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

  Future<void> _loadSessions() async {
    // Метод для загрузки сессий (будет реализован в следующем файле)
  }

  void _showCreateSessionDialog() {
    print('🔥 Открываю диалог создания сессии');
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
              if (nameController.text.isEmpty) {
                setState(() => _errorMessage = 'Введите название сессии');
                return;
              }

              try {
                setState(() => _isLoading = true);

                final session = await _sessionService.createSession(
                  name: nameController.text,
                  campaignName:
                      campaignController.text.isEmpty ? null : campaignController.text,
                  maxPlayers: int.tryParse(maxPlayersController.text) ?? 0,
                );

                print('✅ Сессия создана: ${session.id}, код: ${session.joinCode}');

                // Закрыть диалог создания
                Navigator.pop(context);

                // Показать диалог с кодом
                Future.delayed(const Duration(milliseconds: 300), () {
                  if (mounted) {
                    _showJoinCodeDialog(session);
                  }
                });
              } catch (e) {
                print('❌ Ошибка создания сессии: $e');
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

  void _showJoinCodeDialog(Session session) {
    print('🔥🔥🔥 ВЫЗЫВАЮ _showJoinCodeDialog! Код: ${session.joinCode}');

    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) {
          print('🔥🔥🔥 Строю AlertDialog');
          return AlertDialog(
            backgroundColor: Colors.grey[850],
            title: const Text(
              'Сессия создана!',
              style: TextStyle(color: Colors.white),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Поделитесь этим кодом с игроками:',
                  style: TextStyle(color: Colors.white),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue[900],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    session.joinCode,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Название: ${session.name}',
                  style: TextStyle(color: Colors.grey[400]),
                ),
                if (session.campaignName != null)
                  Text(
                    'Кампания: ${session.campaignName}',
                    style: TextStyle(color: Colors.grey[400]),
                  ),
                Text(
                  'Игроки: ${session.getPlayers().length}${session.maxPlayers > 0 ? '/${session.maxPlayers}' : ''}',
                  style: TextStyle(color: Colors.grey[400]),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  print('👉 Нажата кнопка "Закрыть"');
                  Navigator.pop(dialogContext);
                },
                child: const Text('Закрыть'),
              ),
              ElevatedButton(
                onPressed: () {
                  print('👉👉👉 Нажата кнопка "К сессии (DM)"!!!');
                  Navigator.pop(dialogContext);
                  _navigateToDMScreen(session);
                },
                child: const Text('К сессии (DM)'),
              ),
            ],
          );
        },
      );
      print('🔥🔥🔥 showDialog вызван');
    } catch (e) {
      print('🔥🔥🔥 ОШИБКА в _showJoinCodeDialog: $e');
    }
  }

  void _navigateToDMScreen(Session session) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SessionDMScreen(
          session: session,
          sessionService: _sessionService,
          dmCharacter: null, // DM персонаж можно получить отдельно если нужно
        ),
      ),
    );
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
        content: Column(
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

                final session = await _sessionService.joinSessionByCode(
                  codeController.text,
                );

                if (mounted) {
                  Navigator.pop(context);

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

  void _navigateToSession(Session session) {
    // TODO: Навигация на экран сессии
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Присоединились к: ${session.name}'),
      ),
    );
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

            // Контент
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
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

