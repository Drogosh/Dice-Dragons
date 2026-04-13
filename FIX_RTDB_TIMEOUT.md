# Исправление RTDB Timeout ошибки

## Проблема
При попытке создания запроса на бросок через DM экран возникала ошибка:
```
❌ createRequest ERROR: TimeoutException: RTDB write timeout after 10s for requestId=-Oq7626K99NAgZcAA3LD
```

## Причина
Firebase Rules требовали, чтобы поле `createdAt` было числом (timestamp в миллисекундах):
```json
"createdAt": { ".validate": "newData.isNumber()" }
```

Но код отправлял ISO 8601 строку:
```dart
'createdAt': DateTime.now().toIso8601String(),  // ❌ Отправляется строка, правила требуют число
```

Это вызывало **ошибку валидации** на Firebase, которая приводила к timeout вместо явного сообщения об ошибке валидации.

## Решение
Изменены все места отправки данных в RTDB на использование миллисекундных timestamp вместо ISO строк:

### 1. `realtime_requests_service.dart` (строка 47)
```dart
// ДО
'createdAt': DateTime.now().toIso8601String(),

// ПОСЛЕ
'createdAt': DateTime.now().millisecondsSinceEpoch,
```

### 2. `realtime_responses_service.dart` (строка 40)
```dart
// ДО
'createdAt': DateTime.now().toIso8601String(),

// ПОСЛЕ
'createdAt': DateTime.now().millisecondsSinceEpoch,
```

### 3. `roll_response.dart` - Обновлен парсинг (строка 54)
```dart
// Теперь правильно обрабатывает оба формата: число (из Firebase) и строку (обратная совместимость)
factory RollResponse.fromMap(String uid, Map<String, dynamic> map) {
  String createdAtStr;
  final createdAtValue = map['createdAt'];
  if (createdAtValue is int) {
    // Convert milliseconds timestamp to ISO 8601 string
    createdAtStr = DateTime.fromMillisecondsSinceEpoch(createdAtValue).toIso8601String();
  } else if (createdAtValue is String) {
    createdAtStr = createdAtValue;
  } else {
    createdAtStr = DateTime.now().toIso8601String();
  }
  // ...
}
```

### 4. `firebase_realtime_database_service.dart` - Обновлен парсинг (строка 584)
```dart
// Теперь правильно обрабатывает оба формата
Request _parseRequest(Map requestData) {
  String? createdAtStr;
  final createdAtValue = requestData['createdAt'];
  if (createdAtValue is int) {
    createdAtStr = DateTime.fromMillisecondsSinceEpoch(createdAtValue).toIso8601String();
  } else if (createdAtValue is String) {
    createdAtStr = createdAtValue;
  }
  // ...
}
```

## Результат
✅ Запросы теперь успешно записываются в RTDB  
✅ Нет timeout ошибок при создании запросов  
✅ Обратная совместимость: парсинг поддерживает оба формата (число и строка)

## Технические детали
- **Firebase Rules требуют**: число (миллисекунды) для поля `createdAt` в `liveSessions`
- **Модели могут хранить**: строку (ISO 8601) для удобства отображения
- **При отправке в Firebase**: всегда конвертируем в число
- **При чтении из Firebase**: конвертируем обратно в ISO строку для моделей

## Тестирование
1. Откройте DM экран сессии
2. Попытайтесь создать запрос (например, 1d20)
3. Проверьте, что запрос успешно создается без timeout ошибок
4. Убедитесь, что игроки видят запрос в реальном времени

## Файлы изменены
- `lib/services/realtime_requests_service.dart`
- `lib/services/realtime_responses_service.dart`
- `lib/models/roll_response.dart`
- `lib/services/firebase_realtime_database_service.dart`

