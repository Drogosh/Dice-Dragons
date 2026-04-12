# 🚀 SESSIONS DEPLOYMENT GUIDE

## Prerequisites
- ✅ Firebase project configured
- ✅ Firestore enabled
- ✅ Realtime Database enabled
- ✅ Firebase CLI installed (`firebase-tools`)

---

## Step 1: Deploy Security Rules (CRITICAL!)

### Option A: Using Firebase CLI (Recommended)

```bash
# Navigate to project
cd C:\Users\Luckk\AndroidStudioProjects\Dice_And_Dragons

# Deploy all rules
firebase deploy --only firestore:rules,database

# OR separately:
firebase deploy --only firestore:rules
firebase deploy --only database
```

### Option B: Manual Deployment

#### Firestore
1. Go to https://console.firebase.google.com
2. Select your project
3. Go to **Firestore Database** → **Rules**
4. Replace content with `firestore.rules`
5. Click **Publish**

#### Realtime Database
1. Go to https://console.firebase.google.com
2. Select your project
3. Go to **Realtime Database** → **Rules**
4. Replace content with `rtdb.rules.json`
5. Click **Publish**

---

## Step 2: Verify Rules

### Test Firestore Rules
```bash
firebase emulators:start --only firestore
```

### Test RTDB Rules
```bash
firebase emulators:start --only database
```

---

## Step 3: Integrate into App

### In `lib/main.dart` (if using tabs):
```dart
// Add import
import 'screens/sessions_list_screen.dart';

// In _MainNavigationScreenState:
List<Widget> get _pages => [
  CharacterScreen(...),
  InventoryScreen(...),
  const SessionsListScreen(),  // ← ADD HERE
  // ... other screens
];

// Update _navigationItems:
final _navigationItems = [
  BottomNavigationBarItem(label: 'Character', icon: Icon(Icons.person)),
  BottomNavigationBarItem(label: 'Inventory', icon: Icon(Icons.backpack)),
  BottomNavigationBarItem(label: 'Sessions', icon: Icon(Icons.group)),  // ← ADD
  // ...
];
```

### Or add via drawer menu:
```dart
// In drawer/menu:
ListTile(
  leading: Icon(Icons.group),
  title: const Text('Sessions'),
  onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const SessionsListScreen(),
      ),
    );
  },
),
```

---

## Step 4: Test Integration

### Test 1: Create Session
```
1. Run: flutter run -d windows
2. Navigate to Sessions
3. Click "Create Session (DM)"
4. Fill in: Name = "Test Campaign"
5. Click "Create"
6. ✅ Should show join code (6 chars)
```

### Test 2: Join Session
```
1. Open app on different account/device
2. Navigate to Sessions
3. Click "Join Session"
4. Enter code from Test 1
5. Click "Join"
6. ✅ Should show session with members
```

### Test 3: Real-time Updates
```
1. Keep both devices on session screen
2. On Device A: Click "Edit" → Change name
3. Device B: ✅ Name updates automatically
```

### Test 4: Leave Session
```
1. On Device B: Click menu → "Leave Session"
2. Device A: ✅ Player count decreases
```

---

## Troubleshooting

### Error: "Permission denied" on create
**Issue**: Security rules not deployed  
**Solution**: 
```bash
firebase deploy --only firestore:rules
```

### Error: "Session not found" on join
**Issue**: Code is wrong or session ended  
**Solution**:
- Check code is exactly 6 characters
- Verify session status is "active"
- Create new session and try again

### Real-time updates not working
**Issue**: Stream not connecting  
**Solution**:
- Check internet connection
- Verify RTDB is enabled in Firebase
- Check RTDB rules are deployed

### Members not showing
**Issue**: Members subcollection not loaded  
**Solution**:
- Check Firestore has sessions/{id}/members/{uid}
- Verify user is authenticated
- Check member can read (in rules)

---

## Production Checklist

- ✅ Rules deployed to Firestore
- ✅ Rules deployed to RTDB
- ✅ SessionsListScreen added to navigation
- ✅ Tested create session (DM)
- ✅ Tested join session (Player)
- ✅ Tested real-time updates
- ✅ Tested member operations
- ✅ Error handling works
- ✅ No console errors
- ✅ Performance acceptable (< 2s load)

---

## Performance Optimization (Optional)

### Enable Indexes
If you see warning about missing indexes:
1. Firebase Console → Firestore → Indexes
2. Create suggested indexes
3. Wait for index creation

### Firestore Index for Sessions
```
Collection: sessions
Query fields:
- dmId (Ascending)
- updatedAt (Descending)
```

---

## Monitoring (Optional)

### View Rules in Firebase Console
```
Firestore → Rules
Realtime Database → Rules
```

### Monitor Traffic
```
Firestore → Usage
Realtime Database → Usage
```

---

## Rollback (If Needed)

### Revert Rules
```bash
git checkout firestore.rules rtdb.rules.json
firebase deploy --only firestore:rules,database
```

### Revert Code
```bash
git reset --hard HEAD~1
```

---

## Common Issues & Solutions

| Issue | Solution |
|-------|----------|
| Can't create session | Rules not deployed |
| Can't join session | Check code, session active |
| Updates not real-time | Check RTDB enabled |
| Member list empty | Check subcollection created |
| Performance slow | Check indexes created |
| Rules validation error | Check rules syntax |

---

## Support

### Documentation
- `SESSIONS_IMPLEMENTATION.md` - Full API docs
- `SESSIONS_CHECKLIST.md` - Integration guide
- Code comments in service files

### Testing
- Use Firebase Emulators for local testing
- Test with multiple devices
- Monitor Firestore/RTDB in console

---

## Next Steps After Deployment

1. ✅ Deploy rules
2. ✅ Integrate in app
3. ✅ Test thoroughly
4. ⏳ Add notifications (optional)
5. ⏳ Add voice chat (optional)
6. ⏳ Add combat tracker (optional)

---

**Status**: 🚀 Ready to Deploy  
**Estimated Time**: 30 minutes  
**Complexity**: Low (rules already written)

Deploy with confidence! 🎉

