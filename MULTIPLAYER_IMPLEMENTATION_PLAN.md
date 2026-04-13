# 🎲 Real-time Roll Requests Implementation - PLAN

## ✅ Создано файлов:

1. **lib/models/roll_response.dart** - модель ответа игрока
2. **lib/services/realtime_requests_service.dart** - сервис управления запросами в RTDB
3. **lib/services/realtime_responses_service.dart** - сервис ответов игроков
4. **lib/screens/session_player_screen.dart** - экран для игроков
5. **lib/screens/session_home_screen.dart** - главный экран с табами
6. **lib/screens/session_info_screen.dart** - вкладка информации

## 📝 Осталось:

### 1. Обновить SessionDMScreen
Нужно обновить `lib/screens/session_dm_screen.dart` для:
- Добавления параметров `requestsService` и `responsesService`
- Изменения `createRequest()` для использования RTDB вместо Firestore
- Добавления `watchLiveRequests()` для реального времени
- Добавления отображения ответов игроков под каждым запросом
- Показа HIT/MISS для атак

### 2. Создать wrapper/рефактор
- Обновить места где используется SessionScreen
- Направить на SessionHomeScreen вместо SessionDMScreen напрямую
- Передать `presenceService`, `requestsService`, `responsesService`

### 3. Исправить баги
- Исправить баг в SessionScreen: `isDM(session.dmId)` должен быть `isDM(currentUserId)`

## 🏗️ Архитектура RTDB

```
liveSessions/
  {sessionId}/
    requests/
      {requestId}
        ├── sessionId
        ├── dmId
        ├── type (initiative|attack|damage|check|save)
        ├── formula (e.g., "1d20+5")
        ├── modifier (auto-calculated)
        ├── targetAc (nullable)
        ├── note (nullable)
        ├── abilityType (nullable)
        ├── status ("open"|"closed")
        ├── audience ("all"|"subset")
        ├── targetUids (array)
        └── createdAt (ISO string)
    
    responses/
      {requestId}/
        {uid}
          ├── uid
          ├── displayName
          ├── characterId
          ├── characterName
          ├── baseRoll (e.g., 15)
          ├── mode ("normal"|"advantage"|"disadvantage")
          ├── modifier (auto-calculated)
          ├── total (baseRoll + modifier)
          ├── success (true|false|null)
          └── createdAt (ISO string)
```

## 🔄 Data Flow

### DM создает запрос:
1. Заполняет форму с типом, кубиком, модификаторами, целью
2. Нажимает "Отправить"
3. App генерирует requestId
4. Создает Request объект
5. Записывает в RTDB под `liveSessions/{sessionId}/requests/{requestId}`

### Игрок видит запрос:
1. SessionPlayerScreen слушает `watchPlayerRequests()`
2. Отображает только релевантные запросы (audience=all или uid in targetUids)
3. Показывает карточку с типом, формулой, целью

### Игрок отвечает:
1. Нажимает "Ответить"
2. Открывается диалог
3. Вводит baseRoll (e.g., 15 на d20)
4. Выбирает режим (Normal/Advantage/Disadvantage)
5. App вычисляет modifier на основе:
   - Типа запроса (initiative → DEX, attack → STR/DEX, etc.)
   - Характеристики (если указана в abilityType)
   - Персонажа текущего игрока
6. Вычисляет total = baseRoll + modifier
7. Если атака с targetAc: success = total >= targetAc
8. Записывает в RTDB под `liveSessions/{sessionId}/responses/{requestId}/{uid}`

### DM видит ответы:
1. SessionDMScreen слушает `watchLiveRequests()`
2. Для каждого запроса слушает `watchResponses()`
3. Показывает карточку запроса с:
   - Типом, формулой, целью
   - Списком ответов игроков:
     - displayName / characterName
     - baseRoll, mode, modifier, total
     - HIT/MISS (если attack с targetAc)
   - Прогресс: responsesCount / expectedCount
4. Может закрыть запрос (переводит в status="closed")

## 🎯 Основные моменты

✅ **Реальное время** - все видят обновления мгновенно  
✅ **Модификаторы** - автоматически рассчитываются на клиенте игрока  
✅ **Presence** - один раз при входе в сессию, сохраняется при переключении табов  
✅ **Безопасность** - DM создает запросы, игроки только отвечают  
✅ **Гибкость** - поддержка аудитории (all/subset)

## 🚀 Следующие шаги

1. Обновить SessionDMScreen с новыми параметрами
2. Обновить места вызова SessionScreen на SessionHomeScreen
3. Добавить передачу сервисов через конструктор
4. Тестирование полного цикла

