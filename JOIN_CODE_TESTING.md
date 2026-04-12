# 🧪 Join Code - Testing & Examples

## Quick Test

```dart
// 1. DM создаёт сессию
final sessionService = SessionService();
final session = await sessionService.createSession(
  name: 'Test Campaign',
  maxPlayers: 5,
);

// Вывод: joinCode = "AB12CD" (пример)
print('Code: ${session.joinCode}');

// 2. Player присоединяется
final playerSession = await sessionService.joinSessionByCode('AB12CD');

// Вывод: Session загружена
print('Members: ${playerSession.getMemberCount()}');  // 2 (DM + Player)

// 3. Проверка member
final players = playerSession.getPlayers();
print('Players: ${players.length}');  // 1
```

---

## Test Scenarios

### Scenario 1: Successful Join
```dart
void testSuccessfulJoin() async {
  // Arrange
  final sessionService = SessionService();
  final session = await sessionService.createSession(
    name: 'Test',
    maxPlayers: 10,
  );
  final code = session.joinCode;

  // Act
  final joinedSession = await sessionService.joinSessionByCode(code);

  // Assert
  assert(joinedSession.getMemberCount() == 2);  // DM + Player
  assert(joinedSession.getPlayers().length == 1);
  print('✅ Successful join test passed');
}
```

### Scenario 2: Invalid Code
```dart
void testInvalidCode() async {
  final sessionService = SessionService();

  try {
    await sessionService.joinSessionByCode('INVALID');
    print('❌ Should throw exception');
  } catch (e) {
    assert(e.toString().contains('Session not found'));
    print('✅ Invalid code test passed');
  }
}
```

### Scenario 3: Session Full
```dart
void testSessionFull() async {
  final sessionService = SessionService();
  
  // Create session with max 1 player
  final session = await sessionService.createSession(
    name: 'Test',
    maxPlayers: 1,
  );

  // Try to add 2 players (should fail on second)
  try {
    await sessionService.joinSessionByCode(session.joinCode);  // First player
    await sessionService.joinSessionByCode(session.joinCode);  // Second player
    print('❌ Should throw exception');
  } catch (e) {
    assert(e.toString().contains('Session is full'));
    print('✅ Session full test passed');
  }
}
```

### Scenario 4: Already in Session
```dart
void testAlreadyInSession() async {
  final sessionService = SessionService();
  final session = await sessionService.createSession(
    name: 'Test',
  );

  // Join once
  await sessionService.joinSessionByCode(session.joinCode);

  // Try to join again
  try {
    await sessionService.joinSessionByCode(session.joinCode);
    print('❌ Should throw exception');
  } catch (e) {
    assert(e.toString().contains('Already in this session'));
    print('✅ Already in session test passed');
  }
}
```

---

## Code Generation Tests

### Test: Unique Code Generation
```dart
void testUniqueCodeGeneration() async {
  final sessionService = SessionService();
  final codes = <String>{};

  // Генерировать 10 кодов
  for (int i = 0; i < 10; i++) {
    final session = await sessionService.createSession(
      name: 'Test $i',
    );
    codes.add(session.joinCode);
  }

  // Проверить уникальность
  assert(codes.length == 10);
  print('✅ All 10 codes are unique');
}
```

### Test: Code Format
```dart
void testCodeFormat() {
  final regex = RegExp(r'^[A-Z0-9]{6}$');
  
  final validCodes = ['AB12CD', 'ABCDEF', '000000', 'ZZZZZZ'];
  for (final code in validCodes) {
    assert(regex.hasMatch(code));
    print('✅ Valid: $code');
  }

  final invalidCodes = ['ab12cd', 'ABC', 'ABCDEFG', 'AB12@#'];
  for (final code in invalidCodes) {
    assert(!regex.hasMatch(code));
    print('✅ Invalid rejected: $code');
  }
}
```

---

## UI Test Examples

### Test: Join Dialog
```dart
void testJoinDialog(WidgetTester tester) async {
  // Find button
  final joinButton = find.text('Присоединиться к Сессии');
  
  // Tap it
  await tester.tap(joinButton);
  await tester.pumpAndSettle();

  // Find text field
  final textField = find.byType(TextField);
  expect(textField, findsOneWidget);

  // Enter code
  await tester.enterText(textField, 'AB12CD');
  
  // Find submit button
  final submitButton = find.text('Присоединиться');
  
  // Tap submit
  await tester.tap(submitButton);
  await tester.pumpAndSettle();

  // Should navigate to session
  expect(find.byType(SessionScreen), findsOneWidget);
}
```

### Test: Error Display
```dart
void testErrorDisplay(WidgetTester tester) async {
  // Open dialog
  await tester.tap(find.text('Присоединиться к Сессии'));
  await tester.pumpAndSettle();

  // Enter invalid code
  await tester.enterText(find.byType(TextField), 'INVALID');
  
  // Submit
  await tester.tap(find.text('Присоединиться'));
  await tester.pumpAndSettle();

  // Should show error
  expect(find.text('Session not found'), findsOneWidget);
}
```

---

## Manual Testing Checklist

### Before Deploy
- [ ] Code format is A-Z0-9, 6 characters
- [ ] Codes are unique
- [ ] Player can join with valid code
- [ ] Player gets error with invalid code
- [ ] Player gets error when session full
- [ ] Player gets error if already in session
- [ ] Member document created correctly
- [ ] Real-time sync works
- [ ] Firestore indexed properly

### After Deploy
- [ ] Test on multiple devices
- [ ] Test with multiple accounts
- [ ] Test poor network conditions
- [ ] Test rapid joins
- [ ] Monitor Firestore usage

---

## Firestore Query Test

```firestore
// Test query in Firestore Console
db.collection("sessions")
  .where("joinCode", "==", "AB12CD")
  .where("status", "==", "active")
  .limit(1)
  .get()
```

Expected result:
```json
{
  "dmId": "user_123",
  "name": "My Campaign",
  "joinCode": "AB12CD",
  "status": "active",
  "maxPlayers": 5,
  "members": {
    "user_123": { "role": "dm" },
    "user_456": { "role": "player" }
  }
}
```

---

## Debug Logging

Add these to see what's happening:

```dart
// In SessionService
print('🔍 Searching for code: $joinCode');
print('📊 Found sessions: ${query.docs.length}');
print('👥 Member count: $memberCount');
print('📝 Adding member: $uid as $role');
print('✅ Successfully joined session: $sessionId');
```

---

## Performance Benchmarks

Expected timings:
- Code generation: < 10ms (local)
- Firestore query: 100-500ms (network)
- Member document create: 100-300ms (network)
- Total join time: 300-1000ms

If slower:
- Check Firestore indexes
- Check network connection
- Check rule complexity

---

## Known Limitations

- Code is case-sensitive (enforced uppercase)
- No QR code (Phase 2)
- No shareable links (Phase 2)
- No code expiration (static codes)

---

## Future Tests

When adding new features:
- [ ] QR code generation & scanning
- [ ] Link sharing
- [ ] Invite tokens
- [ ] Code expiration
- [ ] Join history

---

**Status**: Ready for testing  
**Automated**: Can be added to Firebase testing  
**Manual**: Use test scenarios above

