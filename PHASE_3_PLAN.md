# 🎯 Phase 3: Create Missing BLoCs

## 📋 Overview

**Goal:** Create 7 missing BLoCs following the established architecture pattern

**Duration:** 2-3 weeks  
**Complexity:** Medium-High  
**Status:** 🚀 IN PROGRESS

---

## 🎯 Objectives

### 1. Identify Missing BLoCs
Analyze existing codebase and identify features without proper BLoC implementation

### 2. Create BLoC Architecture
For each feature:
- Create BLoC with events and states
- Create repository interface and implementation
- Register in dependency injection
- Update UI to use BLoC

### 3. Maintain Consistency
- Follow Phase 1 & 2 patterns
- Use Equatable for all states
- Use repository pattern
- Proper dependency injection

---

## 📊 Missing BLoCs Identified

### 1. **Calendar/Schedule BLoC** (High Priority) ⏰
**Current:** No BLoC - using direct API calls?
**Need:** Schedule management, availability, bookings
**Complexity:** Medium

### 2. **Earnings BLoC** (High Priority) 💰
**Current:** Mixed with Dashboard
**Need:** Detailed earnings tracking, history, analytics
**Complexity:** Medium

### 3. **Communication BLoC** (High Priority) 💬
**Current:** Using CommunicationService with ChangeNotifier
**Need:** Proper BLoC for calls/messages
**Complexity:** High

### 4. **Heal/Community BLoC** (Medium Priority) 🌟
**Current:** Using screens directly
**Need:** Community posts, discussions
**Complexity:** Medium

### 5. **Help & Support BLoC** (Medium Priority) ❓
**Current:** Using service directly
**Need:** Tickets, FAQs, documentation
**Complexity:** Low-Medium

### 6. **Live Streaming BLoC** (Medium Priority) 📺
**Current:** Using LiveStreamService
**Need:** Live sessions management
**Complexity:** High

### 7. **Notifications BLoC** (Low Priority) 🔔
**Current:** Using NotificationService with ChangeNotifier
**Need:** Enhanced notification management
**Complexity:** Low

---

## 📅 Phase 3 Schedule

### Week 1: High Priority BLoCs
**Days 1-2: Calendar BLoC**
- [ ] Create CalendarRepository interface
- [ ] Implement CalendarRepositoryImpl
- [ ] Create CalendarBloc with events/states
- [ ] Register in DI
- [ ] Update UI

**Days 3-4: Earnings BLoC**
- [ ] Create EarningsRepository interface
- [ ] Implement EarningsRepositoryImpl
- [ ] Create EarningsBloc with events/states
- [ ] Register in DI
- [ ] Update UI

**Day 5: Communication BLoC (Start)**
- [ ] Analyze current communication flow
- [ ] Create CommunicationRepository interface
- [ ] Start implementation

### Week 2: Continue & Medium Priority
**Days 1-2: Communication BLoC (Complete)**
- [ ] Complete CommunicationRepositoryImpl
- [ ] Create CommunicationBloc
- [ ] Register in DI
- [ ] Update UI

**Days 3-4: Heal/Community BLoC**
- [ ] Create HealRepository
- [ ] Create HealBloc
- [ ] Update UI

**Day 5: Help & Support BLoC**
- [ ] Create HelpSupportRepository
- [ ] Create HelpSupportBloc
- [ ] Update UI

### Week 3: Low Priority & Polish
**Days 1-2: Live Streaming BLoC**
- [ ] Create LiveStreamRepository
- [ ] Create LiveStreamBloc
- [ ] Update UI

**Day 3: Notifications BLoC**
- [ ] Create NotificationsRepository
- [ ] Create NotificationsBloc
- [ ] Update UI

**Days 4-5: Testing & Documentation**
- [ ] Test all new BLoCs
- [ ] Update documentation
- [ ] Create Phase 3 report

---

## 📝 Implementation Template

For each BLoC, follow this structure:

### 1. Repository Interface
```dart
// lib/data/repositories/feature/feature_repository.dart
abstract class FeatureRepository {
  Future<List<Model>> getData();
  Future<Model> getById(String id);
  Future<void> save(Model data);
}
```

### 2. Repository Implementation
```dart
// lib/data/repositories/feature/feature_repository_impl.dart
class FeatureRepositoryImpl implements FeatureRepository {
  final ApiService apiService;
  final StorageService storageService;
  
  FeatureRepositoryImpl({
    required this.apiService,
    required this.storageService,
  });
  
  @override
  Future<List<Model>> getData() async {
    // Implementation
  }
}
```

### 3. BLoC Events
```dart
// lib/features/feature/bloc/feature_event.dart
abstract class FeatureEvent extends Equatable {
  const FeatureEvent();
}

class LoadDataEvent extends FeatureEvent {
  @override
  List<Object?> get props => [];
}
```

### 4. BLoC States
```dart
// lib/features/feature/bloc/feature_state.dart
abstract class FeatureState extends Equatable {
  const FeatureState();
  
  @override
  List<Object?> get props => [];
}

class FeatureInitial extends FeatureState {}
class FeatureLoading extends FeatureState {}
class FeatureLoaded extends FeatureState {
  final List<Model> data;
  const FeatureLoaded(this.data);
  
  @override
  List<Object?> get props => [data];
}
```

### 5. BLoC Implementation
```dart
// lib/features/feature/bloc/feature_bloc.dart
class FeatureBloc extends Bloc<FeatureEvent, FeatureState> {
  final FeatureRepository repository;
  
  FeatureBloc({required this.repository}) : super(FeatureInitial()) {
    on<LoadDataEvent>(_onLoadData);
  }
  
  Future<void> _onLoadData(
    LoadDataEvent event,
    Emitter<FeatureState> emit,
  ) async {
    emit(FeatureLoading());
    try {
      final data = await repository.getData();
      emit(FeatureLoaded(data));
    } catch (e) {
      emit(FeatureError(e.toString()));
    }
  }
}
```

### 6. Register in DI
```dart
// lib/core/di/service_locator.dart
getIt.registerLazySingleton<FeatureRepository>(
  () => FeatureRepositoryImpl(
    apiService: getIt<ApiService>(),
    storageService: getIt<StorageService>(),
  ),
);

getIt.registerFactory<FeatureBloc>(
  () => FeatureBloc(repository: getIt<FeatureRepository>()),
);
```

---

## 🎯 Success Criteria

| Metric | Target | Status |
|--------|--------|--------|
| BLoCs Created | 7 | 0/7 |
| Repositories Created | 7 | 0/7 |
| All using Equatable | 100% | - |
| All using DI | 100% | - |
| Linter Errors | 0 | - |
| Documentation | Complete | - |

---

## 📊 Estimated Impact

### Before Phase 3:
- BLoCs: 5
- Mixed state management (BLoC + Provider + direct API)
- Inconsistent patterns

### After Phase 3:
- BLoCs: 12 (+140%)
- All features use BLoC pattern
- Consistent architecture across app

---

## 🚀 Let's Start!

Beginning with **Calendar BLoC** - the most critical missing piece.

---

**Phase 3 Started:** October 26, 2024  
**Expected Completion:** Mid November 2024  
**Status:** 🚀 IN PROGRESS


