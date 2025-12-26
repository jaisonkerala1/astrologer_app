# 🔋 Professional Reusable Wakelock Implementation

**Date:** December 25, 2025  
**Feature:** Screen wake management for live streaming and video calls

## ✅ Implementation Complete

A professional, reusable wakelock solution has been implemented following BLoC architecture best practices.

---

## 📦 What Was Created

### 1. **Core Service Layer**
- **`lib/core/services/wakelock_service.dart`**
  - Singleton service for wakelock management
  - Session tracking (supports multiple concurrent sessions)
  - Safe enable/disable with error handling
  - Force disable for emergency cleanup

### 2. **BLoC Layer (Reusable)**
- **`lib/core/bloc/wakelock/wakelock_event.dart`**
  - `EnableWakelockEvent` - Enable screen wake
  - `DisableWakelockEvent` - Disable screen wake
  - `ForceDisableWakelockEvent` - Emergency disable
  - `AppPausedEvent` - Handle app background
  - `AppResumedEvent` - Handle app foreground

- **`lib/core/bloc/wakelock/wakelock_state.dart`**
  - `WakelockInitial` - Initial state
  - `WakelockEnabled` - Screen awake (with session count)
  - `WakelockDisabled` - Screen can sleep
  - `WakelockPaused` - Temporarily disabled (app backgrounded)
  - `WakelockError` - Error state

- **`lib/core/bloc/wakelock/wakelock_bloc.dart`**
  - Reusable BLoC for wakelock management
  - Handles app lifecycle events
  - Automatic cleanup on dispose
  - Error handling and logging

### 3. **Dependency Injection**
- **`lib/core/di/service_locator.dart`**
  - Registered `WakelockBloc` as singleton
  - Shared across all screens
  - Accessible via `getIt<WakelockBloc>()`

### 4. **Integration**
- **`lib/features/live/screens/live_streaming_screen.dart`**
  - Enable wakelock on stream start
  - Disable wakelock on stream end
  - Handle app lifecycle (pause/resume)

- **`lib/features/live/screens/live_stream_viewer_screen.dart`**
  - Enable wakelock when viewing stream
  - Disable wakelock when leaving
  - Handle app lifecycle (pause/resume)

### 5. **Package Dependency**
- **`pubspec.yaml`**
  - Added `wakelock_plus: ^1.2.1`

---

## 🏗️ Architecture

```
┌─────────────────────────────────────────┐
│         UI Layer (Screens)              │
│  - LiveStreamingScreen                  │
│  - LiveStreamViewerScreen               │
└──────────────┬──────────────────────────┘
               │ Events/States
               ↓
┌─────────────────────────────────────────┐
│         BLoC Layer                      │
│  - WakelockBloc (Singleton)            │
│    • EnableWakelockEvent               │
│    • DisableWakelockEvent              │
│    • AppPausedEvent                    │
│    • AppResumedEvent                   │
└──────────────┬──────────────────────────┘
               │ Service Calls
               ↓
┌─────────────────────────────────────────┐
│      Service Layer                      │
│  - WakelockService (Singleton)         │
│    • enable()                          │
│    • disable()                         │
│    • forceDisable()                    │
└──────────────┬──────────────────────────┘
               │ Package API
               ↓
┌─────────────────────────────────────────┐
│      Package Layer                      │
│  - wakelock_plus                       │
└─────────────────────────────────────────┘
```

---

## 🎯 Features

### ✅ **Reusable**
- Can be used in any screen (live streaming, video calls, etc.)
- Singleton BLoC shared across app
- Session tracking supports multiple concurrent uses

### ✅ **Professional**
- Follows BLoC architecture pattern
- Proper separation of concerns
- Error handling and logging
- App lifecycle management

### ✅ **Battery Efficient**
- Automatically pauses when app goes to background
- Re-enables when app resumes (if needed)
- Force disable for emergency cleanup

### ✅ **Safe**
- Automatic cleanup on dispose
- Session counting prevents premature disable
- Error handling prevents crashes

---

## 📝 Usage Example

### In Any Screen:

```dart
// Get wakelock BLoC
final wakelockBloc = getIt<WakelockBloc>();

// Enable wakelock
wakelockBloc.add(const EnableWakelockEvent());

// Disable wakelock
wakelockBloc.add(const DisableWakelockEvent());

// Handle app lifecycle
@override
void didChangeAppLifecycleState(AppLifecycleState state) {
  if (state == AppLifecycleState.paused) {
    wakelockBloc.add(const AppPausedEvent());
  } else if (state == AppLifecycleState.resumed) {
    wakelockBloc.add(const AppResumedEvent());
  }
}
```

---

## 🔄 How It Works

### **Live Streaming (Broadcaster)**
1. User starts live stream → `EnableWakelockEvent`
2. Screen stays awake during broadcast
3. App goes to background → `AppPausedEvent` (wakelock paused)
4. App resumes → `AppResumedEvent` (wakelock re-enabled)
5. User ends stream → `DisableWakelockEvent`

### **Live Streaming (Viewer)**
1. User joins stream → `EnableWakelockEvent`
2. Screen stays awake while watching
3. App goes to background → `AppPausedEvent` (wakelock paused)
4. App resumes → `AppResumedEvent` (wakelock re-enabled)
5. User leaves stream → `DisableWakelockEvent`

---

## 🧪 Testing

### Manual Testing:
1. ✅ Start live stream → Screen should stay awake
2. ✅ Watch live stream → Screen should stay awake
3. ✅ Press power button → Screen should turn off (wakelock paused)
4. ✅ Unlock phone → Screen should stay awake again
5. ✅ End/Leave stream → Screen can sleep normally

---

## 📊 Benefits

1. **No More Screen Timeouts** - Screen stays awake during live streaming
2. **Battery Efficient** - Automatically pauses when app backgrounded
3. **Reusable** - Can be used in video calls, long-form content, etc.
4. **Professional** - Follows industry-standard BLoC pattern
5. **Maintainable** - Clean separation of concerns
6. **Safe** - Automatic cleanup and error handling

---

## 🚀 Next Steps (Optional Enhancements)

- [ ] Add wakelock toggle in settings
- [ ] Add wakelock indicator in UI
- [ ] Integrate with video call screens
- [ ] Add analytics for wakelock usage
- [ ] Add unit tests for WakelockBloc

---

## 📚 Files Modified/Created

### Created:
- ✅ `lib/core/services/wakelock_service.dart`
- ✅ `lib/core/bloc/wakelock/wakelock_event.dart`
- ✅ `lib/core/bloc/wakelock/wakelock_state.dart`
- ✅ `lib/core/bloc/wakelock/wakelock_bloc.dart`

### Modified:
- ✅ `pubspec.yaml` - Added wakelock_plus package
- ✅ `lib/core/di/service_locator.dart` - Registered WakelockBloc
- ✅ `lib/features/live/screens/live_streaming_screen.dart` - Integrated wakelock
- ✅ `lib/features/live/screens/live_stream_viewer_screen.dart` - Integrated wakelock

---

**Status:** ✅ Complete and Ready for Testing  
**Architecture:** BLoC Pattern  
**Reusability:** High (can be used in any screen)  
**Battery Impact:** Optimized (pauses on background)

