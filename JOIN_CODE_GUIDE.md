# 🎲 Join Code System - Полное Руководство

## Как Это Работает

### 1. Генерация Кода
Когда DM создаёт сессию, автоматически генерируется 6-символьный код:
- Формат: **A-Z, 0-9** (36 возможных символов)
- Примеры: `AB12CD`, `XY9Z8K`, `PQRS12`

```dart
// Автоматически генерируется в createSession()
final joinCode = await _generateUniqueJoinCode();

// Гарантирует уникальность
// Проверяет, нет ли такого кода в Firestore
// Пытается до 10 раз
```

### 2. Экран Присоединения

**Путь**: `lib/screens/sessions_list_screen.dart`

```dart
// Пользователь нажимает "Присоединиться к Сессии"
// Открывается диалог с полем ввода
// Пользователь вводит 6 символов (авто-капитализ)
// Нажимает "Присоединиться"

// Логика:
// 1. Поиск сессии по joinCode в Firestore
// 2. Проверка статуса (active)
// 3. Проверка лимита игроков
// 4. Добавление как member с role=player
// 5. Загрузка сессии и переход на экран
```

### 3. Процесс Присоединения

```dart
Future<void> joinByCode(String code) async {
  try {
    // Вызывается метод из SessionService
    final session = await sessionService.joinSessionByCode(code);
    
    // Если успешно:
    // - Найдена сессия с таким кодом
    // - Сессия активна
    // - Есть свободные места
    // - Пользователь не в сессии
    // - Member документ создан
    
    // Переход на SessionScreen
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => SessionScreen(session: session),
    ));
  } catch (e) {
    // Показать ошибку:
    // - "Session not found" - неверный код
    // - "Session is full" - полная сессия
    // - "Already in this session" - уже участвует
    // - другие ошибки Firebase
  }
}
```

---

## Проверка Кода: Что Происходит

### Шаг 1: Firestore Поиск

```firestore
Query:
- Collection: sessions
- Where joinCode == "AB12CD"
- Where status == "active"
- Limit: 1

Result:
- ✅ Найдена сессия
- ❌ Сессия не найдена
- ⚠️ Сессия найдена но статус ended
```

### Шаг 2: Валидация

```dart
// Проверка 1: Сессия существует?
if (query.docs.isEmpty) {
  throw Exception('Session not found');  // ❌ Ошибка
}

// Проверка 2: Есть свободные места?
final memberCount = await _getMemberCount(sessionId);
final maxPlayers = sessionData['maxPlayers'];

if (maxPlayers > 0 && memberCount >= maxPlayers) {
  throw Exception('Session is full');  // ❌ Ошибка
}

// Проверка 3: Пользователь уже в сессии?
final existingMember = await _firestore
    .collection('sessions')
    .doc(sessionId)
    .collection('members')
    .doc(user.uid)
    .get();

if (existingMember.exists) {
  throw Exception('Already in this session');  // ❌ Ошибка
}
```

### Шаг 3: Создание Member

```dart
// Если все проверки пройдены:
// Создаётся документ:

sessions/{sessionId}/members/{userId}
├── role: "player"
├── displayName: "John"
├── characterId: null  (опционально)
└── joinedAt: Timestamp.now()
```

---

## Использование

### Для Игрока (UI)

```
1. Открыть приложение
2. Перейти в "Сессии"
3. Нажать "Присоединиться к Сессии"
4. Ввести код (например: AB12CD)
5. Нажать "Присоединиться"

Результаты:
✅ Присоединился → Виден экран сессии
❌ Ошибка → Показана ошибка
```

### Для Разработчика (Code)

```dart
// Присоединиться
final session = await SessionService().joinSessionByCode(
  'AB12CD',
  characterId: 'char_123', // опционально
);

// Результат: Session объект с заполненными данными
print('Присоединился к: ${session.name}');
print('Участников: ${session.getMemberCount()}');

// Покинуть
await SessionService().leaveSession(session.id);
```

---

## Обработка Ошибок

### Ошибка: "Session not found"
**Причины**:
- Неверный код
- Сессия удалена
- Сессия завершена (статус != active)

**Решение**:
- Проверить код
- Попросить DM создать новую сессию

### Ошибка: "Session is full"
**Причина**: Максимум игроков уже достигнут

**Решение**:
- Дождаться когда игрок выйдет
- Попросить DM увеличить лимит

### Ошибка: "Already in this session"
**Причина**: Пользователь уже участник

**Решение**:
- Покинуть и присоединиться снова
- Просто открыть существующую сессию

---

## Валидация Кода на Клиенте

### Before Sending

```dart
// Проверка в UI:
if (codeController.text.length != 6) {
  showError('Введите правильный код (6 символов)');
  return;
}

// Проверка формата:
final code = codeController.text.toUpperCase();
if (!RegExp(r'^[A-Z0-9]{6}$').hasMatch(code)) {
  showError('Код может содержать только буквы и цифры');
  return;
}

// Отправить на сервер
await joinByCode(code);
```

### Server-side (Firestore)

```firestore
// Firestore сам проверит:
// - joinCode существует
// - статус active
// - права доступа (DM-only читает, но не пишет)
```

---

## Тестирование

### Test Case 1: Valid Code
```
Input: "AB12CD"
Flow:
1. ✅ Сессия найдена
2. ✅ Статус active
3. ✅ Есть место
4. ✅ Не в сессии
Result: ✅ Присоединился
```

### Test Case 2: Invalid Code
```
Input: "INVALID"
Flow:
1. ❌ Сессия не найдена
Result: ❌ "Session not found"
```

### Test Case 3: Session Full
```
Input: "AB12CD"
Flow:
1. ✅ Сессия найдена
2. ✅ Статус active
3. ❌ Нет места (memberCount >= maxPlayers)
Result: ❌ "Session is full"
```

### Test Case 4: Already Member
```
Input: "AB12CD"
Flow:
1. ✅ Сессия найдена
2. ✅ Статус active
3. ✅ Есть место
4. ❌ Уже в сессии
Result: ❌ "Already in this session"
```

---

## Database Schema

### Firestore структура

```
sessions/
├── {sessionId}/
│   ├── dmId: "user_123"
│   ├── name: "Adventure"
│   ├── joinCode: "AB12CD"  ← Ищем по этому
│   ├── status: "active"    ← Проверяем статус
│   ├── maxPlayers: 5       ← Проверяем лимит
│   └── members/
│       └── {userId}/
│           ├── role: "player"  ← Добавляем с этой ролью
│           ├── displayName: "John"
│           └── joinedAt: Timestamp
```

---

## Security (Firestore Rules)

```firestore
// Любой может создавать члена в сессии
// ЕСЛИ:
// - Он аутентифицирован
// - Он создаёт себя (memberDoc.id == auth.uid)
// - ИЛИ он DM сессии

allow create: if request.auth != null && 
              (request.resource.data.userId == request.auth.uid || 
               isDM(sessionId));
```

---

## Интеграция

### В SessionsListScreen (Уже сделано)

```dart
// Диалог ввода кода
void _showJoinSessionDialog() {
  final codeController = TextEditingController();

  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Присоединиться к сессии'),
      content: TextField(
        controller: codeController,
        inputFormatters: [UpperCaseTextFormatter()],
        maxLength: 6,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Отмена'),
        ),
        ElevatedButton(
          onPressed: () async {
            // Вызов joinSessionByCode
            final session = await _sessionService
                .joinSessionByCode(codeController.text);
            
            // Переход в сессию
            if (mounted) {
              Navigator.pop(context);
              _navigateToSession(session);
            }
          },
          child: const Text('Присоединиться'),
        ),
      ],
    ),
  );
}
```

---

## Примеры Использования

### Example 1: Simple Join
```dart
final sessionService = SessionService();

final session = await sessionService.joinSessionByCode('AB12CD');
print('Присоединился к ${session.name}');
```

### Example 2: With Error Handling
```dart
try {
  final session = await SessionService()
      .joinSessionByCode(code);
  
  // Успех
  showSuccessDialog(session);
} on Exception catch (e) {
  // Ошибка
  showErrorDialog(e.toString());
}
```

### Example 3: Full Flow
```dart
// 1. Пользователь вводит код
String code = 'AB12CD';

// 2. Валидация
if (code.length != 6) {
  print('❌ Invalid code');
  return;
}

// 3. Попытка присоединиться
try {
  final session = await SessionService()
      .joinSessionByCode(code);
  
  // 4. Успех - переход в сессию
  Navigator.push(context, MaterialPageRoute(
    builder: (_) => SessionScreen(session: session),
  ));
} catch (e) {
  // 5. Ошибка
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('Ошибка: $e')),
  );
}
```

---

## Troubleshooting

### Проблема: Код не работает
**Решение**:
1. Проверить правильность кода
2. Убедиться сессия активна
3. Проверить Firestore в консоли

### Проблема: "Already in session"
**Решение**:
1. Покинуть сессию
2. Попробовать присоединиться снова
3. Или просто открыть из списка

### Проблема: Медленное присоединение
**Решение**:
1. Проверить интернет
2. Убедиться индексы созданы в Firestore

---

## Performance Notes

- Запрос по joinCode: O(1) с индексом
- Проверка memberCount: Быстро
- Создание member документа: Быстро
- Загрузка сессии: Включает members подколлекцию

**Оптимизация**: Можно кэшировать сессию после присоединения

---

## Future Enhancements

- [ ] QR код вместо текста
- [ ] Автоматическое присоединение
- [ ] Clipboard вставка
- [ ] История присоединений
- [ ] Пригласительные ссылки

---

**Status**: ✅ Fully Implemented  
**File**: `lib/services/session_service.dart`  
**UI**: `lib/screens/sessions_list_screen.dart`

