# 🏗️ BLoC Architecture Refactoring Plan

## 📊 Current State Analysis

### What We Have Now (Problems)
- ❌ **BLoC Coverage:** 28% (5 out of 18 features)
- ❌ **Repository Pattern:** 6% (only ReviewsBloc has it)
- ❌ **Dependency Injection:** 0% (none)
- ❌ **State Management Quality:** 6.8/10
- ❌ **Architecture Consistency:** 3/10
- ❌ **Overall Grade:** D+ (35%)

### Current Patterns (Mixed Approach)
1. **BLoC Pattern** (5 features - 28%)
   - ✅ AuthBloc
   - ✅ DashboardBloc
   - ✅ ConsultationsBloc
   - ✅ ProfileBloc
   - ✅ ReviewsBloc (✨ Best implemented - has repository!)

2. **Provider Services** (6 services - Acting as state managers)
   - LanguageService
   - ThemeService
   - StatusService
   - NotificationService
   - CommunicationService
   - LiveStreamService

3. **setState + Local State** (83+ screens - 72%)
   - Calendar Screen (500+ lines)
   - Earnings Screen
   - Live Streams
   - Discussion/Heal
   - Communication
   - Settings
   - Chat
   - Help & Support
   - And 75+ more...

---

## 🎯 Target Architecture

```
┌─────────────────────────────────────────────────────────┐
│              PRESENTATION LAYER (UI)                     │
│         Screens → BlocBuilder/BlocListener              │
└───────────────────────┬─────────────────────────────────┘
                        ↓
┌───────────────────────┴─────────────────────────────────┐
│           BUSINESS LOGIC LAYER (BLoCs)                  │
│          12-15 BLoCs handling state logic               │
└───────────────────────┬─────────────────────────────────┘
                        ↓
┌───────────────────────┴─────────────────────────────────┐
│              DATA LAYER (Repositories)                   │
│        12-15 Repositories - Data abstraction            │
└───────────────────────┬─────────────────────────────────┘
                        ↓
┌───────────────────────┴─────────────────────────────────┐
│          DATA SOURCES (Services)                         │
│      ApiService + StorageService + Cache                │
└─────────────────────────────────────────────────────────┘
```

---

## 📅 PHASE 1: Repository Layer Foundation (2-3 weeks)
**Status:** 🟡 IN PROGRESS  
**Priority:** 🔴 CRITICAL - Everything else depends on this

### Goals
- ✅ Create repository pattern infrastructure
- ✅ Implement repositories for existing 5 BLoCs
- ✅ Refactor BLoCs to use repositories instead of ApiService
- ✅ Set up dependency injection foundation

### Tasks

#### Week 1: Infrastructure & Auth Repository
- [ ] Create base repository interfaces
- [ ] Create `AuthRepository` interface
- [ ] Create `AuthRepositoryImpl`
- [ ] Refactor `AuthBloc` to use repository
- [ ] Add basic dependency injection setup
- [ ] Test Auth flow still works

#### Week 2: Dashboard, Consultations, Profile Repositories
- [ ] Create `DashboardRepository` interface & implementation
- [ ] Refactor `DashboardBloc` to use repository
- [ ] Create `ConsultationsRepository` interface & implementation
- [ ] Refactor `ConsultationsBloc` to use repository
- [ ] Create `ProfileRepository` interface & implementation
- [ ] Refactor `ProfileBloc` to use repository

#### Week 3: Cleanup & Testing
- [ ] Review all repository implementations
- [ ] Update dependency injection
- [ ] Clean up old service calls
- [ ] Document repository pattern
- [ ] Test all affected features

### Files to Create
```
lib/
  core/
    di/
      service_locator.dart          # NEW - Dependency injection
  data/
    repositories/
      base_repository.dart          # NEW - Base interface
      auth/
        auth_repository.dart        # NEW - Interface
        auth_repository_impl.dart   # NEW - Implementation
      dashboard/
        dashboard_repository.dart
        dashboard_repository_impl.dart
      consultations/
        consultations_repository.dart
        consultations_repository_impl.dart
      profile/
        profile_repository.dart
        profile_repository_impl.dart
      reviews/
        reviews_repository.dart     # ✅ Already exists!
```

### Expected Outcomes
- ✅ Clean separation between BLoC and data layer
- ✅ BLoCs no longer know about HTTP, JSON, API endpoints
- ✅ Easier to test (can mock repositories)
- ✅ Can switch data sources (API ↔ Local DB) easily

---

## 📅 PHASE 2: Fix Existing BLoCs (2 weeks)
**Status:** ⚪ NOT STARTED  
**Priority:** 🔴 HIGH

### Goals
- Add Equatable to all states (prevent unnecessary rebuilds)
- Consolidate multiple states into single state with status
- Implement proper copyWith pattern
- Fix data loss during loading states

### Tasks

#### Week 1: State Refactoring
- [ ] Add Equatable to `AuthState` classes
- [ ] Consolidate `DashboardState` classes
- [ ] Simplify `ConsultationsState` (too many states)
- [ ] Complete rewrite of `ProfileState` (worst one)

#### Week 2: Testing & Validation
- [ ] Test all state transitions
- [ ] Verify no unnecessary rebuilds
- [ ] Ensure data persists during loading
- [ ] Update documentation

### Files to Update
```
lib/features/
  auth/bloc/
    auth_state.dart               # Add Equatable
  dashboard/bloc/
    dashboard_state.dart          # Consolidate states
  consultations/bloc/
    consultations_state.dart      # Simplify
  profile/bloc/
    profile_state.dart            # Complete rewrite
```

---

## 📅 PHASE 3: Add Missing BLoCs (3-4 weeks)
**Status:** ⚪ NOT STARTED  
**Priority:** 🔴 HIGH

### New BLoCs Needed (7 total)

#### Week 1: Calendar & Earnings
1. **CalendarBloc** (HIGH PRIORITY)
   - Replace 500+ lines of setState
   - Events: LoadCalendar, UpdateAvailability, AddHoliday, etc.
   - States: CalendarLoaded, AvailabilityUpdated, etc.
   - Repository: CalendarRepository

2. **EarningsBloc**
   - Financial data management
   - Events: LoadEarnings, FilterByPeriod, etc.
   - States: EarningsLoaded, TransactionsLoaded, etc.
   - Repository: EarningsRepository

#### Week 2: Communication & Notifications
3. **CommunicationBloc**
   - Replace Provider CommunicationService
   - Events: LoadCommunications, FilterCommunications, etc.
   - States: CommunicationsLoaded, CallIncoming, etc.
   - Repository: CommunicationRepository

4. **NotificationBloc**
   - Replace Provider NotificationService
   - Events: LoadNotifications, MarkAsRead, etc.
   - States: NotificationsLoaded, NotificationReceived, etc.
   - Repository: NotificationRepository

#### Week 3: Live Streams & Discussion
5. **LiveStreamBloc**
   - Live streaming features
   - Events: StartStream, EndStream, LoadStreams, etc.
   - States: StreamActive, StreamEnded, StreamsLoaded, etc.
   - Repository: LiveStreamRepository

6. **DiscussionBloc**
   - Heal/community features
   - Events: LoadDiscussions, CreatePost, AddComment, etc.
   - States: DiscussionsLoaded, PostCreated, etc.
   - Repository: DiscussionRepository

#### Week 4: Chat & Polish
7. **ChatBloc**
   - AI chat management
   - Events: SendMessage, LoadChatHistory, etc.
   - States: MessagesLoaded, MessageSent, etc.
   - Repository: ChatRepository

---

## 📅 PHASE 4: Dependency Injection (1 week)
**Status:** ⚪ NOT STARTED  
**Priority:** 🟡 MEDIUM

### Goals
- Complete dependency injection setup
- Remove all direct service instantiations
- Make code fully testable

### Tasks
- [ ] Add `get_it` package to pubspec.yaml
- [ ] Complete service locator setup
- [ ] Register all services
- [ ] Register all repositories
- [ ] Register all BLoCs
- [ ] Update main.dart initialization
- [ ] Update all BLoC providers

### Example
```dart
// Before
final ApiService _apiService = ApiService();  // ❌

// After
final authRepository = getIt<AuthRepository>();  // ✅
```

---

## 📅 PHASE 5: Provider Cleanup (1 week)
**Status:** ⚪ NOT STARTED  
**Priority:** 🟢 LOW

### Strategy
**Keep Provider for:**
- ✅ ThemeService (UI preference)
- ✅ LanguageService (UI preference)

**Convert to BLoC:**
- ❌ StatusService → Part of ProfileBloc
- ❌ CommunicationService → CommunicationBloc
- ❌ NotificationService → NotificationBloc
- ❌ LiveStreamService → LiveStreamBloc

---

## 📅 PHASE 6: Screen Refactoring (2 weeks)
**Status:** ⚪ NOT STARTED  
**Priority:** 🟡 MEDIUM

### Goals
- Remove all direct StorageService calls from screens
- Remove local state variables (use BLoC state)
- Consolidate duplicate API calls
- Implement proper loading/error states everywhere

### Priority Screens
1. Dashboard Screen (remove _currentUser, _currentStats)
2. Calendar Screen (remove all local state)
3. Discussion Screen (remove all local state)
4. Live Streams Screen (remove all local state)

---

## 📅 PHASE 7: Testing Infrastructure (2 weeks)
**Status:** ⚪ NOT STARTED  
**Priority:** 🟢 LOW

### Goals
- Write unit tests for all BLoCs (12-15 BLoCs)
- Write tests for all repositories
- Write integration tests
- Achieve 80%+ code coverage

---

## 📊 Progress Tracking

### BLoCs Implementation Status

| Feature | BLoC Exists | Has Repository | Uses DI | Equatable | Score | Status |
|---------|-------------|----------------|---------|-----------|-------|--------|
| Auth | ✅ | 🟡 In Progress | ⚪ | ⚪ | 8/10 | Phase 1 |
| Dashboard | ✅ | 🟡 In Progress | ⚪ | ⚪ | 6/10 | Phase 1 |
| Consultations | ✅ | 🟡 In Progress | ⚪ | ⚪ | 7/10 | Phase 1 |
| Profile | ✅ | 🟡 In Progress | ⚪ | ⚪ | 4/10 | Phase 1 |
| Reviews | ✅ | ✅ | ✅ | ✅ | 9/10 | ✅ Done |
| Calendar | ⚪ | ⚪ | ⚪ | ⚪ | 0/10 | Phase 3 |
| Earnings | ⚪ | ⚪ | ⚪ | ⚪ | 0/10 | Phase 3 |
| Communication | ⚪ | ⚪ | ⚪ | ⚪ | 0/10 | Phase 3 |
| Notifications | ⚪ | ⚪ | ⚪ | ⚪ | 0/10 | Phase 3 |
| Live Streams | ⚪ | ⚪ | ⚪ | ⚪ | 0/10 | Phase 3 |
| Discussion | ⚪ | ⚪ | ⚪ | ⚪ | 0/10 | Phase 3 |
| Chat | ⚪ | ⚪ | ⚪ | ⚪ | 0/10 | Phase 3 |

**Legend:**
- ✅ Complete
- 🟡 In Progress
- ⚪ Not Started
- ❌ Issues Found

---

## 📈 Timeline Overview

| Phase | Duration | Priority | Status |
|-------|----------|----------|--------|
| Phase 1: Repository Layer | 2-3 weeks | 🔴 CRITICAL | 🟡 IN PROGRESS |
| Phase 2: Fix Existing BLoCs | 2 weeks | 🔴 HIGH | ⚪ NOT STARTED |
| Phase 3: Add Missing BLoCs | 3-4 weeks | 🔴 HIGH | ⚪ NOT STARTED |
| Phase 4: Dependency Injection | 1 week | 🟡 MEDIUM | ⚪ NOT STARTED |
| Phase 5: Provider Cleanup | 1 week | 🟢 LOW | ⚪ NOT STARTED |
| Phase 6: Screen Refactoring | 2 weeks | 🟡 MEDIUM | ⚪ NOT STARTED |
| Phase 7: Testing | 2 weeks | 🟢 LOW | ⚪ NOT STARTED |
| **TOTAL** | **13-17 weeks** | | |

---

## 🎯 Success Metrics

### Target Scores
- **BLoC Coverage:** 100% (12-15 features)
- **Repository Pattern:** 100%
- **Dependency Injection:** 100%
- **State Management Quality:** 9/10
- **Architecture Consistency:** 9/10
- **Testability:** 8/10
- **Overall Grade:** A (90%+)

---

## 📝 Notes & Decisions

### Why ReviewsBloc is the Best Example
- ✅ Uses Equatable on all states
- ✅ Has repository pattern
- ✅ Uses dependency injection
- ✅ Clean separation of concerns
- **Use this as the template for all other BLoCs!**

### Repository Pattern Benefits
- Clean separation between business logic and data
- Easy to test (mock repositories)
- Can switch data sources (API → Local DB)
- BLoCs don't know about HTTP, JSON, endpoints

### Dependency Injection Benefits
- No direct service instantiation
- Easy to mock in tests
- Loose coupling
- Better architecture

---

## 🚀 Quick Start (Phase 1)

```bash
# 1. Create directory structure
mkdir -p lib/core/di
mkdir -p lib/data/repositories/auth
mkdir -p lib/data/repositories/dashboard
mkdir -p lib/data/repositories/consultations
mkdir -p lib/data/repositories/profile

# 2. Start with AuthRepository (most critical)
# See lib/data/repositories/auth/auth_repository.dart

# 3. Add get_it for dependency injection
flutter pub add get_it

# 4. Follow the implementation plan below
```

---

## 📚 References

- [BLoC Official Documentation](https://bloclibrary.dev)
- [Clean Architecture in Flutter](https://resocoder.com/flutter-clean-architecture)
- [Repository Pattern](https://martinfowler.com/eaaCatalog/repository.html)
- ReviewsBloc implementation (our best example!)

---

**Last Updated:** [Current Date]  
**Current Phase:** Phase 1 - Repository Layer  
**Next Milestone:** Complete AuthRepository implementation


