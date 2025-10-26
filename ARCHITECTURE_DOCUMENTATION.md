# 🏛️ Architecture Documentation - BLoC Pattern Implementation

## 📋 Overview

This document describes the clean architecture implementation in the Astrologer App using the BLoC (Business Logic Component) pattern with repository abstraction.

---

## 🎯 Architecture Goals

1. **Separation of Concerns**: Clear boundaries between layers
2. **Testability**: Easy to test each layer independently
3. **Maintainability**: Easy to understand and modify
4. **Scalability**: Easy to add new features
5. **Reusability**: Components can be reused across features

---

## 🏗️ Architecture Layers

```
┌─────────────────────────────────────────────────────────────┐
│                      Presentation Layer                      │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐         │
│  │   Screens   │  │   Widgets   │  │   Themes    │         │
│  └─────────────┘  └─────────────┘  └─────────────┘         │
└───────────────────────────┬─────────────────────────────────┘
                            │
                            │ Events / States
                            │
┌───────────────────────────▼─────────────────────────────────┐
│                     Business Logic Layer                     │
│  ┌──────────────────────────────────────────────────────┐   │
│  │                        BLoCs                          │   │
│  │  • AuthBloc      • DashboardBloc                      │   │
│  │  • ProfileBloc   • ConsultationsBloc                  │   │
│  │  • ReviewsBloc   • CalendarBloc (planned)             │   │
│  └──────────────────────────────────────────────────────┘   │
└───────────────────────────┬─────────────────────────────────┘
                            │
                            │ Repository Calls
                            │
┌───────────────────────────▼─────────────────────────────────┐
│                       Data Layer                             │
│  ┌──────────────────────────────────────────────────────┐   │
│  │                    Repositories                       │   │
│  │  • AuthRepository      • DashboardRepository          │   │
│  │  • ProfileRepository   • ConsultationsRepository      │   │
│  │  • ReviewsRepository   • CalendarRepository (planned) │   │
│  └──────────────────────────────────────────────────────┘   │
└───────────────────────────┬─────────────────────────────────┘
                            │
                            │ API / Storage Calls
                            │
┌───────────────────────────▼─────────────────────────────────┐
│                    Infrastructure Layer                      │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐         │
│  │ ApiService  │  │   Storage   │  │   Network   │         │
│  └─────────────┘  └─────────────┘  └─────────────┘         │
└─────────────────────────────────────────────────────────────┘
```

---

## 📦 Layer Details

### 1. Presentation Layer (UI)

**Purpose:** Display data and capture user interactions

**Components:**
- **Screens**: Full-page views (e.g., `LoginScreen`, `DashboardScreen`)
- **Widgets**: Reusable UI components (e.g., `CustomButton`, `StatCard`)
- **Themes**: Visual styling and branding

**Responsibilities:**
- Render UI based on state
- Dispatch events to BLoCs
- Listen to BLoC states
- Handle user input

**Dependencies:**
- BLoC layer (via BlocBuilder, BlocListener)
- Theme service
- Language service

**Example:**
```dart
BlocBuilder<AuthBloc, AuthState>(
  builder: (context, state) {
    if (state is AuthLoading) {
      return CircularProgressIndicator();
    } else if (state is AuthSuccessState) {
      return WelcomeScreen(user: state.astrologer);
    } else if (state is AuthErrorState) {
      return ErrorWidget(message: state.message);
    }
    return LoginForm();
  },
)
```

---

### 2. Business Logic Layer (BLoC)

**Purpose:** Handle business logic and state management

**Components:**
- **BLoC**: Business Logic Component
- **Events**: User actions or system events
- **States**: Representations of app state

**Responsibilities:**
- Process events
- Execute business rules
- Transform data for presentation
- Emit states
- Coordinate repository calls
- Handle errors gracefully

**Dependencies:**
- Repository layer (via dependency injection)
- No direct UI dependencies
- No direct service dependencies

**Structure:**
```dart
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository repository;

  AuthBloc({required this.repository}) : super(AuthInitial()) {
    on<LoginEvent>(_onLogin);
    on<LogoutEvent>(_onLogout);
  }

  Future<void> _onLogin(LoginEvent event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      final user = await repository.login(event.phone, event.otp);
      emit(AuthSuccessState(user));
    } catch (e) {
      emit(AuthErrorState(e.toString()));
    }
  }
}
```

**Key Principles:**
- Pure business logic only
- No UI code
- No direct API calls
- No direct storage calls
- Testable without Flutter framework

---

### 3. Data Layer (Repositories)

**Purpose:** Abstract data sources and provide clean APIs

**Components:**
- **Repository Interface**: Abstract contract
- **Repository Implementation**: Concrete implementation
- **Models**: Data structures

**Responsibilities:**
- Fetch data from API
- Cache data locally
- Transform API responses to models
- Handle network errors
- Implement offline-first strategies
- Manage data consistency

**Dependencies:**
- Infrastructure layer (ApiService, StorageService)
- No BLoC dependencies
- No UI dependencies

**Structure:**
```dart
// Interface (Contract)
abstract class AuthRepository {
  Future<AstrologerModel> login(String phone, String otp);
  Future<void> logout();
  Future<bool> isLoggedIn();
}

// Implementation
class AuthRepositoryImpl implements AuthRepository {
  final ApiService apiService;
  final StorageService storageService;

  AuthRepositoryImpl({
    required this.apiService,
    required this.storageService,
  });

  @override
  Future<AstrologerModel> login(String phone, String otp) async {
    // 1. Call API
    final response = await apiService.post('/auth/login', {
      'phone': phone,
      'otp': otp,
    });
    
    // 2. Transform response
    final user = AstrologerModel.fromJson(response.data);
    
    // 3. Cache locally
    await storageService.setUserData(jsonEncode(user.toJson()));
    
    // 4. Return
    return user;
  }
}
```

**Key Principles:**
- Interface + Implementation pattern
- Data operations only
- No business logic
- No UI code
- Mockable for testing

---

### 4. Infrastructure Layer (Services)

**Purpose:** Handle external dependencies and low-level operations

**Components:**
- **ApiService**: HTTP client wrapper (Dio)
- **StorageService**: Local storage wrapper (SharedPreferences)
- **NotificationService**: Push notifications
- **LanguageService**: Internationalization

**Responsibilities:**
- HTTP requests
- Local storage
- Device APIs
- Third-party SDKs
- Configuration

**Dependencies:**
- External packages (dio, shared_preferences, etc.)
- No app-specific logic

**Example:**
```dart
class ApiService {
  final Dio _dio;

  Future<Response> get(String endpoint) async {
    try {
      return await _dio.get(endpoint);
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<Response> post(String endpoint, Map<String, dynamic> data) async {
    try {
      return await _dio.post(endpoint, data: data);
    } catch (e) {
      throw _handleError(e);
    }
  }
}
```

---

## 🔄 Data Flow

### User Action Flow

```
User Interaction
    │
    │ 1. User taps button
    ▼
UI dispatches Event
    │
    │ 2. bloc.add(LoginEvent(phone, otp))
    ▼
BLoC receives Event
    │
    │ 3. on<LoginEvent>(_onLogin)
    ▼
BLoC calls Repository
    │
    │ 4. final user = await repository.login(...)
    ▼
Repository calls API
    │
    │ 5. final response = await apiService.post(...)
    ▼
Repository transforms data
    │
    │ 6. final user = AstrologerModel.fromJson(...)
    ▼
Repository caches data
    │
    │ 7. await storageService.save(user)
    ▼
Repository returns data
    │
    │ 8. return user
    ▼
BLoC emits new State
    │
    │ 9. emit(AuthSuccessState(user))
    ▼
UI rebuilds
    │
    │ 10. BlocBuilder rebuilds with new state
    ▼
User sees result
```

---

## 🔧 Dependency Injection

We use `get_it` for dependency injection:

```dart
// lib/core/di/service_locator.dart

final getIt = GetIt.instance;

Future<void> setupServiceLocator() async {
  // 1. Register Services (Singletons)
  getIt.registerLazySingleton<StorageService>(
    () => StorageService()..initialize(),
  );
  
  getIt.registerLazySingleton<ApiService>(
    () => ApiService()..initialize(),
  );

  // 2. Register Repositories (Singletons)
  getIt.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(
      apiService: getIt<ApiService>(),
      storageService: getIt<StorageService>(),
    ),
  );

  // 3. Register BLoCs (Factories - new instance each time)
  getIt.registerFactory<AuthBloc>(
    () => AuthBloc(repository: getIt<AuthRepository>()),
  );
}

// Usage in app:
BlocProvider<AuthBloc>(
  create: (context) => getIt<AuthBloc>(),
  child: MyApp(),
)
```

**Benefits:**
- ✅ Loose coupling
- ✅ Easy to test (swap implementations)
- ✅ Single source of truth
- ✅ Centralized configuration

---

## 📁 Project Structure

```
lib/
├── app/
│   ├── app.dart                    # Main app widget
│   └── routes.dart                 # Route configuration
│
├── core/                           # Shared core functionality
│   ├── constants/
│   │   └── api_constants.dart      # API endpoints
│   ├── di/
│   │   └── service_locator.dart    # Dependency injection setup
│   └── services/
│       ├── api_service.dart        # HTTP client
│       └── storage_service.dart    # Local storage
│
├── data/                           # Data layer
│   └── repositories/
│       ├── base_repository.dart    # Base repository
│       ├── auth/
│       │   ├── auth_repository.dart          # Interface
│       │   └── auth_repository_impl.dart     # Implementation
│       ├── dashboard/
│       │   ├── dashboard_repository.dart
│       │   └── dashboard_repository_impl.dart
│       ├── consultations/
│       │   ├── consultations_repository.dart
│       │   └── consultations_repository_impl.dart
│       └── profile/
│           ├── profile_repository.dart
│           └── profile_repository_impl.dart
│
├── features/                       # Feature-based organization
│   ├── auth/
│   │   ├── bloc/
│   │   │   ├── auth_bloc.dart
│   │   │   ├── auth_event.dart
│   │   │   └── auth_state.dart
│   │   ├── models/
│   │   │   └── astrologer_model.dart
│   │   └── screens/
│   │       ├── login_screen.dart
│   │       └── signup_screen.dart
│   │
│   ├── dashboard/
│   │   ├── bloc/
│   │   ├── models/
│   │   └── screens/
│   │
│   ├── consultations/
│   │   ├── bloc/
│   │   ├── models/
│   │   └── screens/
│   │
│   └── profile/
│       ├── bloc/
│       ├── models/
│       └── screens/
│
├── shared/                         # Shared widgets and utilities
│   ├── theme/
│   ├── widgets/
│   └── utils/
│
└── main.dart                       # App entry point
```

---

## 🎯 Design Patterns Used

### 1. Repository Pattern
- Abstracts data sources
- Provides clean API to business logic layer
- Enables easy testing and swapping of implementations

### 2. BLoC Pattern
- Separates business logic from UI
- Predictable state management
- Easy to test and maintain

### 3. Dependency Injection
- Loose coupling between components
- Easy to test with mocked dependencies
- Centralized configuration

### 4. Factory Pattern
- Used in service locator for creating BLoCs
- New instance for each provider

### 5. Singleton Pattern
- Used for services and repositories
- Single instance shared across app

---

## ✅ Best Practices

### BLoC Layer
```dart
// ✅ DO: Use repository
Future<void> _onLoadData(LoadDataEvent event, Emitter<State> emit) async {
  emit(LoadingState());
  try {
    final data = await repository.getData();
    emit(LoadedState(data));
  } catch (e) {
    emit(ErrorState(e.toString()));
  }
}

// ❌ DON'T: Direct API call
Future<void> _onLoadData(LoadDataEvent event, Emitter<State> emit) async {
  final response = await apiService.get('/data'); // ❌ Wrong layer
  emit(LoadedState(response.data));
}
```

### Repository Layer
```dart
// ✅ DO: Abstract interface + Implementation
abstract class DataRepository {
  Future<List<Data>> getData();
}

class DataRepositoryImpl implements DataRepository {
  final ApiService apiService;
  
  @override
  Future<List<Data>> getData() async {
    final response = await apiService.get('/data');
    return (response.data as List)
        .map((json) => Data.fromJson(json))
        .toList();
  }
}

// ❌ DON'T: Concrete class only
class DataRepository { // ❌ Can't mock easily
  Future<List<Data>> getData() async { ... }
}
```

### UI Layer
```dart
// ✅ DO: Listen to BLoC
BlocBuilder<AuthBloc, AuthState>(
  builder: (context, state) {
    if (state is AuthLoading) return LoadingWidget();
    if (state is AuthSuccess) return HomeScreen();
    return LoginScreen();
  },
)

// ❌ DON'T: Direct repository call
final data = await repository.getData(); // ❌ Wrong layer
```

---

## 🧪 Testing Strategy

### Unit Tests
- Test each layer independently
- Mock dependencies
- Fast and deterministic

### Integration Tests
- Test complete flows
- Real or test doubles
- Verify layer interactions

### Widget Tests
- Test UI components
- Mock BLoCs
- Verify user interactions

**Coverage Goals:**
- Repositories: 90%+
- BLoCs: 95%+
- Widgets: 70%+

---

## 🚀 Adding New Features

### Step-by-Step Guide

1. **Define Models**
```dart
class MyDataModel {
  final String id;
  final String name;
  
  MyDataModel({required this.id, required this.name});
  
  factory MyDataModel.fromJson(Map<String, dynamic> json) => MyDataModel(
    id: json['id'],
    name: json['name'],
  );
}
```

2. **Create Repository Interface**
```dart
abstract class MyRepository {
  Future<List<MyDataModel>> getData();
  Future<MyDataModel> getById(String id);
  Future<void> save(MyDataModel data);
}
```

3. **Implement Repository**
```dart
class MyRepositoryImpl implements MyRepository {
  final ApiService apiService;
  final StorageService storageService;
  
  MyRepositoryImpl({required this.apiService, required this.storageService});
  
  @override
  Future<List<MyDataModel>> getData() async {
    final response = await apiService.get('/my-data');
    return (response.data as List)
        .map((json) => MyDataModel.fromJson(json))
        .toList();
  }
}
```

4. **Define Events and States**
```dart
// Events
abstract class MyEvent {}
class LoadDataEvent extends MyEvent {}

// States
abstract class MyState {}
class MyInitial extends MyState {}
class MyLoading extends MyState {}
class MyLoaded extends MyState {
  final List<MyDataModel> data;
  MyLoaded(this.data);
}
```

5. **Create BLoC**
```dart
class MyBloc extends Bloc<MyEvent, MyState> {
  final MyRepository repository;
  
  MyBloc({required this.repository}) : super(MyInitial()) {
    on<LoadDataEvent>(_onLoadData);
  }
  
  Future<void> _onLoadData(LoadDataEvent event, Emitter<MyState> emit) async {
    emit(MyLoading());
    try {
      final data = await repository.getData();
      emit(MyLoaded(data));
    } catch (e) {
      emit(MyError(e.toString()));
    }
  }
}
```

6. **Register in DI**
```dart
// In service_locator.dart
getIt.registerLazySingleton<MyRepository>(
  () => MyRepositoryImpl(
    apiService: getIt<ApiService>(),
    storageService: getIt<StorageService>(),
  ),
);

getIt.registerFactory<MyBloc>(
  () => MyBloc(repository: getIt<MyRepository>()),
);
```

7. **Use in UI**
```dart
BlocProvider<MyBloc>(
  create: (context) => getIt<MyBloc>()..add(LoadDataEvent()),
  child: BlocBuilder<MyBloc, MyState>(
    builder: (context, state) {
      if (state is MyLoading) return LoadingWidget();
      if (state is MyLoaded) return DataListWidget(state.data);
      return ErrorWidget();
    },
  ),
)
```

---

## 📊 Architecture Metrics

| Metric | Current | Goal | Status |
|--------|---------|------|--------|
| BLoCs with Repository Pattern | 5/5 | 100% | ✅ |
| Repositories with Interface | 5/5 | 100% | ✅ |
| Test Coverage - Repositories | TBD | 90%+ | ⏳ |
| Test Coverage - BLoCs | TBD | 95%+ | ⏳ |
| Linter Errors | 0 | 0 | ✅ |
| Code Duplication | Low | Low | ✅ |

---

## 🎓 Learning Resources

- [BLoC Library Documentation](https://bloclibrary.dev/)
- [Clean Architecture by Uncle Bob](https://blog.cleancoder.com/uncle-bob/2012/08/13/the-clean-architecture.html)
- [Flutter Architecture Samples](https://github.com/brianegan/flutter_architecture_samples)
- [Repository Pattern in Flutter](https://www.kodeco.com/24502121-repository-pattern-in-flutter)

---

**Document Version:** 1.0  
**Last Updated:** October 2024  
**Maintained By:** Development Team  
**Status:** ✅ Complete


