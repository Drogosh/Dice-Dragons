# Решение: TimeoutException в createRequest

## Краткое резюме
Ошибка **"RTDB write timeout after 10s"** была вызвана **несоответствием типа данных** между кодом и Firebase Rules.

## Что было не так
**Firebase Rules требовали числовой timestamp:**
```json
"createdAt": { ".validate": "newData.isNumber()" }
```

**А код отправлял ISO строку:**
```dart
'createdAt': DateTime.now().toIso8601String()  // String, а не Number!
```

Когда Firebase правило отклоняет данные из-за типа, операция просто зависает и потом выбрасывает timeout (вместо явной ошибки валидации).

## Исправление
Все 4 сервиса обновлены:

| Файл | Изменение |
|------|-----------|
| `realtime_requests_service.dart` | `createdAt` отправляется как `millisecondsSinceEpoch` |
| `realtime_responses_service.dart` | `createdAt` отправляется как `millisecondsSinceEpoch` |
| `roll_response.dart` | Парсинг поддерживает оба формата (число→строка) |
| `firebase_realtime_database_service.dart` | Парсинг поддерживает оба формата (число→строка) |

## Проверка
Ошибка должна исчезнуть после этих изменений. Если проблема продолжится:

1. Проверьте, что Firebase Rules правильно развернуты (команда `firebase deploy --only database:rules`)
2. Убедитесь, что DM имеет доступ для записи (проверьте логи Firebase Console)
3. Проверьте сетевое соединение на Android устройстве

## Почему это случилось
Firebase Rules не дает явную ошибку валидации для типов - операция просто не выполняется. Flutter SDK ждет 10 секунд, а потом выбрасывает TimeoutException.

