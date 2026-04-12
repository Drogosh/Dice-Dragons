# 🎲 D&D Sessions - Многопользовательская система

## Структура

### Firestore
```
sessions/{sessionId}
├── dmId: string (UID ведущего)
├── name: string (название сессии)
├── joinCode: string (код присоединения, 6 символов)
├── status: "active" | "paused" | "ended"
├── description: string (опционально)
├── campaignName: string (название кампании)
├── maxPlayers: number (0 = без лимита)
├── createdAt: timestamp
├── updatedAt: timestamp
└── members/{uid}
    ├── role: "dm" | "player"
    ├── displayName: string
    ├── characterId: string (опционально)
    └── joinedAt: timestamp
```

### Realtime Database
```
sessions/{sessionId}
├── events/{eventId}
│   ├── type: "roll" | "attack" | "spell" | "message" | "action"
│   ├── timestamp: number
│   ├── userId: string
│   └── data: object (специфичные данные)
└── members/{uid}
    └── (индекс для быстрого поиска)
```

---

## Безопасность

### Firestore Rules
- ✅ Читать сессию могут только её участники
- ✅ Писать (обновлять) сессию может только DM
- ✅ Удалить сессию может только DM
- ✅ Добавить члена может DM или сам пользователь
- ✅ Удалить члена может DM или сам пользователь

### RTDB Rules
- ✅ Читать события могут только участники сессии
- ✅ Писать события могут только участники
- ✅ Валидация типа события
- ✅ Обязательные поля: type, timestamp

---

## API

### Создать сессию (DM)
```dart
final sessionService = SessionService();

final session = await sessionService.createSession(
  name: 'Приключение в Забытых Подземельях',
  description: 'Эпическое путешествие',
  campaignName: 'Вампиры Вотерглена',
  maxPlayers: 6,
);

print('Код присоединения: ${session.joinCode}');
```

### Присоединиться к сессии
```dart
final session = await sessionService.joinSessionByCode(
  'AB12CD',
  characterId: 'character_id_123', // опционально
);

print('Присоединились к: ${session.name}');
```

### Получить мои сессии
```dart
// Все сессии, где я участник
final sessions = await sessionService.getUserSessions();

// Только сессии, где я DM
final dmSessions = await sessionService.getDMSessions();
```

### Получить сессию по ID
```dart
final session = await sessionService.getSessions('session_id');
```

### Обновить сессию (только DM)
```dart
await sessionService.updateSession(
  'session_id',
  name: 'Новое название',
  status: SessionStatus.paused,
);
```

### Покинуть сессию
```dart
await sessionService.leaveSession('session_id');
```

### Удалить сессию (только DM)
```dart
await sessionService.deleteSession('session_id');
```

---

## Live Events (Real-Time)

### Слушать изменения сессии
```dart
sessionService.watchSession('session_id').listen((session) {
  print('Сессия обновлена: ${session?.name}');
  print('Участников: ${session?.getMemberCount()}');
});
```

### Слушать членов сессии
```dart
sessionService.watchMembers('session_id').listen((members) {
  print('Актуальный список участников:');
  for (final member in members) {
    print('  - ${member.displayName} (${member.role.name})');
  }
});
```

---

## Применение Правил

### Firestore
1. Перейти в Firebase Console → Firestore → Rules
2. Заменить содержимое содержимым файла `firestore.rules`
3. Нажать Publish

### Realtime Database
1. Перейти в Firebase Console → Realtime Database → Rules
2. Заменить содержимое содержимым файла `rtdb.rules.json`
3. Нажать Publish

---

## Примеры Использования

### Сценарий 1: DM Создаёт Сессию
```dart
// 1. DM создаёт сессию
final session = await sessionService.createSession(
  name: 'В поисках артефакта',
  maxPlayers: 5,
);

// 2. DM получает код и делится с игроками
print('Присоединяйтесь по коду: ${session.joinCode}');

// 3. Слушать когда игроки присоединяются
sessionService.watchMembers(session.id).listen((members) {
  print('Игроки присоединились: ${members.length}');
});
```

### Сценарий 2: Игрок Присоединяется
```dart
// 1. Игрок вводит код
final session = await sessionService.joinSessionByCode('AB12CD');

// 2. Игрок видит информацию о сессии
print('Вы в сессии: ${session.name}');
print('DM: ${session.getDM()?.displayName}');
print('Игроки: ${session.getPlayers().length}');

// 3. Игрок может слушать изменения
sessionService.watchSession(session.id).listen((updatedSession) {
  print('Статус сессии: ${updatedSession?.status.name}');
});
```

### Сценарий 3: Live События
```dart
// В RTDB можно отправлять события
// Пример пути для события:
// sessions/{sessionId}/events/{eventId}

final event = {
  'type': 'roll',
  'timestamp': DateTime.now().millisecondsSinceEpoch,
  'userId': user.uid,
  'data': {
    'character': 'Артур',
    'dice': 'd20',
    'result': 18,
  }
};

// Записать в RTDB
await database.ref('sessions/$sessionId/events').push().set(event);
```

---

## Модели

### Session
```dart
class Session {
  final String id;              // ID сессии
  final String dmId;            // UID ведущего
  final String name;            // Название
  final String joinCode;        // Код присоединения
  final SessionStatus status;   // Статус
  final Map<String, SessionMember> members;  // Участники
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? description;
  final String? campaignName;
  final int maxPlayers;

  // Методы:
  List<SessionMember> getPlayers()  // Получить всех игроков
  SessionMember? getDM()            // Получить ведущего
  bool hasAvailableSpots()          // Проверить свободные места
  int getMemberCount()              // Количество участников
  bool isDM(String uid)             // Является ли пользователь DM
  bool hasMember(String uid)        // Участвует ли пользователь
}
```

### SessionMember
```dart
class SessionMember {
  final String uid;
  final SessionRole role;           // dm | player
  final String displayName;
  final String? characterId;        // ID персонажа игрока
  final DateTime joinedAt;
}
```

### Enums
```dart
enum SessionRole { dm, player }
enum SessionStatus { active, paused, ended }
```

---

## Интеграция в UI

### Экран Создания Сессии
```dart
// Добавить в main_navigation_screen.dart

final sessionService = SessionService();

// Форма создания
final nameController = TextEditingController();
final maxPlayersController = TextEditingController();

// На кнопку "Создать":
try {
  final session = await sessionService.createSession(
    name: nameController.text,
    maxPlayers: int.tryParse(maxPlayersController.text) ?? 0,
  );
  
  // Показать код присоединения
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Сессия создана!'),
      content: Text('Код: ${session.joinCode}'),
    ),
  );
} catch (e) {
  // Показать ошибку
}
```

### Экран Присоединения
```dart
// Форма для ввода кода
final codeController = TextEditingController();

// На кнопку "Присоединиться":
try {
  final session = await sessionService.joinSessionByCode(
    codeController.text,
  );
  
  // Перейти в сессию
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => SessionScreen(session: session),
    ),
  );
} catch (e) {
  // Показать ошибку (неверный код, сессия полная и т.д.)
}
```

---

## Todo (Будущие Улучшения)

- [ ] Добавить invites (приглашения вместо кодов)
- [ ] Уведомления о присоединении игроков
- [ ] История действий в сессии
- [ ] Чат в сессии
- [ ] Roll history (история бросков)
- [ ] Combat tracker
- [ ] Initiative tracker
- [ ] Синхронизация состояния боя
- [ ] Voice chat интеграция

---

## Развёртывание

### Шаг 1: Обновить Firestore Rules
```bash
firebase deploy --only firestore:rules
```

### Шаг 2: Обновить RTDB Rules
```bash
firebase deploy --only database
```

### Шаг 3: Интегрировать в приложение
- Добавить SessionService в сервисный слой
- Создать UI для сессий
- Добавить навигацию между сессиями

---

**Статус**: 🚀 Готово к интеграции
**Версия**: 1.0
**Последнее обновление**: 13 апреля 2026

