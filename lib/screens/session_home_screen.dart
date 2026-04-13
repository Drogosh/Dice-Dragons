import 'package:flutter/material.dart';
import '../models/session.dart';
import '../models/character.dart';
import '../services/realtime_requests_service.dart';
import '../services/realtime_responses_service.dart';
import '../services/session_service.dart';
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

  const SessionHomeScreen({
    super.key,
    required this.session,
    this.dmCharacter,
    this.playerCharacter,
    required this.currentUserId,
    required this.currentUserDisplayName,
  });

  @override
  State<SessionHomeScreen> createState() => _SessionHomeScreenState();
}

class _SessionHomeScreenState extends State<SessionHomeScreen> {
  late int _selectedTabIndex;
  late RealtimeRequestsService _requestsService;
  late RealtimeResponsesService _responsesService;
  late SessionService _sessionService;
  late PresenceService _presenceService;

  @override
  void initState() {
    super.initState();
    _selectedTabIndex = 0;
    _requestsService = RealtimeRequestsService();
    _responsesService = RealtimeResponsesService();
    _sessionService = SessionService();
    _presenceService = PresenceService();

    // Установить presence при входе
    _enterPresence();
  }

  Future<void> _enterPresence() async {
    try {
      await _presenceService.enterSession(widget.session.id);
      debugPrint('✅ Presence установлен для сессии ${widget.session.id}');
    } catch (e) {
      debugPrint('❌ Ошибка установки presence: $e');
    }
  }

  @override
  void dispose() {
    // Удалить presence при выходе
    _leavePresence();
    super.dispose();
  }

  Future<void> _leavePresence() async {
    try {
      await _presenceService.leaveSession(widget.session.id);
      debugPrint('✅ Presence удален для сессии ${widget.session.id}');
    } catch (e) {
      debugPrint('❌ Ошибка удаления presence: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Session?>(
      stream: _sessionService.watchSession(widget.session.id),
      initialData: widget.session,
      builder: (context, snapshot) {
        final liveSession = snapshot.data ?? widget.session;
        final isDM = liveSession.isDM(widget.currentUserId);

        return Scaffold(
          appBar: AppBar(
            title: Text('Сессия: ${liveSession.name} (${liveSession.getMemberCount()} участников)'),
            elevation: 0,
          ),
          body: IndexedStack(
            index: _selectedTabIndex,
            children: [
              // Вкладка "Инфо"
              SessionInfoScreen(session: liveSession),

              // Вкладка "Игра"
              if (isDM)
                SessionDMScreen(
                  session: liveSession,
                  dmCharacter: widget.dmCharacter,
                  requestsService: _requestsService,
                  responsesService: _responsesService,
                )
              else if (widget.playerCharacter != null)
                SessionPlayerScreen(
                  session: liveSession,
                  currentPlayerId: widget.currentUserId,
                  playerDisplayName: widget.currentUserDisplayName,
                  playerCharacter: widget.playerCharacter,
                  requestsService: _requestsService,
                  responsesService: _responsesService,
                )
              else
                const Center(child: Text('❌ Ошибка: персонаж не найден')),
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
      },
    );
  }
}









