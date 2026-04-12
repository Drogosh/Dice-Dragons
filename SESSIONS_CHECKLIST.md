# 🎲 Sessions Feature - Чек-лист Интеграции

## ✅ Реализовано

### 1. Модели
- ✅ `lib/models/session.dart` - Session, SessionMember, SessionRole, SessionStatus
  - Session с методами getPlayers(), getDM(), hasAvailableSpots()
  - SessionMember с UUID и metadata
  - Полная сериализация/десериализация

### 2. Сервис
- ✅ `lib/services/session_service.dart` - SessionService
  - createSession() - создать сессию
  - joinSessionByCode() - присоединиться
  - getSessions() - загрузить сессию
  - getUserSessions() - сессии пользователя
  - getDMSessions() - сессии где я DM
  - updateSession() - обновить (только DM)
  - deleteSession() - удалить (только DM)
  - leaveSession() - покинуть
  - watchSession() - live сессия
  - watchMembers() - live члены

### 3. Правила Безопасности
- ✅ `firestore.rules` - Firestore Security Rules
  - Чтение сессии только участниками
  - Запись (обновление) только DM
  - Валидация членов
  
- ✅ `rtdb.rules.json` - Realtime Database Rules
  - Live события от участников
  - Валидация типов событий

### 4. UI Экраны
- ✅ `lib/screens/sessions_list_screen.dart`
  - Создание новой сессии
  - Присоединение по коду
  - Отображение кода присоединения
  
- ✅ `lib/screens/session_screen.dart`
  - Информация о сессии
  - Список участников (real-time)
  - Управление сессией (DM)
  - Покидание сессии (игроки)

### 5. Документация
- ✅ `SESSIONS_IMPLEMENTATION.md` - Полная документация
  - Структура Firestore
  - Структура RTDB
  - API примеры
  - Сценарии использования
  - Интеграция в UI

---

## 🔧 Требуется Доделать

### Шаг 1: Применить Security Rules

**Firestore:**
1. Открыть Firebase Console → Firestore → Rules
2. Заменить на содержимое `firestore.rules`
3. Нажать Publish

```bash
# ИЛИ через CLI:
firebase deploy --only firestore:rules
```

**Realtime Database:**
1. Открыть Firebase Console → Realtime Database → Rules
2. Заменить на содержимое `rtdb.rules.json`
3. Нажать Publish

```bash
# ИЛИ через CLI:
firebase deploy --only database
```

### Шаг 2: Интегрировать в Приложение

**В `main_navigation_screen.dart`:**
```dart
// Добавить Tab для сессий
_pageController = PageController(initialPage: 0);

// Добавить в body список экранов:
final screens = [
  CharacterScreen(character: currentCharacter),
  InventoryScreen(inventory: currentInventory, character: currentCharacter),
  const SessionsListScreen(),  // ← НОВЫЙ ЭКРАН
  // ... другие экраны
];
```

**Или создать отдельную навигацию:**
```dart
// Кнопка в главном меню
ElevatedButton(
  onPressed: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const SessionsListScreen(),
      ),
    );
  },
  child: const Text('Сессии'),
),
```

### Шаг 3: Обновить pubspec.yaml

Проверить наличие зависимостей (уже должны быть):
```yaml
dependencies:
  firebase_core: ^4.6.0
  firebase_auth: ^6.3.0
  cloud_firestore: ^6.2.0
  firebase_database: ^12.2.0
```

### Шаг 4: Тестирование

#### Тест 1: Создание сессии
```
1. Запустить приложение
2. Перейти в "Сессии"
3. Кликнуть "Создать Сессию (DM)"
4. Ввести название: "Test Session"
5. Нажать "Создать"
6. ✅ Должен показаться код (6 символов)
```

#### Тест 2: Присоединение
```
1. На другом девайсе/аккаунте
2. Перейти в "Сессии"
3. Кликнуть "Присоединиться к Сессии"
4. Ввести код
5. Нажать "Присоединиться"
6. ✅ Должна загрузиться сессия с DM и участниками
```

#### Тест 3: Real-time
```
1. Открыть сессию в двух браузерах/девайсах одновременно
2. На одном экране кликнуть "Изменить название"
3. Изменить на "Updated Session"
4. На другом экране название должно измениться в real-time
5. ✅ Stream updates работает
```

---

## 📋 Дополнительные Фичи (Optional)

### Phase 2: Live Events
- [ ] Интегрировать RTDB для live событий
- [ ] Создать EventService для работы с событиями
- [ ] Синхронизация бросков кубика
- [ ] Chat в сессии

### Phase 3: Advanced
- [ ] Combat Tracker интеграция
- [ ] Initiative Tracker
- [ ] Character state sync
- [ ] Voice chat

### Phase 4: Polish
- [ ] Notifications о присоединении
- [ ] Session history
- [ ] Invite system (вместо кодов)
- [ ] Permissions system

---

## 🚀 Быстрый Старт

1. **Применить Rules:**
   ```bash
   firebase deploy --only firestore:rules,database
   ```

2. **Добавить SessionService:**
   ```dart
   final sessionService = SessionService();
   ```

3. **Использовать в UI:**
   ```dart
   // Создать
   final session = await sessionService.createSession(
     name: 'My Campaign',
     maxPlayers: 5,
   );
   
   // Присоединиться
   final session = await sessionService.joinSessionByCode('AB12CD');
   
   // Слушать изменения
   sessionService.watchSession(sessionId).listen((session) {
     print('Session updated: ${session?.name}');
   });
   ```

---

## 📊 Struktura Firestore (Reference)

```
firestore/
└── sessions/
    ├── {sessionId1}/
    │   ├── dmId: "user123"
    │   ├── name: "Adventure"
    │   ├── joinCode: "AB12CD"
    │   ├── status: "active"
    │   ├── maxPlayers: 5
    │   ├── createdAt: Timestamp
    │   ├── updatedAt: Timestamp
    │   └── members/
    │       ├── {user123}/
    │       │   ├── role: "dm"
    │       │   ├── displayName: "John"
    │       │   └── joinedAt: Timestamp
    │       └── {user456}/
    │           ├── role: "player"
    │           ├── displayName: "Jane"
    │           ├── characterId: "char789"
    │           └── joinedAt: Timestamp
    └── {sessionId2}/
        └── ...
```

---

## 🔒 Безопасность - Проверка

- ✅ Только участники могут читать сессию
- ✅ Только DM может обновлять сессию
- ✅ Только DM может удалить сессию
- ✅ Пользователь может добавить себя как игрока
- ✅ Валидация типов событий в RTDB

---

## 📝 Файлы

| Файл | Статус | Описание |
|------|--------|---------|
| `lib/models/session.dart` | ✅ | Модели сессии |
| `lib/services/session_service.dart` | ✅ | Сервис Firestore |
| `lib/screens/sessions_list_screen.dart` | ✅ | Создание/присоединение |
| `lib/screens/session_screen.dart` | ✅ | Экран сессии |
| `firestore.rules` | ✅ | Rules Firestore |
| `rtdb.rules.json` | ✅ | Rules RTDB |
| `SESSIONS_IMPLEMENTATION.md` | ✅ | Документация |

---

## ✨ Статус

**Статус**: 🚀 **Готово к Интеграции**

Все компоненты реализованы и документированы. Требуется:
1. Применить Security Rules
2. Добавить SessionsListScreen в навигацию
3. Провести тестирование

**Сложность**: Средняя  
**Время Интеграции**: 1-2 часа  
**Testing**: 30 минут

---

*Последнее обновление: 13 апреля 2026*

