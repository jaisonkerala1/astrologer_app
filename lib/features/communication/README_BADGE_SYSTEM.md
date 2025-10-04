# Communication Tab Badge System

## Overview
This document explains the tab badge system implementation for the Communication screen, which displays unread counts for both Calls and Messages tabs.

## Architecture

### Components

#### 1. **CommunicationService** (`services/communication_service.dart`)
State management service that tracks:
- Unread messages count
- Missed calls count
- Call and message data
- Real-time updates

**Key Methods:**
```dart
// Getters
int get unreadMessagesCount
int get missedCallsCount
int get totalUnreadCount

// Actions
void markMessagesAsRead()
void markMessageAsRead(String name)
void clearMissedCalls()
void addNewMessage({...})
void addNewCall({...})

// Testing helpers
void simulateNewMessage()
void simulateMissedCall()
void resetUnreadCounts()
```

#### 2. **TabBadge Widget** (`widgets/tab_badge.dart`)
Displays tab label with optional badge count.

**Features:**
- Red badge indicator with count
- Shows "99+" for counts over 99
- Animated badge with shadow
- Active/inactive color states

**Variants:**
- `TabBadge` - Full label with count badge
- `BadgeDot` - Simple red dot indicator
- `IconBadge` - Icon with badge count

#### 3. **Communication Screen Integration** (`screens/communication_screen.dart`)
Main screen that implements the badge system.

**Key Features:**
- Real-time badge updates via Provider
- Auto-clear badges when viewing tabs
- Individual message read tracking
- Test/demo menu for badge simulation

---

## How It Works

### Badge Display Logic

#### **Calls Tab Badge:**
- Shows count of **missed calls**
- Badge clears automatically when user switches to Calls tab (500ms delay)
- Missed calls marked as "viewed" but remain in call history

#### **Messages Tab Badge:**
- Shows total **unread message count** across all conversations
- Individual messages marked as read when conversation is opened
- Real-time updates as new messages arrive

### User Flow

```
┌─────────────────────────────────────────────────────┐
│  Communication Screen                               │
│                                                     │
│  [Calls ⓵]  [Messages ⓷]    ← Badge indicators    │
│     ↑          ↑                                    │
│  1 missed   3 unread                                │
├─────────────────────────────────────────────────────┤
│  User Action: Tap "Calls" tab                      │
├─────────────────────────────────────────────────────┤
│  Result:                                            │
│  • Switches to Calls tab                            │
│  • After 500ms: Badge clears                        │
│  • Missed calls remain visible in list              │
└─────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────┐
│  User Action: Tap on message conversation           │
├─────────────────────────────────────────────────────┤
│  Result:                                            │
│  • Opens chat screen                                │
│  • Marks that conversation as read                  │
│  • Updates badge count (-2 if 2 unread)            │
│  • Other conversations remain unread                │
└─────────────────────────────────────────────────────┘
```

---

## Integration with Main App

### Provider Registration
In `lib/app/app.dart`:

```dart
ChangeNotifierProvider<CommunicationService>(
  create: (context) => CommunicationService(),
),
```

### Accessing in Widgets
```dart
// Listen to changes
Consumer<CommunicationService>(
  builder: (context, commService, child) {
    return Text('Unread: ${commService.unreadMessagesCount}');
  },
)

// Read once without listening
final commService = Provider.of<CommunicationService>(context, listen: false);
commService.markMessageAsRead('Sarah Miller');
```

---

## Testing the Badge System

### Built-in Test Menu
The Communication screen includes a test menu (⋮ icon in app bar):

1. **Test New Message** - Simulates receiving a new message
   - Adds test message
   - Increments badge count
   - Shows at top of messages list

2. **Test Missed Call** - Simulates a missed call
   - Adds missed call to history
   - Increments calls badge
   - Shows in call list

3. **Reset Badges** - Clears all unread counts
   - Marks all messages as read
   - Clears all missed calls
   - Resets both badges to 0

### Testing Workflow
```bash
1. Open Communication screen
2. Tap ⋮ menu → "Test New Message"
3. Observe Messages badge shows count
4. Switch to Messages tab
5. Tap on the test message conversation
6. Observe badge decrements

7. Tap ⋮ menu → "Test Missed Call"
8. Observe Calls badge shows count
9. Switch to Calls tab
10. Observe badge clears after brief delay
```

---

## Future Enhancements

### Real-time Integration
To connect with actual backend:

```dart
// In CommunicationService

Stream<Message> _messageStream;
Stream<Call> _callStream;

void initializeRealTimeListeners() {
  // WebSocket or Firebase listener
  _messageStream = messageRepository.getMessageStream();
  _messageStream.listen((message) {
    addNewMessage(
      name: message.senderName,
      preview: message.content,
      avatar: message.senderInitials,
      isOnline: message.isOnline,
    );
  });
  
  _callStream = callRepository.getCallStream();
  _callStream.listen((call) {
    if (call.status == CallStatus.missed) {
      addNewCall(
        name: call.callerName,
        type: 'Missed',
        status: 'missed',
        avatar: call.callerInitials,
      );
    }
  });
}
```

### Push Notifications Integration
```dart
// When receiving push notification for new message
void handleMessageNotification(Map<String, dynamic> data) {
  final commService = context.read<CommunicationService>();
  commService.addNewMessage(
    name: data['senderName'],
    preview: data['messagePreview'],
    avatar: data['senderInitials'],
    isOnline: data['isOnline'] ?? false,
  );
}
```

### Badge Persistence
```dart
// Save badge state
Future<void> saveBadgeState() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setInt('unread_messages', _unreadMessagesCount);
  await prefs.setInt('missed_calls', _missedCallsCount);
}

// Restore badge state
Future<void> restoreBadgeState() async {
  final prefs = await SharedPreferences.getInstance();
  _unreadMessagesCount = prefs.getInt('unread_messages') ?? 0;
  _missedCallsCount = prefs.getInt('missed_calls') ?? 0;
  notifyListeners();
}
```

---

## Best Practices

### 1. **Badge Clearing Strategy**
- **Calls:** Clear on tab view (user sees list = acknowledgment)
- **Messages:** Clear on conversation open (user reads specific chat)

### 2. **Performance**
- Use `listen: false` when only triggering actions
- Minimize unnecessary rebuilds with `Consumer` scope
- Debounce rapid badge updates

### 3. **User Experience**
- Clear feedback when badges update
- Smooth animations (500ms delay feels natural)
- Consistent badge styling across app

### 4. **Accessibility**
- Badge counts announced by screen readers
- High contrast red badges visible to all users
- Large touch targets (not just badge, whole tab)

---

## Troubleshooting

### Badge not updating
**Problem:** Badge count doesn't change when adding messages/calls

**Solution:**
```dart
// Ensure you're calling notifyListeners()
void addNewMessage(...) {
  // ... add message logic
  _updateUnreadCounts();  // This calls notifyListeners()
}
```

### Badge shows wrong count
**Problem:** Badge count doesn't match actual unread items

**Solution:**
```dart
// Manually recalculate
commService._updateUnreadCounts();
```

### Multiple badges for same message
**Problem:** Same message creates multiple badges

**Solution:** Check message deduplication logic in `addNewMessage()`

---

## API Reference

### CommunicationService

| Method | Parameters | Returns | Description |
|--------|-----------|---------|-------------|
| `unreadMessagesCount` | - | `int` | Total unread messages |
| `missedCallsCount` | - | `int` | Total missed calls |
| `markMessageAsRead` | `String name` | `void` | Mark conversation as read |
| `clearMissedCalls` | - | `void` | Clear all missed call badges |
| `simulateNewMessage` | - | `void` | Test: add fake message |
| `simulateMissedCall` | - | `void` | Test: add fake missed call |

### TabBadge Widget

| Property | Type | Required | Description |
|----------|------|----------|-------------|
| `label` | `String` | Yes | Tab label text |
| `count` | `int` | Yes | Badge count (0 = no badge) |
| `isActive` | `bool` | Yes | Active tab state |
| `activeColor` | `Color` | Yes | Color when active |
| `inactiveColor` | `Color` | Yes | Color when inactive |

---

## Summary

The badge system provides:
- ✅ Real-time unread counts
- ✅ Separate tracking for calls and messages
- ✅ Automatic badge clearing
- ✅ Easy testing and simulation
- ✅ Clean, maintainable architecture
- ✅ Ready for production integration

Next steps: Connect to your backend API and replace mock data with real data streams.

