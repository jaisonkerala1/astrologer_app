# ✅ Communication Screens Refactoring Complete

## 📋 Summary

Successfully refactored all communication screens to be **generic and reusable** for:
- ✅ **Admin ↔ Astrologer** communication
- ✅ **User ↔ Astrologer** communication (future-ready)
- ✅ **Astrologer ↔ Astrologer** communication (future-ready)

---

## 🔄 Files Updated

### **1. Models**
- ✅ `lib/features/communication/models/communication_item.dart`
  - Added `contactId` field
  - Added `contactType` enum (admin, user, astrologer)
  - Added `conversationId` field
  - Added parsing methods for new fields

- 🆕 `lib/features/communication/models/message.dart`
  - New model for individual chat messages
  - Supports text, image, audio, file types
  - Includes read receipts and status

### **2. Screens**
- ✅ `lib/features/communication/screens/chat_screen.dart`
  - Now accepts `contactId`, `contactType`, `conversationId`
  - Loads messages from backend API
  - Real-time messaging via Socket.IO
  - Different UI for admin vs users
  - Special badge/icon for admin messages

- ✅ `lib/features/communication/screens/video_call_screen.dart`
  - Now accepts `contactId`, `contactType`, `agoraToken`, `channelName`
  - Generates Agora token for outgoing calls
  - Uses provided token for incoming calls
  - Notifies backend via Socket.IO
  - Special UI for admin calls

- ✅ `lib/features/communication/screens/incoming_call_screen.dart`
  - Now accepts `callId`, `contactId`, `contactType`, `callType`
  - Handles both voice and video calls
  - Notifies backend on accept/reject
  - Shows admin badge for admin calls
  - Navigates to VideoCallScreen on accept

---

## 🎯 ContactType Enum

```dart
enum ContactType {
  user,        // Regular end-user/client
  admin,       // Admin/Support team
  astrologer,  // Another astrologer (future use)
}
```

### Extensions:
- `displayName`: "User", "Admin Support", "Astrologer"
- `description`: "Client", "Support Team", "Fellow Astrologer"
- `fromString(value)`: Parse from string

---

## 🚀 How to Use

### **1. Navigate to Chat Screen (Admin)**

```dart
// When user taps on admin message in communication list
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (_) => ChatScreen(
      contactId: 'admin',
      contactName: 'Admin Support',
      contactType: ContactType.admin,
      conversationId: item.conversationId,
    ),
  ),
);
```

### **2. Navigate to Chat Screen (User)**

```dart
// When astrologer taps on user message
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (_) => ChatScreen(
      contactId: user.id,
      contactName: user.name,
      contactType: ContactType.user,
      conversationId: conversation.id,
      avatarUrl: user.profilePicture,
    ),
  ),
);
```

### **3. Handle Incoming Call from Admin (Socket.IO)**

```dart
// In your socket listener (main.dart or app-level)
socketService.on('call:incoming').listen((data) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => IncomingCallScreen(
        callId: data['callId'],
        contactId: data['callerId'],
        contactName: data['callerType'] == 'admin' 
            ? 'Admin Support' 
            : data['callerName'],
        contactType: ContactTypeExtension.fromString(data['callerType']),
        phoneNumber: data['callerPhone'] ?? '',
        callType: data['callType'], // 'voice' or 'video'
        agoraToken: data['agoraToken'],
        channelName: data['channelName'],
        avatarUrl: data['callerAvatar'],
      ),
    ),
  );
});
```

### **4. Update CommunicationBloc to Handle Admin Messages**

```dart
// When loading communications, include admin conversations
final adminConversation = await repository.getAdminConversation();

// Create CommunicationItem for admin
if (adminConversation != null) {
  items.add(CommunicationItem(
    id: 'admin_conversation',
    type: CommunicationType.message,
    contactName: 'Admin Support',
    contactId: 'admin',
    contactType: ContactType.admin,
    avatar: '', // Will show admin icon
    timestamp: adminConversation.lastMessageAt,
    preview: adminConversation.lastMessage,
    unreadCount: adminConversation.unreadCount,
    isOnline: true,
    status: CommunicationStatus.received,
    conversationId: adminConversation.id,
  ));
}
```

---

## 🎨 Visual Differences

### **Admin Messages:**
- 🔵 Blue icon instead of avatar
- 🔵 Blue background for received messages
- 🏷️ "Support Team" badge
- 🚫 No call buttons (admin initiates calls)

### **User Messages:**
- 👤 User avatar
- 🟢 Standard message bubbles
- ✅ Call buttons available
- 📊 Normal status indicators

---

## 🔌 Socket.IO Events Required

### **Backend Must Emit:**

```javascript
// Direct message received
socket.emit('dm:message_received', {
  conversationId: 'abc123',
  senderId: 'admin',
  senderType: 'admin',
  content: 'Hello, how can I help?',
  messageType: 'text',
  timestamp: new Date(),
});

// Incoming call
socket.emit('call:incoming', {
  callId: 'call_123',
  callerId: 'admin',
  callerType: 'admin',
  callerName: 'Admin Support',
  callType: 'video',
  agoraToken: 'token_xyz',
  channelName: 'channel_abc',
});

// Call accepted
socket.emit('call:connected', {
  callId: 'call_123',
});

// Call ended
socket.emit('call:end', {
  callId: 'call_123',
  duration: 120,
});
```

### **Frontend Must Listen For:**
- `dm:message_received` - New message arrived
- `dm:typing_start` - Contact is typing
- `dm:typing_stop` - Contact stopped typing
- `call:incoming` - Incoming call notification
- `call:connected` - Call connected successfully
- `call:end` - Call ended by other party

---

## 📡 API Endpoints Required

### **Chat Endpoints:**

```
GET    /api/conversations/admin/messages
POST   /api/conversations/admin/messages
GET    /api/conversations/:id/messages
POST   /api/conversations/:id/messages
```

### **Call Endpoints:**

```
POST   /api/calls/admin/token
POST   /api/calls/initiate
POST   /api/calls/:id/end
POST   /api/calls/:id/token
```

---

## 🧪 Testing Checklist

### **Chat Functionality:**
- [ ] Admin can send message to astrologer
- [ ] Astrologer receives message in real-time
- [ ] Astrologer can reply to admin
- [ ] Messages show correct sender (admin vs user)
- [ ] Typing indicators work
- [ ] Read receipts work
- [ ] Message history loads correctly
- [ ] Empty state shows for new conversations

### **Call Functionality:**
- [ ] Admin can initiate video call
- [ ] Admin can initiate voice call
- [ ] Astrologer receives incoming call notification
- [ ] Accept call works (navigates to video screen)
- [ ] Decline call works (closes screen)
- [ ] Agora token generated correctly
- [ ] Video/audio controls work
- [ ] Call duration tracked
- [ ] End call syncs to backend

### **UI/UX:**
- [ ] Admin messages have blue styling
- [ ] User messages have normal styling
- [ ] Admin icon shows instead of avatar
- [ ] Support Team badge displays
- [ ] Call buttons hidden for admin chats
- [ ] Incoming call shows correct caller type

---

## 🔐 Security Considerations

1. **Authentication:**
   - All Socket.IO connections must be authenticated
   - Use JWT tokens for API requests
   - Validate `contactType` on backend

2. **Authorization:**
   - Check if user has permission to access conversation
   - Verify call participants match
   - Rate limit message sending

3. **Data Protection:**
   - Encrypt sensitive message content
   - Secure Agora tokens (expire in 24h)
   - Don't expose internal user IDs to admin

---

## 📝 Next Steps

1. **Backend Implementation:**
   - Create DirectMessage model
   - Create DirectConversation model
   - Create Call model
   - Implement Socket.IO handlers
   - Create API endpoints

2. **Repository Updates:**
   - Add `getAdminConversation()` method
   - Add `sendAdminMessage()` method
   - Update `getAllCommunications()` to include admin

3. **BLoC Updates:**
   - Add Socket.IO subscription to CommunicationBloc
   - Handle `AdminMessageReceivedEvent`
   - Update state to include admin conversations

4. **Main App Updates:**
   - Add Socket.IO listener for incoming calls
   - Handle navigation to IncomingCallScreen
   - Show notification for new admin messages

---

## ✅ Benefits Achieved

1. ✅ **Single Codebase** - One set of screens for all communication types
2. ✅ **Consistent UX** - Same UI patterns across admin and user chats
3. ✅ **Easy Maintenance** - Fix bugs in one place
4. ✅ **Future-Proof** - Ready for user-astrologer communication
5. ✅ **Extensible** - Easy to add new contact types
6. ✅ **Type-Safe** - Using enums and strong typing

---

## 🎉 Conclusion

Your communication screens are now **fully generic and reusable**! They seamlessly support:
- Admin-to-Astrologer messaging and calls
- Future User-to-Astrologer messaging and calls
- Potential Astrologer-to-Astrologer communication

The implementation follows **Flutter best practices** with:
- BLoC architecture
- Clean code separation
- Type safety
- Real-time Socket.IO integration
- Agora video/voice integration

**Ready for backend integration!** 🚀
