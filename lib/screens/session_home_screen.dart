import 'package:flutter/material.dart';
import '../models/session.dart';
import '../models/character.dart';
import '../services/realtime_requests_service.dart';
import '../services/realtime_responses_service.dart';
import '../services/presence_service.dart';
import 'session_dm_screen.dart';
import 'session_player_screen.dart';
import 'session_info_screen.dart';

class SessionHomeScreen extends StatefulWidget {
  final Session session;
  final Character? dmCharacter;
  final Character? playerCharacter;
  final String currentUserId;
  final String currentUserDisplayName;
  final PresenceService presenceService;

  const SessionHomeScreen({
    super.key,
    required this.session,
    this.dmCharacter,
    this.playerCharacter,
    required this.currentUserId,
    required this.currentUserDisplayName,
    required this.presenceService,
  });

  @override
  State<SessionHomeScreen> createState() => _SessionHomeScreenState();
}

class _SessionHomeScreenState extends State<SessionHomeScreen> {
  late int _selectedTabIndex;
  late RealtimeRequestsService _requestsService;
  late RealtimeResponsesService _responsesService;

  @override
  void initState() {
    super.initState();
    _selectedTabIndex = 0;
    _requestsService = RealtimeRequestsService();
    _responsesService = RealtimeResponsesService();

    // Установить presence при входе
    _enterPresence();
  }

  Future<void> _enterPresence() async {
    try {
      await widget.presenceService.setPresence(
        widget.session.id,
        widget.currentUserId,
        isOnline: true,
      );
    } catch (e) {
      debugPrint('❌ Ошибка установки presence: $e');
    }
  }

  @override
  void dispose() {
    // Удалить presence при выходе
    _exitPresence();
    super.dispose();
  }

  Future<void> _exitPresence() async {
    try {
      await widget.presenceService.setPresence(
        widget.session.id,
        widget.currentUserId,
        isOnline: false,
      );
    } catch (e) {
      debugPrint('❌ Ошибка удаления presence: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDM = widget.session.isDM(widget.currentUserId);

    return Scaffold(
      appBar: AppBar(
        title: Text('Сессия: ${widget.session.name}'),
        elevation: 0,
      ),
      body: IndexedStack(
        index: _selectedTabIndex,
        children: [
          // Вкладка "Инфо"
          SessionInfoScreen(session: widget.session),

          // Вкладка "Игра"
          if (isDM)
            SessionDMScreen(
              session: widget.session,
              dmCharacter: widget.dmCharacter,
              requestsService: _requestsService,
              responsesService: _responsesService,
            )
          else
            SessionPlayerScreen(
              session: widget.session,
              currentPlayerId: widget.currentUserId,
              playerDisplayName: widget.currentUserDisplayName,
              playerCharacter: widget.playerCharacter,
              requestsService: _requestsService,
              responsesService: _responsesService,
            ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedTabIndex,
        onTap: (index) {
          setState(() {
            _selectedTabIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.info),
            label: 'Инфо',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.games),
            label: 'Игра',
          ),
        ],
      ),
    );
  }
}

