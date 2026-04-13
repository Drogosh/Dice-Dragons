# 🎲 Live Запросы и Ответы - Руководство

## 📌 Структура данных

### Live запросы (запросы от DM)
```
liveSessions/
  {sessionId}/
    requests/
      {requestId}:
        id: string
        dmId: string
        characterName: string
        formula: string
        type: string (skill|attack|saving_throw)
        targetAc: number | null
        note: string | null
        status: "open" | "closed"
        audience: "all" | "subset"
        targetUids: array<string>
        createdAt: timestamp
        completedAt: timestamp | null
```

### Ответы игроков
```
liveSessions/
  {sessionId}/
    responses/
      {requestId}/
        {playerId}:
          playerId: string
          playerName: string
          result: any (число, строка, объект)
          rollResult: number | null
          success: boolean | null
          respondedAt: timestamp
```

## 🔧 API методов

### Создание live запроса

```dart
await rtdbService.createLiveRequest(
  sessionId: 'session-123',
  requestId: 'req-456',
  dmId: 'dm-uid',
  characterName: 'Враг',
  formula: '1d20 + STR',
  type: 'skill',
  targetAc: 15,
  note: 'Проверка Ловкости',
  audience: 'subset',
  targetUids: ['player-1', 'player-2'],
);
```

### Слушание live запросов в реальном времени

```dart
rtdbService.watchLiveRequests(sessionId).listen((requests) {
  print('Открытых запросов: ${requests.length}');
  
  for (final request in requests) {
    print('${request['characterName']}: ${request['formula']}');
  }
});
```

### Добавление ответа игрока

```dart
await rtdbService.addPlayerResponse(
  sessionId: 'session-123',
  requestId: 'req-456',
  playerId: 'player-1',
  playerName: 'Герой',
  result: 18,           // Результат броска
  rollResult: 18,       // Просто число
  success: true,        // Успешен ли бросок
);
```

### Слушание ответов на запрос

```dart
rtdbService.watchRequestResponses(sessionId, requestId)
  .listen((responses) {
    print('Ответов: ${responses.length}');
    
    responses.forEach((playerId, response) {
      print('${response['playerName']}: ${response['result']}');
    });
  });
```

### Получение всех ответов сразу

```dart
final responses = await rtdbService.getRequestResponses(
  sessionId,
  requestId,
);

print('Получено ответов: ${responses.length}');
```

### Закрытие live запроса

```dart
await rtdbService.closeLiveRequest(sessionId, requestId);
```

### Удаление live запроса

```dart
await rtdbService.deleteLiveRequest(sessionId, requestId);
```

### Очистка всей live сессии

```dart
await rtdbService.clearLiveSession(sessionId);
```

## 🎯 Примеры использования

### Пример 1: Создание и отслеживание запроса

```dart
// DM создает запрос броска
await rtdbService.createLiveRequest(
  sessionId: sessionId,
  requestId: requestId,
  dmId: dmId,
  characterName: 'Враг атакует',
  formula: '1d20 + 5',
  type: 'attack',
  targetAc: 14,
  note: 'Атака врага',
  audience: 'all',
  targetUids: [],
);

// Все игроки видят запрос в реальном времени
rtdbService.watchLiveRequests(sessionId)
  .listen((requests) {
    setState(() {
      activeRequests = requests;
    });
  });

// Когда запрос отображен на экране, игроки видят его
```

### Пример 2: Игрок отвечает на запрос

```dart
// Игрок вводит результат и нажимает "Ответить"
void submitResponse(int rollResult) {
  rtdbService.addPlayerResponse(
    sessionId: sessionId,
    requestId: requestId,
    playerId: currentPlayerId,
    playerName: playerName,
    result: rollResult,
    rollResult: rollResult,
    success: rollResult >= targetAc,
  );
}

// DM видит ответ в реальном времени
rtdbService.watchRequestResponses(sessionId, requestId)
  .listen((responses) {
    // Обновить UI с ответами
    updateResponsesUI(responses);
  });
```

### Пример 3: DM управляет запросом

```dart
// Когда все ответили или DM завершает запрос
void completeRequest() {
  // Закрыть запрос
  rtdbService.closeLiveRequest(sessionId, requestId);
  
  // Получить все ответы
  final responses = await rtdbService.getRequestResponses(
    sessionId,
    requestId,
  );
  
  // Обработать результаты
  processResponses(responses);
}
```

### Пример 4: Widget для отслеживания ответов

```dart
class RequestResponsesWidget extends StatelessWidget {
  final String sessionId;
  final String requestId;
  final FirebaseRealtimeDatabaseService rtdbService;

  const RequestResponsesWidget({
    required this.sessionId,
    required this.requestId,
    required this.rtdbService,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Map<String, dynamic>>(
      stream: rtdbService.watchRequestResponses(sessionId, requestId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final responses = snapshot.data ?? {};

        return ListView.builder(
          itemCount: responses.length,
          itemBuilder: (context, index) {
            final playerId = responses.keys.elementAt(index);
            final response = responses[playerId] as Map;
            
            return Card(
              child: ListTile(
                title: Text(response['playerName']),
                subtitle: Text('Результат: ${response['result']}'),
                trailing: response['success'] == true
                    ? Icon(Icons.check, color: Colors.green)
                    : response['success'] == false
                        ? Icon(Icons.close, color: Colors.red)
                        : null,
              ),
            );
          },
        );
      },
    );
  }
}
```

## 🔐 Правила безопасности

### Кто может читать запросы?
- ✅ Члены сессии
- ✅ DM сессии

### Кто может создавать запросы?
- ✅ Только DM сессии

### Кто может добавлять ответы?
- ✅ Игрок на себя
- ✅ DM сессии

### Кто может закрывать запросы?
- ✅ Только DM сессии

## 📊 Примеры данных

### Запрос броска навыка
```json
{
  "id": "req-001",
  "dmId": "dm-123",
  "characterName": "Гоблин",
  "formula": "1d20 + 3",
  "type": "skill",
  "status": "open",
  "audience": "all",
  "targetUids": [],
  "note": "Проверка Восприятия",
  "createdAt": 1712973600000
}
```

### Запрос атаки
```json
{
  "id": "req-002",
  "dmId": "dm-123",
  "characterName": "Враг орка",
  "formula": "1d20 + 7",
  "type": "attack",
  "targetAc": 14,
  "status": "open",
  "audience": "subset",
  "targetUids": ["player-1", "player-2"],
  "note": "Атака мечом",
  "createdAt": 1712973600000
}
```

### Ответ игрока
```json
{
  "playerId": "player-1",
  "playerName": "Герой",
  "result": 16,
  "rollResult": 16,
  "success": true,
  "respondedAt": 1712973620000
}
```

## ⚡ Производительность

### Оптимизация
1. **Используйте listen(), не get()** - для получения обновлений в реальном времени
2. **Отписывайтесь при выходе** - избегайте утечек памяти
3. **Кэшируйте результаты** - не запрашивайте одно и то же дважды
4. **Удаляйте старые запросы** - очищайте live сессию после завершения

### Пример оптимизированного использования

```dart
@override
void initState() {
  super.initState();
  _subscription = rtdbService
    .watchLiveRequests(sessionId)
    .listen((requests) {
      setState(() {
        _requests = requests;
      });
    });
}

@override
void dispose() {
  _subscription?.cancel(); // ✅ Отписаться
  super.dispose();
}
```

## 🐛 Отладка

### Проверка live запросов в консоли Firebase

```bash
# Посмотреть все live запросы сессии
firebase database:get liveSessions/{sessionId}/requests

# Посмотреть все ответы
firebase database:get liveSessions/{sessionId}/responses
```

### Логирование ошибок

```dart
// Все ошибки логируются автоматически:
// ✅ Успех
// ❌ Ошибка
// 🔄 Процесс
```

## 📱 Интеграция с UI

### DM экран - показывать запросы
```dart
StreamBuilder<List<Map<String, dynamic>>>(
  stream: rtdbService.watchLiveRequests(sessionId),
  builder: (context, snapshot) {
    if (snapshot.hasData) {
      final requests = snapshot.data ?? [];
      // Показать список запросов
    }
  },
);
```

### Игроков экран - отвечать на запросы
```dart
// Показать текущий открытый запрос
// Кнопки для ввода результата
// Отправить ответ через addPlayerResponse()
```

## ✨ Лучшие практики

1. ✅ Очищайте live сессию при завершении
2. ✅ Используйте уникальные ID для запросов
3. ✅ Добавляйте note с описанием действия
4. ✅ Устанавливайте правильный audience
5. ✅ Закрывайте запросы после получения ответов
6. ✅ Логируйте все операции для отладки

## 🎊 Готово!

Live запросы и ответы полностью интегрированы в RTDB и готовы к использованию!

