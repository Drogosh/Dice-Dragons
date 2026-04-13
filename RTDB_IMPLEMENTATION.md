# 🚀 Real-time Database Внедрение

## Обзор

Этот проект был переноса из исключительно Firestore на гибридную архитектуру, использующую **Firebase Real-time Database (RTDB)** как основное хранилище с резервной копией на Firestore.

### Почему RTDB?

✅ **Синхронизация в реальном времени** - обновления видны мгновенно  
✅ **Работает офлайн** - данные синхронизируются при восстановлении соединения  
✅ **Быстрее** - благодаря кэшированию и оптимизированным путям  
✅ **Лучше для многопользовательского** - идеально для игровых сессий  

## Архитектура

```
┌─────────────────────────────────────┐
│   Приложение Flutter                │
└────────────┬────────────────────────┘
             │
    ┌────────┴──────────┐
    │                   │
┌───▼──────────────┐  ┌─▼──────────────────┐
│ HybridSession    │  │ FirebaseRealtime    │
│ Service          │  │ DatabaseService     │
└───┬──────────────┘  └─┬──────────────────┘
    │                  │
    ├──────────┬───────┤
    │          │       │
┌───▼─────┐  ┌▼──────┐│
│Firestore│  │ RTDB  ││
└─────────┘  └───────┘│
             └────────┘
```

## Структура RTDB

```
/sessions
  /sessionId
    id: string
    dmId: string
    name: string
    joinCode: string
    status: string (active|paused|ended)
    description: string
    campaignName: string
    maxPlayers: number
    createdAt: number (timestamp)
    updatedAt: number (timestamp)
    members:
      /userId
        uid: string
        role: string (dm|player)
        displayName: string
        characterId: string
        joinedAt: number (timestamp)

/requests
  /sessionId
    /requestId
      id: string
      characterId: string
      characterName: string
      type: string (skill|saving_throw|attack)
      formula: string
      targetAc: number
      note: string
      status: string (open|closed)
      audience: string (all|subset)
      targetUids: array
      createdAt: number (timestamp)
      completedAt: number (timestamp)
      result: any

/presence
  /sessionId
    /userId
      userId: string
      lastSeen: number (timestamp)
      online: boolean
```

## Использование

### 1. Инициализация сервисов

```dart
// В main.dart или в локации инициализации Firebase
final rtdbService = FirebaseRealtimeDatabaseService();
await rtdbService.initialize();

final migrationService = MigrationService(rtdbService);
final hybridSessionService = HybridSessionService(rtdbService);
```

### 2. Миграция данных

Во время первого запуска выполните миграцию:

```dart
// Из DataMigrationScreen
final result = await migrationService.migrateAllSessions();
print('Успешно мигрировано: ${result.successCount} сессий');
```

### 3. Создание сессии

```dart
final session = await hybridSessionService.createSession(
  name: 'Забытые руины',
  description: 'Новая кампания',
  campaignName: 'Lost Temples',
  maxPlayers: 4,
);
```

### 4. Прослушивание обновлений

```dart
// Слушаем все сессии пользователя
hybridSessionService.watchUserSessions().listen((sessions) {
  print('Сессии обновлены: ${sessions.length}');
});

// Слушаем одну сессию
hybridSessionService.watchSession(sessionId).listen((session) {
  if (session != null) {
    print('Сессия: ${session.name}');
  }
});

// Слушаем членов сессии
hybridSessionService.watchMembers(sessionId).listen((members) {
  print('Членов: ${members.length}');
});
```

### 5. Работа с запросами

```dart
// Создать запрос
await hybridSessionService.createRequest(
  sessionId: sessionId,
  character: dmCharacter,
  type: RequestType.skill,
  baseFormula: '1d20 + STR',
  note: 'Проверка силы',
  audience: 'subset',
  targetUids: ['player1', 'player2'],
  abilityType: null,
  targetAc: null,
);

// Закрыть запрос
await hybridSessionService.closeRequest(sessionId, requestId);

// Слушаем запросы
hybridSessionService.watchRequests(sessionId).listen((requests) {
  print('Запросов: ${requests.length}');
});
```

## Преимущества гибридного подхода

| Операция | RTDB | Firestore |
|----------|------|-----------|
| **Создание** | Основной | Резервная копия |
| **Чтение** | Быстро (кэш) | При необходимости |
| **Обновление** | Реальное время | Синхронизировано |
| **Офлайн** | Полная поддержка | Ограничена |
| **Аналитика** | - | Полная поддержка |

## Правила безопасности RTDB

Добавьте в `rtdb.rules.json`:

```json
{
  "rules": {
    "sessions": {
      "$sessionId": {
        ".read": "root.child('sessions').child($sessionId).child('members').child(auth.uid).exists() || root.child('sessions').child($sessionId).child('dmId').val() === auth.uid",
        ".write": "root.child('sessions').child($sessionId).child('dmId').val() === auth.uid",
        "members": {
          ".read": true,
          ".write": false
        },
        "updatedAt": {
          ".write": "root.child('sessions').child($sessionId).child('dmId').val() === auth.uid"
        }
      }
    },
    "requests": {
      "$sessionId": {
        ".read": "root.child('sessions').child($sessionId).child('members').child(auth.uid).exists() || root.child('sessions').child($sessionId).child('dmId').val() === auth.uid",
        ".write": "root.child('sessions').child($sessionId).child('dmId').val() === auth.uid"
      }
    },
    "presence": {
      "$sessionId": {
        "$userId": {
          ".read": true,
          ".write": "$userId === auth.uid"
        }
      }
    }
  }
}
```

## Миграция данных

### Процесс миграции

1. **Проверка статуса**: Определить, сколько сессий нужно мигрировать
2. **Миграция**: Передать все сессии из Firestore в RTDB
3. **Проверка**: Убедиться, что все данные перенесены успешно
4. **Резервная копия**: Сохранить резервную копию в Firestore

### Отслеживание миграции

Используйте экран `DataMigrationScreen`:

```dart
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => DataMigrationScreen(
      rtdbService: rtdbService,
      migrationService: migrationService,
    ),
  ),
);
```

## Синхронизация в реальном времени

Все события синхронизируются автоматически:

```dart
// Событие в Firestore
session.copyWith(status: SessionStatus.paused)

// ↓ (HybridSessionService обновляет оба)

// Обновление в RTDB
status = 'paused'

// ↓ (Слушатели получают уведомление)

// Stream уведомляет подписчиков
watchSession() → новая Session с status = 'paused'
```

## Оптимизация производительности

### Кэширование

```dart
// RTDB кэширует данные локально
await rtdbService.initialize();
// Включен persistent cache размером 10 MB
```

### Использование Stream вместо Future

```dart
// ❌ Плохо - загружает данные один раз
Future<List<Session>> sessions = hybridSessionService.getRequests(sessionId);

// ✅ Хорошо - получает обновления в реальном времени
Stream<List<Request>> requests = hybridSessionService.watchRequests(sessionId);
```

### Индексирование

Убедитесь, что у вас есть индексы в Firestore для часто используемых запросов:

```firestore
Collection: sessions
Fields: joinCode (Ascending), dmId (Ascending)
```

## Отладка

### Логирование

Все операции логируются с префиксами:

```
✅ Успешно
❌ Ошибка
🔄 Процесс
📊 Статистика
```

### Проверка данных

```dart
// Проверить синхронизацию
final firestoreSession = await hybridSessionService._getSessionFromFirestore(sessionId);
final rtdbSession = await rtdbService.getSessionFromRTDB(sessionId);

// Они должны быть идентичны
assert(firestoreSession == rtdbSession);
```

## Решение проблем

### Проблема: Данные не синхронизируются

**Решение:**
1. Проверьте правила безопасности RTDB
2. Убедитесь, что у вас есть интернет соединение
3. Проверьте консоль логирования в Firebase Console

### Проблема: Медленные обновления

**Решение:**
1. Включите кэширование: `setPersistenceEnabled(true)`
2. Используйте Stream вместо Future
3. Оптимизируйте структуру данных

### Проблема: Высокий расход трафика

**Решение:**
1. Установите лимиты на количество слушателей
2. Используйте фильтры (`equalTo`, `limitToFirst` и т.д.)
3. Отключайте слушатели, когда они не нужны

```dart
@override
void dispose() {
  _subscription?.cancel(); // Отменяем подписку
  super.dispose();
}
```

## Заключение

Гибридный подход обеспечивает:
- 🚀 **Быстрые обновления** через RTDB
- 💾 **Безопасность данных** через Firestore резервную копию
- 📊 **Аналитику** через Firestore
- 🔄 **Синхронизацию** в реальном времени

Для вопросов и поддержки обратитесь к Firebase документации или создайте issue в репозитории.

