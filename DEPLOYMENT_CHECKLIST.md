# 🚀 DEPLOYMENT CHECKLIST - RTDB TIMEOUT FIX

## Pre-Deployment

- [ ] Прочитал `RTDB_TIMEOUT_FINAL_FIX.md` - основной документ с полным описанием
- [ ] Все файлы исправлены (нет синтаксических ошибок)
- [ ] Ветка кода актуальна

## Step 1: Deploy Rules

```powershell
cd C:\Users\Luckk\AndroidStudioProjects\Dice_And_Dragons
firebase deploy --only database:rules
```

Ожидаемый результат:
```
✔ Database rules published successfully
```

**Проверка в Firebase Console:**
- Перейти: Realtime Database → Rules
- Убедиться что правила развернуты (показано время последнего обновления)

## Step 2: Rebuild App

```powershell
flutter clean
flutter pub get
flutter run
```

## Step 3: Test Scenario 1 (DM)

**Setup:**
1. Запустить приложение на Android устройстве/эмуляторе
2. Залогиниться как DM (или создать тестовую сессию)
3. Войти в свою сессию

**Проверки:**
```
✅ Логи показывают:
   🔧 initializeSessionInRTDB: sessionId=...
   ✅ dmId initialized in RTDB for session ...
```

**Создать запрос:**
1. Нажать "Создать запрос"
2. Выбрать тип (например, Проверка)
3. Ввести формулу (1d20)
4. Нажать "Отправить"

**Проверки результата:**
```
✅ Логи показывают:
   🎲 _createRequest: type=RequestType.check formula=1d20
   📝 createRequest payload: {...}
   ✅ createRequest SUCCESS: requestId=...
```

❌ **Если timeout:**
```
❌ createRequest ERROR: TimeoutException: RTDB write timeout after 10s
```

Действия:
1. Проверить что Firebase Rules развернуты
2. Проверить сетевое соединение
3. Перезагрузить приложение и повторить

## Step 4: Test Scenario 2 (Player)

**Setup:**
1. На втором устройстве/эмуляторе залогиниться как Player
2. Присоединиться к сессии DM (по коду)
3. Войти в SessionPlayerScreen

**Проверки:**
```
✅ Логи показывают:
   🔧 RealtimeResponsesService.initializeSessionInRTDB: sessionId=...
   ✅ dmId initialized in RTDB for session ...
```

**Отправить ответ на запрос:**
1. На DM: создать новый запрос (1d20)
2. На Player: должен увидеть запрос в списке
3. Player: нажать на карточку запроса
4. Player: выбрать результат броска
5. Player: нажать "Отправить ответ"

**Проверки результата:**
```
✅ Логи показывают:
   📤 submitResponse START: sessionId=... requestId=... uid=...
   ✅ submitResponse SUCCESS: ответ сохранен
```

❌ **Если timeout:**
```
❌ submitResponse ERROR: TimeoutException: RTDB write timeout
```

## Step 5: Verify Firebase Console

**Проверка структуры в Realtime Database:**

1. Открыть Firebase Console → Realtime Database
2. Перейти в `Data`
3. Развернуть `liveSessions` → выбрать сессию
4. Проверить структуру:

```
liveSessions/{sessionId}/
├── dmId: "user_123..."        ✅ Должна быть
├── requests/
│   └── {requestId}/
│       ├── id: "-Oq774yxUp..."
│       ├── dmId: "user_123..."
│       ├── characterName: "..."
│       ├── formula: "1d20"
│       ├── type: "check"
│       ├── status: "open"
│       ├── createdAt: 1776105316287  ✅ ЧИСЛО, не строка!
│       └── ...
└── responses/
    └── {requestId}/
        └── {playerId}/
            ├── uid: "player_456..."
            ├── displayName: "..."
            ├── baseRoll: 15
            ├── mode: "normal"
            ├── modifier: 2
            ├── total: 17
            ├── createdAt: 1776105316500  ✅ ЧИСЛО!
            └── success: true
```

## Post-Deployment

- [ ] Оба сценария успешно протестированы (DM и Player)
- [ ] Firebase Console показывает правильную структуру данных
- [ ] `createdAt` везде хранится как ЧИСЛО
- [ ] Нет timeout ошибок в логах
- [ ] Документация обновлена (этот файл)

## Rollback (если нужно)

Если что-то сломалось, откатить правила к старой версии:

```bash
# Посмотреть историю развертывания
firebase database:get rules

# Откатить на предыдущую версию (если она сохранена)
# Или вернуть старое содержимое rtdb.rules.json
firebase deploy --only database:rules
```

## Support

Если проблема продолжается:
1. Проверить все 4 файла с исправлением формата `createdAt`
2. Убедиться что `initializeSessionInRTDB()` вызывается в обоих экранах
3. Проверить Firebase Console → Rules и Database console для ошибок
4. Посмотреть детальные логи Firebase (Firebase Console → Realtime Database → Rules performance)

---

**Статус:** ✅ READY TO DEPLOY  
**Date:** 2026-04-13  
**Estimated Time:** 10-15 minutes

