# Phase 5: Provider Cleanup Plan

## 🎯 Goal
Clean up unnecessary Provider usage and keep only essential UI services (Theme & Language).

## 📊 Current Analysis

### Services to KEEP (UI Preferences):
1. ✅ **LanguageService** - Language/locale management (essential for UI)
2. ✅ **ThemeService** - Theme management (essential for UI)

### Services to REMOVE (Replaced by BLoCs):
1. ❌ **StatusService** - 0 usages, can be removed
2. ❌ **NotificationService** - 7 usages in 2 files, replaced by `NotificationsBloc`
3. ❌ **LiveStreamService** - 0 usages, can be removed
4. ❌ **CommunicationService** - 2 usages in 2 files, replaced by `CommunicationBloc`

---

## 🔧 Refactoring Steps

### Step 1: Remove Unused Services (No Dependencies)
- [x] Remove `StatusService` from `MultiProvider`
- [x] Remove `LiveStreamService` from `MultiProvider`

### Step 2: Refactor NotificationService Usage
Files to update:
- `lib/features/notifications/screens/notifications_screen.dart` (4 usages)
- `lib/features/notifications/screens/notification_detail_screen.dart` (3 usages)

**Action:** Replace with `BlocBuilder<NotificationsBloc, NotificationsState>`

### Step 3: Refactor CommunicationService Usage
Files to update:
- `lib/features/dashboard/screens/dashboard_screen.dart` (1 usage)
- `lib/features/communication/screens/unified_communication_screen.dart` (1 usage)

**Action:** Replace with `BlocBuilder<CommunicationBloc, CommunicationState>`

### Step 4: Remove Service Provider Declarations
- [x] Remove `StatusService` from `main.dart` initialization
- [x] Remove `NotificationService` provider after refactoring screens
- [x] Remove `LiveStreamService` provider
- [x] Remove `CommunicationService` provider after refactoring screens

### Step 5: Final Cleanup
- [x] Remove unused service files (optional, can keep for reference)
- [x] Update `app.dart` to only include `LanguageService` and `ThemeService`
- [x] Verify build success

---

## ✅ Expected Result

**Final `MultiProvider` will only contain:**
```dart
MultiProvider(
  providers: [
    ChangeNotifierProvider<LanguageService>(
      create: (context) => widget.languageService,
    ),
    ChangeNotifierProvider<ThemeService>(
      create: (context) => widget.themeService,
    ),
  ],
  child: MultiBlocProvider(...),
)
```

---

## 📝 Benefits

1. ✅ **Cleaner Architecture** - Clear separation between UI services and business logic
2. ✅ **Better State Management** - All business logic in BLoCs
3. ✅ **Easier Testing** - BLoCs are easier to test than ChangeNotifiers
4. ✅ **Consistent Pattern** - All features use BLoC pattern
5. ✅ **Better Performance** - Fewer providers to rebuild

---

## ⚠️ Notes

- `LanguageService` and `ThemeService` remain as Providers because they are UI-level concerns
- All business logic (notifications, communication, live streaming, status) now uses BLoC
- Old service files can be kept for reference or completely removed


