# 📱 Communication Screens - Usage Examples

## 🎯 Complete Implementation Examples

---

## Example 1: Communication Screen Integration

### Update `communication_screen.dart` to handle admin messages:

```dart
// In your communication item card onTap handler:

onTap: () {
  final item = state.filteredCommunications[index];
  
  // Determine navigation based on type and contactType
  if (item.type == CommunicationType.message) {
    // Navigate to chat
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          contactId: item.contactId,
          contactName: item.contactName,
          contactType: item.contactType,
          conversationId: item.conversationId,
          avatarUrl: item.avatar.isNotEmpty ? item.avatar : null,
        ),
      ),
    ).then((_) {
      // Refresh when coming back
      context.read<CommunicationBloc>().add(
        const RefreshCommunicationsEvent(),
      );
    });
  } else if (item.type == CommunicationType.videoCall) {
    // Handle call history tap (show details or re-call)
    _showCallOptions(context, item);
  }
}
```

---

## Example 2: Socket.IO Listener Setup

### In your `main.dart` or app-level widget:

```dart
class _AppState extends State<App> {
  late final SocketService _socketService;
  StreamSubscription? _messageSubscription;
  StreamSubscription? _callSubscription;

  @override
  void initState() {
    super.initState();
    _socketService = getIt<SocketService>();
    _setupSocketListeners();
  }

  void _setupSocketListeners() {
    // Listen for incoming messages
    _messageSubscription = _socketService.on('dm:message_received').listen((data) {
      print('📩 New message: ${data['content']}');
      
      // Show notification
      _showMessageNotification(
        senderName: data['senderType'] == 'admin' 
            ? 'Admin Support' 
            : data['senderName'],
        message: data['content'],
        contactType: ContactTypeExtension.fromString(data['senderType']),
      );
      
      // Update communication bloc
      context.read<CommunicationBloc>().add(
        const RefreshCommunicationsEvent(),
      );
    });

    // Listen for incoming calls
    _callSubscription = _socketService.on('call:incoming').listen((data) {
      print('📞 Incoming call from: ${data['callerName']}');
      
      // Navigate to incoming call screen
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => IncomingCallScreen(
            callId: data['callId'],
            contactId: data['callerId'],
            contactName: data['callerType'] == 'admin'
                ? 'Admin Support'
                : data['callerName'],
            contactType: ContactTypeExtension.fromString(data['callerType']),
            phoneNumber: data['callerPhone'] ?? '+1234567890',
            callType: data['callType'],
            agoraToken: data['agoraToken'],
            channelName: data['channelName'],
            avatarUrl: data['callerAvatar'],
          ),
        ),
      );
    });
  }

  void _showMessageNotification({
    required String senderName,
    required String message,
    required ContactType contactType,
  }) {
    // Show in-app notification or system notification
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            if (contactType == ContactType.admin)
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.support_agent,
                  color: Colors.white,
                  size: 20,
                ),
              )
            else
              const CircleAvatar(
                child: Icon(Icons.person),
              ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    senderName,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    message,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        action: SnackBarAction(
          label: 'Reply',
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ChatScreen(
                  contactId: contactType == ContactType.admin ? 'admin' : '',
                  contactName: senderName,
                  contactType: contactType,
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  void dispose() {
    _messageSubscription?.cancel();
    _callSubscription?.cancel();
    super.dispose();
  }
}
```

---

## Example 3: Communication Repository Implementation

### Add to `communication_repository_impl.dart`:

```dart
class CommunicationRepositoryImpl implements CommunicationRepository {
  final ApiService _apiService;
  final SocketService _socketService;
  final StorageService _storageService;

  // ... existing code ...

  @override
  Future<List<CommunicationItem>> getAllCommunications({int page = 1}) async {
    try {
      final items = <CommunicationItem>[];

      // 1. Get admin conversation if exists
      try {
        final adminConvo = await getAdminConversation();
        if (adminConvo != null) {
          items.add(adminConvo);
        }
      } catch (e) {
        print('No admin conversation: $e');
      }

      // 2. Get user conversations
      final response = await _apiService.get('/api/conversations', 
        queryParameters: {'page': page, 'limit': 20});
      
      if (response['success'] == true) {
        final conversations = (response['data'] as List?)
            ?.map((conv) => CommunicationItem.fromJson(conv))
            .toList() ?? [];
        
        items.addAll(conversations);
      }

      // 3. Get call history
      final callResponse = await _apiService.get('/api/calls/history');
      if (callResponse['success'] == true) {
        final calls = (callResponse['data'] as List?)
            ?.map((call) => CommunicationItem.fromJson(call))
            .toList() ?? [];
        
        items.addAll(calls);
      }

      // Sort by timestamp
      items.sort((a, b) => b.timestamp.compareTo(a.timestamp));

      // Cache for instant load
      await _cacheItems(items);

      return items;
    } catch (e) {
      print('Error loading communications: $e');
      throw Exception('Failed to load communications');
    }
  }

  @override
  Future<CommunicationItem?> getAdminConversation() async {
    try {
      final response = await _apiService.get('/api/conversations/admin');
      
      if (response['success'] == true && response['data'] != null) {
        final data = response['data'];
        
        return CommunicationItem(
          id: 'admin_conversation',
          type: CommunicationType.message,
          contactName: 'Admin Support',
          contactId: 'admin',
          contactType: ContactType.admin,
          avatar: '',
          timestamp: data['lastMessageAt'] != null
              ? DateTime.parse(data['lastMessageAt'])
              : DateTime.now(),
          preview: data['lastMessage'] ?? 'No messages yet',
          unreadCount: data['unreadCount'] ?? 0,
          isOnline: true,
          status: CommunicationStatus.received,
          conversationId: data['_id'] ?? data['id'],
        );
      }
      
      return null;
    } catch (e) {
      print('Error getting admin conversation: $e');
      return null;
    }
  }

  @override
  Future<void> sendAdminMessage(String message) async {
    try {
      // Send via API
      await _apiService.post('/api/conversations/admin/messages', {
        'content': message,
        'messageType': 'text',
      });

      // Also send via Socket.IO for real-time
      _socketService.emit('dm:send_message', {
        'conversationId': 'admin_conversation',
        'recipientType': 'admin',
        'content': message,
        'messageType': 'text',
      });
    } catch (e) {
      throw Exception('Failed to send message: $e');
    }
  }
}
```

---

## Example 4: Communication BLoC Update

### Add to `communication_bloc.dart`:

```dart
class CommunicationBloc extends Bloc<CommunicationEvent, CommunicationState> {
  final CommunicationRepository repository;
  final SocketService socketService;
  
  StreamSubscription? _socketSubscription;

  CommunicationBloc({
    required this.repository,
    required this.socketService,
  }) : super(const CommunicationInitial()) {
    // ... existing handlers ...
    
    on<AdminMessageReceivedEvent>(_onAdminMessageReceived);
    
    // Listen to socket events
    _setupSocketListener();
  }

  void _setupSocketListener() {
    _socketSubscription = socketService.on('dm:message_received').listen((data) {
      // Only handle if it's from admin
      if (data['senderType'] == 'admin') {
        add(AdminMessageReceivedEvent(
          message: data['content'],
          timestamp: DateTime.parse(data['timestamp']),
        ));
      }
    });
  }

  Future<void> _onAdminMessageReceived(
    AdminMessageReceivedEvent event,
    Emitter<CommunicationState> emit,
  ) async {
    if (state is CommunicationLoadedState) {
      final currentState = state as CommunicationLoadedState;
      
      // Find admin conversation and update it
      final updatedItems = currentState.allCommunications.map((item) {
        if (item.contactType == ContactType.admin) {
          return CommunicationItem(
            id: item.id,
            type: item.type,
            contactName: item.contactName,
            contactId: item.contactId,
            contactType: item.contactType,
            avatar: item.avatar,
            timestamp: event.timestamp,
            preview: event.message,
            unreadCount: item.unreadCount + 1,
            isOnline: item.isOnline,
            status: item.status,
            conversationId: item.conversationId,
          );
        }
        return item;
      }).toList();

      // Sort by timestamp
      updatedItems.sort((a, b) => b.timestamp.compareTo(a.timestamp));

      emit(currentState.copyWith(
        allCommunications: updatedItems,
        unreadMessagesCount: currentState.unreadMessagesCount + 1,
      ));
    }
  }

  @override
  Future<void> close() {
    _socketSubscription?.cancel();
    return super.close();
  }
}

// New event
class AdminMessageReceivedEvent extends CommunicationEvent {
  final String message;
  final DateTime timestamp;

  const AdminMessageReceivedEvent({
    required this.message,
    required this.timestamp,
  });

  @override
  List<Object?> get props => [message, timestamp];
}
```

---

## Example 5: Service Locator Setup

### Update `service_locator.dart`:

```dart
void setupServiceLocator() {
  // ... existing services ...

  // Socket.IO Service
  getIt.registerLazySingleton<SocketService>(() => SocketService());

  // API Service
  getIt.registerLazySingleton<ApiService>(() => ApiService());

  // Storage Service
  getIt.registerLazySingleton<StorageService>(() => StorageService());

  // Communication Repository
  getIt.registerLazySingleton<CommunicationRepository>(
    () => CommunicationRepositoryImpl(
      apiService: getIt<ApiService>(),
      socketService: getIt<SocketService>(),
      storageService: getIt<StorageService>(),
    ),
  );

  // Communication BLoC
  getIt.registerFactory<CommunicationBloc>(
    () => CommunicationBloc(
      repository: getIt<CommunicationRepository>(),
      socketService: getIt<SocketService>(),
    ),
  );
}
```

---

## Example 6: Testing

### Widget Test for ChatScreen:

```dart
testWidgets('ChatScreen shows admin badge for admin contacts', (tester) async {
  await tester.pumpWidget(
    MaterialApp(
      home: ChatScreen(
        contactId: 'admin',
        contactName: 'Admin Support',
        contactType: ContactType.admin,
      ),
    ),
  );

  await tester.pumpAndSettle();

  // Should show admin icon
  expect(find.byIcon(Icons.support_agent), findsOneWidget);

  // Should show "Support Team" badge
  expect(find.text('Support Team'), findsOneWidget);

  // Should NOT show call buttons
  expect(find.byIcon(Icons.phone_rounded), findsNothing);
  expect(find.byIcon(Icons.videocam_rounded), findsNothing);
});

testWidgets('ChatScreen shows call buttons for user contacts', (tester) async {
  await tester.pumpWidget(
    MaterialApp(
      home: ChatScreen(
        contactId: 'user123',
        contactName: 'John Doe',
        contactType: ContactType.user,
      ),
    ),
  );

  await tester.pumpAndSettle();

  // Should show call buttons
  expect(find.byIcon(Icons.phone_rounded), findsOneWidget);
  expect(find.byIcon(Icons.videocam_rounded), findsOneWidget);

  // Should NOT show admin badge
  expect(find.text('Support Team'), findsNothing);
});
```

---

## 🎉 Summary

These examples show complete integration of the refactored communication screens:

1. ✅ **Screen Navigation** - How to navigate with correct parameters
2. ✅ **Socket.IO Integration** - Real-time message and call handling
3. ✅ **Repository Implementation** - Data fetching and caching
4. ✅ **BLoC Updates** - State management for admin messages
5. ✅ **Service Setup** - Dependency injection configuration
6. ✅ **Testing** - Widget tests for different contact types

Copy these examples and adapt them to your specific needs! 🚀
