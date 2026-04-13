# 🚀 Real-time Database - Краткая инструкция

## ✅ Что было создано

### 1. **firebase_realtime_database_service.dart**
Основной сервис для работы с Firebase Realtime Database:
- ✨ Синхронизация сессий в реальном времени
- 👥 Управление членами сессии
- 🎲 Работа с запросами (requests)
- 📊 Отслеживание присутствия (presence)

### 2. **hybrid_session_service.dart**
Гибридный сервис, объединяющий RTDB и Firestore:
- 📁 Основные данные в RTDB (быстро)
- 💾 Резервная копия в Firestore (надежно)
- 🔄 Автоматическая синхронизация
- 📈 Поддержка аналитики

### 3. **migration_service.dart**
Сервис для миграции данных:
- 📦 Массовая миграция сессий
- ✅ Проверка статуса миграции
- 🔍 Синхронизация отдельных сессий
- 📊 Отчеты о ходе миграции

### 4. **data_migration_screen.dart**
UI экран для управления миграцией:
- 🖥️ Визуальное отображение статуса
- 🎯 Управление миграцией
- 📈 Результаты и статистика
- ⚡ Обновление в реальном времени

### 5. **Документация и правила**
- 📖 RTDB_IMPLEMENTATION.md - полная документация
- 🔐 rtdb.rules.json - правила безопасности

## 🚀 Быстрый старт

### Шаг 1: Инициализация в main.dart

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Инициализация Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Инициализация RTDB сервиса
  final rtdbService = FirebaseRealtimeDatabaseService();
  await rtdbService.initialize();
  
  // Создание миграционного сервиса
  final migrationService = MigrationService(rtdbService);
  
  // Создание гибридного сервиса сессий
  final hybridSessionService = HybridSessionService(rtdbService);
  
  runApp(MyApp(
    rtdbService: rtdbService,
    migrationService: migrationService,
    hybridSessionService: hybridSessionService,
  ));
}
```

### Шаг 2: Миграция данных

Во время первого запуска покажите экран миграции:

```dart
// В settings или admin экране
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

Или автоматическая миграция:

```dart
// При запуске приложения
final result = await migrationService.migrateAllSessions();
print('✅ Мигрировано: ${result.successCount} сессий');
```

### Шаг 3: Использование в коде

Вместо старого `SessionService` используйте `HybridSessionService`:

```dart
// ✅ Вместо этого:
// final sessionService = SessionService();

// Используйте это:
final sessionService = HybridSessionService(rtdbService);
```

## 📋 Основные операции

### Создание сессии
```dart
final session = await hybridSessionService.createSession(
  name: 'Новая сессия',
  description: 'Описание',
  campaignName: 'Кампания',
  maxPlayers: 4,
);
```

### Получение сессии
```dart
final session = await hybridSessionService.getSession(sessionId);
```

### Слушание обновлений сессии
```dart
hybridSessionService.watchSession(sessionId).listen((session) {
  if (session != null) {
    setState(() {
      currentSession = session;
    });
  }
});
```

### Слушание всех сессий пользователя
```dart
hybridSessionService.watchUserSessions().listen((sessions) {
  setState(() {
    userSessions = sessions;
  });
});
```

### Слушание членов сессии
```dart
hybridSessionService.watchMembers(sessionId).listen((members) {
  setState(() {
    sessionMembers = members;
  });
});
```

### Создание запроса
```dart
await hybridSessionService.createRequest(
  sessionId: sessionId,
  character: dmCharacter,
  type: RequestType.skill,
  baseFormula: '1d20 + STR',
  note: 'Проверка Атлетики',
  audience: 'subset',
  targetUids: ['player1', 'player2'],
  abilityType: null,
  targetAc: null,
);
```

### Закрытие запроса
```dart
await hybridSessionService.closeRequest(sessionId, requestId);
```

## 🔐 Развертывание правил безопасности

### Используя Firebase CLI

```bash
# Установка Firebase CLI (если не установлен)
npm install -g firebase-tools

# Логин в Firebase
firebase login

# Выбор проекта
firebase use --add

# Развертывание правил RTDB
firebase deploy --only database
```

### Через Firebase Console

1. Перейти в **Realtime Database** → **Правила**
2. Скопировать содержимое из `rtdb.rules.json`
3. Нажать **Опубликовать**

## 📊 Структура данных в RTDB

```
/sessions
  /sessionId
    id: "session-123"
    dmId: "user-456"
    name: "Забытые руины"
    joinCode: "ABC123"
    status: "active"
    members:
      /uid1
        role: "dm"
        displayName: "Ведущий"
      /uid2
        role: "player"
        displayName: "Приключенец"
    createdAt: 1234567890
    updatedAt: 1234567890

/requests
  /sessionId
    /requestId
      characterName: "Враг"
      formula: "1d20 + 3"
      status: "open"

/presence
  /sessionId
    /userId
      online: true
      lastSeen: 1234567890
```

## 🎯 Лучшие практики

### ✅ Делайте так:

```dart
// Слушайте изменения в реальном времени
Stream<Session?> session = hybridSessionService.watchSession(id);

// Отписывайтесь при выходе из экрана
@override
void dispose() {
  _subscription?.cancel();
  super.dispose();
}

// Кэшируйте данные локально
final cachedSession = await rtdbService.getSessionFromRTDB(id);
```

### ❌ Не делайте так:

```dart
// Не загружайте данные в цикле
for (int i = 0; i < 100; i++) {
  await hybridSessionService.getSession(sessionIds[i]);
}

// Не создавайте новые слушатели без отписки
build() {
  hybridSessionService.watchSession(id).listen(...); // ⚠️ Утечка памяти
}

// Не используйте Future вместо Stream
Future<Session?> session = hybridSessionService.getSession(id); // Один раз
Stream<Session?> session = hybridSessionService.watchSession(id); // Обновления
```

## 🐛 Отладка

### Проверить логи:

```dart
// Включить подробное логирование
debugPrint('🔄 Сессия загружена из RTDB');
debugPrint('✅ Запрос создан успешно');
debugPrint('❌ Ошибка: $e');
```

### Проверить синхронизацию:

```dart
// Получить данные из обоих источников
final rtdbSession = await rtdbService.getSessionFromRTDB(id);
final firestoreSession = await hybridSessionService._getSessionFromFirestore(id);

// Сравнить
print(rtdbSession == firestoreSession ? 'Синхронизировано ✅' : 'Рассинхронизировано ❌');
```

## 📞 Поддержка

- 📖 Документация: [RTDB_IMPLEMENTATION.md](RTDB_IMPLEMENTATION.md)
- 🔐 Правила: [rtdb.rules.json](rtdb.rules.json)
- 🆘 Помощь: Firebase Console → Realtime Database → Diagnostics

## 🎉 Готово!

Real-time Database полностью интегрирована! Ваше приложение теперь:

- ⚡ Получает обновления в реальном времени
- 💾 Сохраняет данные безопасно в Firestore
- 🔄 Синхронизирует данные автоматически
- 📱 Работает офлайн с автоматической синхронизацией
- 🚀 Обеспечивает лучший UX для многопользовательского

**Всё готово к использованию!** 🎊

