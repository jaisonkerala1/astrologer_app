# 🔄 Migration Guide - Understanding the New BLoC Architecture

## 📋 For Development Team

This guide helps you understand the changes made in Phase 1 and how to work with the new architecture.

---

## 🎯 What Changed?

### Before Phase 1 ❌
```dart
// BLoCs called services directly
class MyBloc {
  final ApiService _api = ApiService();  // ❌ Direct instantiation
  final StorageService _storage = StorageService();
  
  Future<void> loadData() async {
    final response = await _api.get('/data');  // ❌ Direct API call
    // Process data...
  }
}
```

**Problems:**
- Hard to test (can't mock services)
- Tight coupling
- Mixed concerns (API logic in BLoC)
- Can't swap implementations

### After Phase 1 ✅
```dart
// BLoCs use repositories through dependency injection
class MyBloc {
  final MyRepository repository;  // ✅ Injected dependency
  
  MyBloc({required this.repository});  // ✅ Constructor injection
  
  Future<void> loadData() async {
    final data = await repository.getData();  // ✅ Clean repository call
    // Process data...
  }
}

// Repository handles API calls
class MyRepositoryImpl implements MyRepository {
  final ApiService apiService;
  
  @override
  Future<List<Data>> getData() async {
    final response = await apiService.get('/data');
    return response.data.map((json) => Data.fromJson(json)).toList();
  }
}
```

**Benefits:**
- Easy to test (can mock repository)
- Loose coupling
- Clear separation of concerns
- Easy to swap implementations

---

## 📚 Key Concepts

### 1. Repository Pattern

**What it is:** A pattern that abstracts data sources and provides a clean API to the business logic layer.

**Structure:**
```dart
// 1. Interface (contract)
abstract class MyRepository {
  Future<List<Data>> getData();
}

// 2. Implementation (concrete)
class MyRepositoryImpl implements MyRepository {
  final ApiService apiService;
  final StorageService storageService;
  
  MyRepositoryImpl({required this.apiService, required this.storageService});
  
  @override
  Future<List<Data>> getData() async {
    // 1. Try cache first
    final cached = await storageService.getCachedData();
    if (cached != null) return cached;
    
    // 2. Fetch from API
    final response = await apiService.get('/data');
    
    // 3. Transform data
    final data = (response.data as List)
        .map((json) => Data.fromJson(json))
        .toList();
    
    // 4. Cache for next time
    await storageService.cacheData(data);
    
    // 5. Return
    return data;
  }
}
```

### 2. Dependency Injection (DI)

**What it is:** A technique where objects receive their dependencies from external sources rather than creating them.

**Before (No DI):**
```dart
class MyBloc {
  final ApiService _api = ApiService();  // ❌ Creates its own dependency
}
```

**After (With DI):**
```dart
class MyBloc {
  final MyRepository repository;  // ✅ Receives dependency
  MyBloc({required this.repository});
}

// Usage with get_it
final bloc = MyBloc(repository: getIt<MyRepository>());
```

### 3. Service Locator (get_it)

**What it is:** A centralized registry for dependencies.

**Setup:**
```dart
// lib/core/di/service_locator.dart
final getIt = GetIt.instance;

Future<void> setupServiceLocator() async {
  // Register services (singleton - one instance)
  getIt.registerLazySingleton<ApiService>(() => ApiService());
  
  // Register repositories (singleton)
  getIt.registerLazySingleton<MyRepository>(
    () => MyRepositoryImpl(apiService: getIt<ApiService>()),
  );
  
  // Register BLoCs (factory - new instance each time)
  getIt.registerFactory<MyBloc>(
    () => MyBloc(repository: getIt<MyRepository>()),
  );
}
```

**Usage:**
```dart
// In main.dart
void main() async {
  await setupServiceLocator();  // Initialize DI
  runApp(MyApp());
}

// In app.dart
BlocProvider<MyBloc>(
  create: (context) => getIt<MyBloc>(),  // Get from DI container
  child: MyScreen(),
)
```

---

## 🗺️ Where Things Live Now

### Before Phase 1
```
lib/
├── features/
│   └── auth/
│       └── bloc/
│           └── auth_bloc.dart  # ❌ Called ApiService directly
```

### After Phase 1
```
lib/
├── core/
│   └── di/
│       └── service_locator.dart  # ✅ NEW: DI setup
├── data/
│   └── repositories/
│       └── auth/
│           ├── auth_repository.dart       # ✅ NEW: Interface
│           └── auth_repository_impl.dart  # ✅ NEW: Implementation
└── features/
    └── auth/
        └── bloc/
            └── auth_bloc.dart  # ✅ MODIFIED: Uses repository
```

---

## 🔄 How to Work with Existing Features

### Scenario 1: Adding a New Method to Existing Repository

**Example:** Add "getRecentData" to DashboardRepository

**Step 1:** Update interface
```dart
// lib/data/repositories/dashboard/dashboard_repository.dart
abstract class DashboardRepository {
  Future<DashboardStatsModel> getDashboardStats();
  Future<bool> updateOnlineStatus(bool isOnline);
  Future<List<Data>> getRecentData();  // ✅ NEW
}
```

**Step 2:** Implement method
```dart
// lib/data/repositories/dashboard/dashboard_repository_impl.dart
class DashboardRepositoryImpl implements DashboardRepository {
  // ... existing code ...
  
  @override
  Future<List<Data>> getRecentData() async {
    final response = await apiService.get('/dashboard/recent');
    return (response.data as List)
        .map((json) => Data.fromJson(json))
        .toList();
  }
}
```

**Step 3:** Use in BLoC
```dart
// lib/features/dashboard/bloc/dashboard_bloc.dart
Future<void> _onLoadRecentData(LoadRecentDataEvent event, Emitter<DashboardState> emit) async {
  emit(DashboardLoading());
  try {
    final data = await repository.getRecentData();  // ✅ Use new method
    emit(RecentDataLoadedState(data));
  } catch (e) {
    emit(DashboardErrorState(e.toString()));
  }
}
```

### Scenario 2: Modifying Existing BLoC

**Before Making Changes:**
1. ✅ Check if repository has the method you need
2. ✅ If not, add to repository first
3. ✅ Then update BLoC

**Example:**
```dart
// ❌ DON'T do this in BLoC
Future<void> _onEvent(Event event, Emitter<State> emit) async {
  final response = await apiService.get('/data');  // ❌ Direct API call
}

// ✅ DO this
Future<void> _onEvent(Event event, Emitter<State> emit) async {
  final data = await repository.getData();  // ✅ Use repository
}
```

---

## 🆕 How to Add New Features

### Complete Example: Adding a "Notifications" Feature

**Step 1: Create Models**
```dart
// lib/features/notifications/models/notification_model.dart
class NotificationModel {
  final String id;
  final String title;
  final String message;
  
  NotificationModel({required this.id, required this.title, required this.message});
  
  factory NotificationModel.fromJson(Map<String, dynamic> json) => NotificationModel(
    id: json['id'],
    title: json['title'],
    message: json['message'],
  );
  
  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'message': message,
  };
}
```

**Step 2: Create Repository Interface**
```dart
// lib/data/repositories/notifications/notifications_repository.dart
abstract class NotificationsRepository {
  Future<List<NotificationModel>> getNotifications();
  Future<void> markAsRead(String id);
  Future<void> deleteNotification(String id);
}
```

**Step 3: Implement Repository**
```dart
// lib/data/repositories/notifications/notifications_repository_impl.dart
class NotificationsRepositoryImpl implements NotificationsRepository {
  final ApiService apiService;
  final StorageService storageService;
  
  NotificationsRepositoryImpl({
    required this.apiService,
    required this.storageService,
  });
  
  @override
  Future<List<NotificationModel>> getNotifications() async {
    try {
      // Try cache first
      final cached = await _getCachedNotifications();
      if (cached != null) return cached;
      
      // Fetch from API
      final response = await apiService.get('/notifications');
      final notifications = (response.data as List)
          .map((json) => NotificationModel.fromJson(json))
          .toList();
      
      // Cache for offline
      await _cacheNotifications(notifications);
      
      return notifications;
    } catch (e) {
      throw Exception('Failed to fetch notifications: $e');
    }
  }
  
  @override
  Future<void> markAsRead(String id) async {
    await apiService.patch('/notifications/$id', data: {'read': true});
  }
  
  @override
  Future<void> deleteNotification(String id) async {
    await apiService.delete('/notifications/$id');
  }
  
  // Private cache methods
  Future<List<NotificationModel>?> _getCachedNotifications() async {
    // Implement caching logic
  }
  
  Future<void> _cacheNotifications(List<NotificationModel> notifications) async {
    // Implement caching logic
  }
}
```

**Step 4: Create Events & States**
```dart
// lib/features/notifications/bloc/notifications_event.dart
abstract class NotificationsEvent {}

class LoadNotificationsEvent extends NotificationsEvent {}
class MarkAsReadEvent extends NotificationsEvent {
  final String id;
  MarkAsReadEvent(this.id);
}
class DeleteNotificationEvent extends NotificationsEvent {
  final String id;
  DeleteNotificationEvent(this.id);
}

// lib/features/notifications/bloc/notifications_state.dart
abstract class NotificationsState {}

class NotificationsInitial extends NotificationsState {}
class NotificationsLoading extends NotificationsState {}
class NotificationsLoadedState extends NotificationsState {
  final List<NotificationModel> notifications;
  NotificationsLoadedState(this.notifications);
}
class NotificationsErrorState extends NotificationsState {
  final String message;
  NotificationsErrorState(this.message);
}
```

**Step 5: Create BLoC**
```dart
// lib/features/notifications/bloc/notifications_bloc.dart
class NotificationsBloc extends Bloc<NotificationsEvent, NotificationsState> {
  final NotificationsRepository repository;
  
  NotificationsBloc({required this.repository}) : super(NotificationsInitial()) {
    on<LoadNotificationsEvent>(_onLoadNotifications);
    on<MarkAsReadEvent>(_onMarkAsRead);
    on<DeleteNotificationEvent>(_onDeleteNotification);
  }
  
  Future<void> _onLoadNotifications(
    LoadNotificationsEvent event,
    Emitter<NotificationsState> emit,
  ) async {
    emit(NotificationsLoading());
    try {
      final notifications = await repository.getNotifications();
      emit(NotificationsLoadedState(notifications));
    } catch (e) {
      emit(NotificationsErrorState(e.toString()));
    }
  }
  
  Future<void> _onMarkAsRead(
    MarkAsReadEvent event,
    Emitter<NotificationsState> emit,
  ) async {
    try {
      await repository.markAsRead(event.id);
      add(LoadNotificationsEvent());  // Reload
    } catch (e) {
      emit(NotificationsErrorState(e.toString()));
    }
  }
  
  Future<void> _onDeleteNotification(
    DeleteNotificationEvent event,
    Emitter<NotificationsState> emit,
  ) async {
    try {
      await repository.deleteNotification(event.id);
      add(LoadNotificationsEvent());  // Reload
    } catch (e) {
      emit(NotificationsErrorState(e.toString()));
    }
  }
}
```

**Step 6: Register in DI**
```dart
// lib/core/di/service_locator.dart
Future<void> setupServiceLocator() async {
  // ... existing registrations ...
  
  // Register Notifications Repository
  getIt.registerLazySingleton<NotificationsRepository>(
    () => NotificationsRepositoryImpl(
      apiService: getIt<ApiService>(),
      storageService: getIt<StorageService>(),
    ),
  );
  
  // Register Notifications BLoC
  getIt.registerFactory<NotificationsBloc>(
    () => NotificationsBloc(repository: getIt<NotificationsRepository>()),
  );
}
```

**Step 7: Update App Providers**
```dart
// lib/app/app.dart
MultiBlocProvider(
  providers: [
    // ... existing BLoCs ...
    BlocProvider<NotificationsBloc>(
      create: (context) => getIt<NotificationsBloc>(),
    ),
  ],
  child: MyApp(),
)
```

**Step 8: Create UI**
```dart
// lib/features/notifications/screens/notifications_screen.dart
class NotificationsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Notifications')),
      body: BlocBuilder<NotificationsBloc, NotificationsState>(
        builder: (context, state) {
          if (state is NotificationsLoading) {
            return CircularProgressIndicator();
          } else if (state is NotificationsLoadedState) {
            return ListView.builder(
              itemCount: state.notifications.length,
              itemBuilder: (context, index) {
                final notification = state.notifications[index];
                return ListTile(
                  title: Text(notification.title),
                  subtitle: Text(notification.message),
                  trailing: IconButton(
                    icon: Icon(Icons.delete),
                    onPressed: () {
                      context.read<NotificationsBloc>().add(
                        DeleteNotificationEvent(notification.id),
                      );
                    },
                  ),
                );
              },
            );
          } else if (state is NotificationsErrorState) {
            return Text('Error: ${state.message}');
          }
          return Container();
        },
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.refresh),
        onPressed: () {
          context.read<NotificationsBloc>().add(LoadNotificationsEvent());
        },
      ),
    );
  }
}
```

---

## ✅ Best Practices Checklist

When working with the new architecture:

### For BLoCs
- [ ] BLoC only has business logic
- [ ] BLoC uses repository (not ApiService/StorageService directly)
- [ ] BLoC receives repository through constructor
- [ ] BLoC handles errors gracefully
- [ ] BLoC emits appropriate states

### For Repositories
- [ ] Repository has interface + implementation
- [ ] Repository handles API calls
- [ ] Repository handles caching
- [ ] Repository transforms data to models
- [ ] Repository has proper error handling

### For Dependency Injection
- [ ] Services registered as lazy singletons
- [ ] Repositories registered as lazy singletons
- [ ] BLoCs registered as factories
- [ ] All dependencies in service_locator.dart
- [ ] BLoCs use getIt in providers

---

## 🐛 Common Mistakes & Fixes

### Mistake 1: Direct API Call in BLoC ❌
```dart
// ❌ Wrong
class MyBloc {
  final ApiService _api = ApiService();
  
  Future<void> loadData() async {
    final response = await _api.get('/data');
  }
}
```

**Fix:** Use repository ✅
```dart
// ✅ Correct
class MyBloc {
  final MyRepository repository;
  MyBloc({required this.repository});
  
  Future<void> loadData() async {
    final data = await repository.getData();
  }
}
```

### Mistake 2: Direct Instantiation ❌
```dart
// ❌ Wrong
BlocProvider<MyBloc>(
  create: (context) => MyBloc(repository: MyRepositoryImpl(...)),
)
```

**Fix:** Use service locator ✅
```dart
// ✅ Correct
BlocProvider<MyBloc>(
  create: (context) => getIt<MyBloc>(),
)
```

### Mistake 3: Concrete Repository in BLoC ❌
```dart
// ❌ Wrong
class MyBloc {
  final MyRepositoryImpl repository;  // Concrete class
}
```

**Fix:** Use interface ✅
```dart
// ✅ Correct
class MyBloc {
  final MyRepository repository;  // Abstract interface
}
```

---

## 📚 Additional Resources

- **[Architecture Documentation](ARCHITECTURE_DOCUMENTATION.md)** - Full architecture guide
- **[Testing Guide](TESTING_GUIDE.md)** - How to test everything
- **[Code Review](PHASE_1_CODE_REVIEW.md)** - Quality assessment
- **[BLoC Pattern Guide](https://bloclibrary.dev/)** - Official BLoC docs
- **[get_it Package](https://pub.dev/packages/get_it)** - DI package docs

---

## 🆘 Need Help?

### Questions to Ask Yourself:
1. **"Where should this logic go?"**
   - API call? → Repository
   - Business logic? → BLoC
   - UI logic? → Widget

2. **"How do I test this?"**
   - If hard to test, probably wrong layer

3. **"Can I mock this dependency?"**
   - No? Use dependency injection

### Getting Unstuck:
1. Look at existing features (Auth, Dashboard, Profile)
2. Follow the same pattern
3. Check documentation
4. Ask team members

---

## ✅ Summary

**Remember:**
1. **BLoCs** = Business logic only
2. **Repositories** = Data operations only
3. **Services** = Infrastructure only
4. **DI** = Inject all dependencies
5. **Interface** = Always create abstract class first

**The Golden Rule:**
> "If you can't easily write a test for it, you're probably in the wrong layer."

---

**Last Updated:** October 26, 2024  
**Version:** 1.0 (Phase 1)  
**Status:** ✅ Complete

**Happy Coding!** 🚀


