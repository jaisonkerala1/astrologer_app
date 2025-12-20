# FCM BLoC Architecture - Professional Implementation

## ✅ Proper BLoC Architecture

This implementation follows **industry-standard Flutter BLoC patterns** and is **100% reusable** for both Astrologer and Customer apps.

---

## 📦 Layer Separation

```
┌─────────────────────────────────────────┐
│           UI Layer (Widgets)            │
│  - BlocListener<FcmBloc>               │
│  - Shows IncomingCallScreen            │
└──────────────┬──────────────────────────┘
               │ States
               ▼
┌─────────────────────────────────────────┐
│         BLoC Layer (Business Logic)     │
│  - FcmBloc (FCM notifications)         │
│  - CallBloc (Call management)          │
│  - Events → BLoC → States              │
└──────────────┬──────────────────────────┘
               │ Method calls
               ▼
┌─────────────────────────────────────────┐
│      Service Layer (Infrastructure)     │
│  - FcmService (Firebase SDK)           │
│  - SocketService (Socket.IO)           │
└─────────────────────────────────────────┘
```

---

## 📁 File Structure

```
lib/
├── core/
│   ├── fcm/
│   │   ├── fcm_event.dart       # FCM events (input to BLoC)
│   │   ├── fcm_state.dart       # FCM states (output from BLoC)
│   │   └── fcm_bloc.dart        # FCM BLoC (business logic)
│   ├── services/
│   │   ├── fcm_service.dart     # Low-level Firebase operations
│   │   └── socket_service.dart  # Socket.IO (foreground only)
│   └── di/
│       └── service_locator.dart # Dependency injection
└── features/
    └── communication/
        └── bloc/
            ├── call_bloc.dart   # Call BLoC listens to FcmBloc
            └── ...
```

---

## 🔄 How It Works

### 1. **FcmService** (Low-level)
```dart
// ONLY handles Firebase SDK operations
class FcmService {
  // Exposes streams (no business logic)
  Stream<Map<String, dynamic>> get callStream;
  Stream<Map<String, dynamic>> get videoCallStream;
  Stream<Map<String, dynamic>> get messageStream;
  
  Future<void> initialize();
}
```

### 2. **FcmBloc** (Business logic)
```dart
// Converts service streams into proper BLoC events/states
class FcmBloc extends Bloc<FcmEvent, FcmState> {
  // Subscribes to FcmService streams
  // Emits typed states (FcmIncomingCallNotification, etc.)
  
  on<InitializeFcmEvent>(...);
  on<FcmNotificationReceivedEvent>(...);
}
```

### 3. **App.dart** (UI integration)
```dart
// Provides FcmBloc globally
BlocProvider<FcmBloc>(
  create: (_) => getIt<FcmBloc>()..add(InitializeFcmEvent()),
  child: BlocListener<FcmBloc, FcmState>(
    listener: (context, state) {
      if (state is FcmIncomingCallNotification) {
        // Show incoming call screen
        // CallBloc will handle the call logic
      }
    },
    child: MaterialApp(...),
  ),
)
```

---

## 🎯 Integration Steps

### Step 1: Add to `app.dart`

```dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/fcm/fcm_bloc.dart';
import 'core/fcm/fcm_event.dart';
import 'core/fcm/fcm_state.dart';
import 'core/di/service_locator.dart';

class _AstrologerAppState extends State<AstrologerApp> {
  late final FcmBloc _fcmBloc;
  late final CallBloc _callBloc;

  @override
  void initState() {
    super.initState();
    // Eagerly initialize singletons
    _fcmBloc = getIt<FcmBloc>()..add(const InitializeFcmEvent());
    _callBloc = getIt<CallBloc>();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: _fcmBloc),
        BlocProvider.value(value: _callBloc),
        // ... other BLoCs
      ],
      child: MaterialApp(
        navigatorKey: _rootNavigatorKey,
        builder: (context, child) {
          return MultiBlocListener(
            listeners: [
              // Listen to FCM notifications
              BlocListener<FcmBloc, FcmState>(
                listener: (context, state) {
                  if (state is FcmIncomingCallNotification) {
                    // Incoming call from FCM (background/locked)
                    _callBloc.add(IncomingCallEvent(
                      callId: state.callData['callId'],
                      callerId: state.callData['callerId'],
                      callerName: state.callData['callerName'],
                      callerType: state.callData['callerType'],
                      callType: state.isVideo ? 'video' : 'voice',
                      channelName: state.callData['channelName'],
                      token: state.callData['agoraToken'],
                      agoraAppId: state.callData['agoraAppId'],
                    ));
                  }
                },
              ),
              
              // Listen to CallBloc (same as before)
              BlocListener<CallBloc, CallState>(
                listener: (context, state) {
                  if (state is CallIncoming) {
                    _rootNavigatorKey.currentState?.push(...);
                  }
                },
              ),
            ],
            child: child ?? const SizedBox.shrink(),
          );
        },
        home: SplashScreen(),
      ),
    );
  }
}
```

### Step 2: Register FCM token after login

```dart
// In your AuthBloc or after successful login:
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final FcmBloc fcmBloc;
  
  Future<void> _onLoginSuccess(LoginSuccessEvent event, Emitter emit) async {
    // ... login logic ...
    
    // Register FCM token with backend
    fcmBloc.add(RegisterFcmTokenEvent(
      userId: user.id,
      userType: 'astrologer', // or 'customer' for customer app
    ));
  }
}
```

---

## 🏗️ Architecture Benefits

### ✅ Proper Separation of Concerns
- **FcmService**: Only Firebase operations
- **FcmBloc**: Business logic & state management
- **CallBloc**: Call-specific logic
- **UI**: Only listens to states

### ✅ Testable
```dart
// Easy to test with bloc_test package
blocTest<FcmBloc, FcmState>(
  'emits [FcmIncomingCallNotification] when call received',
  build: () => FcmBloc(mockFcmService),
  act: (bloc) => bloc.add(FcmNotificationReceivedEvent({
    'type': 'call',
    'callerId': 'admin',
  })),
  expect: () => [
    isA<FcmIncomingCallNotification>(),
  ],
);
```

### ✅ Reusable
Same code works for:
- Astrologer App (receives calls from customers/admin)
- Customer App (receives calls from astrologers)
- Just change `userType: 'customer'` in registration

### ✅ Scalable
Easy to add new notification types:
```dart
case 'payment':
  emit(FcmPaymentNotification(...));
case 'booking':
  emit(FcmBookingNotification(...));
```

---

## 🔐 Firebase Setup (Next Steps)

### 1. Create Firebase Project
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Create new project "Astrologer App"
3. Add Android app (package: `com.example.astrologer_app`)
4. Download `google-services.json` → place in `android/app/`

### 2. Update Android Configuration
```gradle
// android/build.gradle
dependencies {
    classpath 'com.google.gms:google-services:4.4.0'
}

// android/app/build.gradle
apply plugin: 'com.google.gms.google-services'
```

### 3. Update Backend
See `BACKEND_FCM_INTEGRATION.md` for backend implementation.

---

## 📊 Comparison: Before vs After

### ❌ Before (Improper)
```dart
// Direct service usage in CallBloc
class CallBloc {
  CallBloc(FcmService fcm) {
    fcm.callStream.listen((data) {
      // ❌ CallBloc depends on FCM directly
      // ❌ Hard to test
      // ❌ Couples call logic to FCM
    });
  }
}
```

### ✅ After (Proper BLoC)
```dart
// FcmBloc handles FCM, emits states
class FcmBloc extends Bloc<FcmEvent, FcmState> {
  // ✅ Clean separation
  // ✅ Testable with bloc_test
  // ✅ Reusable events/states
}

// UI listens to FcmBloc states
BlocListener<FcmBloc, FcmState>(
  listener: (context, state) {
    if (state is FcmIncomingCallNotification) {
      // ✅ UI triggers CallBloc event
      // ✅ CallBloc doesn't know about FCM
    }
  },
)
```

---

## 🎓 Summary

This implementation follows:
- ✅ **Single Responsibility Principle**: Each layer has one job
- ✅ **Dependency Inversion**: BLoCs depend on abstractions (streams), not implementations
- ✅ **Testability**: Easy to mock services and test BLoCs
- ✅ **Reusability**: Same code for Astrologer & Customer apps
- ✅ **Industry Standards**: Matches official BLoC library patterns

**This is production-ready, professional Flutter BLoC architecture!** 🚀






