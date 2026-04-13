# 🎲 Live Запросы - Краткая интеграция

## 📦 Что добавлено

✅ Методы для создания live запросов  
✅ Методы для добавления ответов игроков  
✅ Streams для реального времени  
✅ Обновленные правила безопасности  

## 🚀 Быстрое использование

### 1. Создать live запрос (DM)

```dart
await rtdbService.createLiveRequest(
  sessionId: 'session-123',
  requestId: 'req-456',
  dmId: dmId,
  characterName: 'Враг',
  formula: '1d20 + STR',
  type: 'skill',
  targetAc: 15,
  note: 'Проверка ловкости',
  audience: 'all',      // или 'subset'
  targetUids: [],       // пустой для всех
);
```

### 2. Слушать запросы (Игроки)

```dart
rtdbService.watchLiveRequests(sessionId)
  .listen((requests) {
    // requests это List<Map<String, dynamic>>
    for (final req in requests) {
      print('${req['characterName']}: ${req['formula']}');
    }
  });
```

### 3. Отправить ответ (Игрок)

```dart
await rtdbService.addPlayerResponse(
  sessionId: 'session-123',
  requestId: 'req-456',
  playerId: playerId,
  playerName: playerName,
  result: 18,           // Результат
  rollResult: 18,       // Число для броска
  success: true,        // Успешен ли
);
```

### 4. Слушать ответы (DM)

```dart
rtdbService.watchRequestResponses(sessionId, requestId)
  .listen((responses) {
    // responses это Map<String, dynamic>
    // Ключи - playerId, значения - ответы
    responses.forEach((playerId, response) {
      print('${response['playerName']}: ${response['result']}');
    });
  });
```

### 5. Закрыть запрос (DM)

```dart
await rtdbService.closeLiveRequest(sessionId, requestId);
```

## 📍 Структура в RTDB

```
liveSessions/
  {sessionId}/
    requests/
      {requestId}: { id, dmId, characterName, formula, type, status, ... }
    responses/
      {requestId}/
        {playerId}: { playerId, playerName, result, rollResult, success, ... }
    presence/      (уже существует)
```

## 🎯 Интеграция в SessionDMScreen

```dart
// В state класса
late StreamSubscription _requestsSubscription;
late StreamSubscription _responsesSubscription;

@override
void initState() {
  super.initState();
  
  // Слушаем live запросы
  _requestsSubscription = widget.rtdbService
    .watchLiveRequests(widget.session.id)
    .listen((requests) {
      setState(() {
        liveRequests = requests;
      });
    });
}

@override
void dispose() {
  _requestsSubscription?.cancel();
  _responsesSubscription?.cancel();
  super.dispose();
}
```

## 🔄 Полный цикл

```
1. DM нажимает "Новый запрос" 
   ↓
2. createLiveRequest() 
   ↓
3. Игроки видят запрос (watchLiveRequests)
   ↓
4. Игрок вводит результат и отправляет (addPlayerResponse)
   ↓
5. DM видит ответы (watchRequestResponses)
   ↓
6. DM закрывает запрос (closeLiveRequest)
   ↓
7. Запрос исчезает для всех
```

## ⚡ Важные моменты

✅ **Реальное время** - все видят обновления мгновенно  
✅ **Безопасность** - только DM может создавать запросы  
✅ **Аудитория** - можно отправить конкретным игрокам  
✅ **Ответы** - игроки видят результаты друг друга  

## 📚 Полная документация

👉 `LIVE_REQUESTS_GUIDE.md` - все методы и примеры

## 🎊 Готово!

Live запросы встроены в RTDB и готовы к использованию!

