# 🧪 Testing Guide - BLoC Architecture

## 📚 Overview

This guide shows how to test your BLoC architecture with the new repository pattern. All BLoCs are now 100% testable!

---

## 🏗️ Test Structure

```
test/
├── unit/
│   ├── repositories/
│   │   ├── auth_repository_test.dart
│   │   ├── dashboard_repository_test.dart
│   │   ├── consultations_repository_test.dart
│   │   └── profile_repository_test.dart
│   └── blocs/
│       ├── auth_bloc_test.dart
│       ├── dashboard_bloc_test.dart
│       ├── consultations_bloc_test.dart
│       └── profile_bloc_test.dart
├── integration/
│   ├── auth_flow_test.dart
│   └── consultation_flow_test.dart
└── mocks/
    ├── mock_repositories.dart
    └── mock_services.dart
```

---

## 📦 Required Packages

Add to `pubspec.yaml`:

```yaml
dev_dependencies:
  flutter_test:
    sdk: flutter
  mockito: ^5.4.0
  build_runner: ^2.4.0
  bloc_test: ^9.1.0
  mocktail: ^1.0.0  # Alternative to mockito
```

---

## 🎯 Testing Strategy

### 1. Repository Tests
Test data layer in isolation - verify API calls and data transformation

### 2. BLoC Tests  
Test business logic in isolation - verify state changes with mocked repositories

### 3. Integration Tests
Test complete flows end-to-end

---

## 📝 Example 1: Testing AuthRepository

### Create Mock Services

```dart
// test/mocks/mock_services.dart
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:astrologer_app/core/services/api_service.dart';
import 'package:astrologer_app/core/services/storage_service.dart';

@GenerateMocks([ApiService, StorageService])
class MockApiService extends Mock implements ApiService {}
class MockStorageService extends Mock implements StorageService {}
```

### Test AuthRepository

```dart
// test/unit/repositories/auth_repository_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:dio/dio.dart';
import 'package:astrologer_app/data/repositories/auth/auth_repository_impl.dart';
import '../../mocks/mock_services.dart';

void main() {
  late AuthRepositoryImpl repository;
  late MockApiService mockApiService;
  late MockStorageService mockStorageService;

  setUp(() {
    mockApiService = MockApiService();
    mockStorageService = MockStorageService();
    repository = AuthRepositoryImpl(
      apiService: mockApiService,
      storageService: mockStorageService,
    );
  });

  group('AuthRepository - checkPhoneExists', () {
    test('returns exists true when phone exists', () async {
      // Arrange
      final mockResponse = Response(
        data: {'exists': true, 'message': 'Phone number exists'},
        statusCode: 200,
        requestOptions: RequestOptions(path: '/api/auth/check-phone'),
      );
      
      when(mockApiService.post(any, data: anyNamed('data')))
          .thenAnswer((_) async => mockResponse);

      // Act
      final result = await repository.checkPhoneExists('+919876543210');

      // Assert
      expect(result['exists'], true);
      expect(result['message'], 'Phone number exists');
      verify(mockApiService.post(
        '/api/auth/check-phone',
        data: {'phone': '+919876543210'},
      )).called(1);
    });

    test('returns exists false when phone does not exist', () async {
      // Arrange
      final mockResponse = Response(
        data: {'exists': false, 'message': 'Phone number not found'},
        statusCode: 200,
        requestOptions: RequestOptions(path: '/api/auth/check-phone'),
      );
      
      when(mockApiService.post(any, data: anyNamed('data')))
          .thenAnswer((_) async => mockResponse);

      // Act
      final result = await repository.checkPhoneExists('+919876543210');

      // Assert
      expect(result['exists'], false);
      expect(result['message'], 'Phone number not found');
    });

    test('throws exception on network error', () async {
      // Arrange
      when(mockApiService.post(any, data: anyNamed('data')))
          .thenThrow(DioException(
            requestOptions: RequestOptions(path: '/api/auth/check-phone'),
            type: DioExceptionType.connectionTimeout,
          ));

      // Act & Assert
      expect(
        () => repository.checkPhoneExists('+919876543210'),
        throwsA(isA<Exception>()),
      );
    });
  });

  group('AuthRepository - verifyOtp', () {
    test('returns auth data on successful verification', () async {
      // Arrange
      final mockResponse = Response(
        data: {
          'success': true,
          'token': 'mock_token_123',
          'sessionId': 'session_123',
          'astrologer': {
            'id': '1',
            'name': 'Test Astrologer',
            'phone': '+919876543210',
            'email': 'test@example.com',
            // ... other fields
          },
        },
        statusCode: 200,
        requestOptions: RequestOptions(path: '/api/auth/verify-otp'),
      );
      
      when(mockApiService.post(any, data: anyNamed('data')))
          .thenAnswer((_) async => mockResponse);
      
      when(mockStorageService.setAuthToken(any))
          .thenAnswer((_) async => true);
      when(mockStorageService.setSessionId(any))
          .thenAnswer((_) async => true);
      when(mockStorageService.setUserData(any))
          .thenAnswer((_) async => true);
      when(mockStorageService.setIsLoggedIn(any))
          .thenAnswer((_) async => true);
      when(mockStorageService.setPhoneNumber(any))
          .thenAnswer((_) async => true);

      // Act
      final result = await repository.verifyOtp(
        phoneNumber: '+919876543210',
        otp: '123456',
      );

      // Assert
      expect(result['success'], true);
      expect(result['token'], 'mock_token_123');
      expect(result['sessionId'], 'session_123');
      expect(result['astrologer'], isNotNull);
      
      // Verify storage calls
      verify(mockStorageService.setAuthToken('mock_token_123')).called(1);
      verify(mockStorageService.setIsLoggedIn(true)).called(1);
    });
  });
}
```

---

## 📝 Example 2: Testing AuthBloc

### Using bloc_test Package

```dart
// test/unit/blocs/auth_bloc_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:mockito/mockito.dart';
import 'package:astrologer_app/features/auth/bloc/auth_bloc.dart';
import 'package:astrologer_app/features/auth/bloc/auth_event.dart';
import 'package:astrologer_app/features/auth/bloc/auth_state.dart';
import 'package:astrologer_app/data/repositories/auth/auth_repository.dart';
import '../../mocks/mock_repositories.dart';

@GenerateMocks([AuthRepository])
void main() {
  late AuthBloc authBloc;
  late MockAuthRepository mockRepository;

  setUp(() {
    mockRepository = MockAuthRepository();
    authBloc = AuthBloc(repository: mockRepository);
  });

  tearDown(() {
    authBloc.close();
  });

  group('AuthBloc - CheckPhoneExistsEvent', () {
    final phoneNumber = '+919876543210';

    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, PhoneCheckedState] when phone exists',
      build: () {
        when(mockRepository.checkPhoneExists(phoneNumber))
            .thenAnswer((_) async => {
                  'exists': true,
                  'message': 'Phone number exists',
                });
        return authBloc;
      },
      act: (bloc) => bloc.add(CheckPhoneExistsEvent(phoneNumber)),
      expect: () => [
        isA<AuthLoading>(),
        isA<PhoneCheckedState>()
            .having((state) => state.exists, 'exists', true)
            .having((state) => state.phoneNumber, 'phoneNumber', phoneNumber),
      ],
      verify: (_) {
        verify(mockRepository.checkPhoneExists(phoneNumber)).called(1);
      },
    );

    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, PhoneCheckedState] when phone does not exist',
      build: () {
        when(mockRepository.checkPhoneExists(phoneNumber))
            .thenAnswer((_) async => {
                  'exists': false,
                  'message': 'Phone number not found',
                });
        return authBloc;
      },
      act: (bloc) => bloc.add(CheckPhoneExistsEvent(phoneNumber)),
      expect: () => [
        isA<AuthLoading>(),
        isA<PhoneCheckedState>()
            .having((state) => state.exists, 'exists', false),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, AuthErrorState] on error',
      build: () {
        when(mockRepository.checkPhoneExists(phoneNumber))
            .thenThrow(Exception('Network error'));
        return authBloc;
      },
      act: (bloc) => bloc.add(CheckPhoneExistsEvent(phoneNumber)),
      expect: () => [
        isA<AuthLoading>(),
        isA<AuthErrorState>()
            .having((state) => state.message, 'message', contains('Network error')),
      ],
    );
  });

  group('AuthBloc - VerifyOtpEvent', () {
    final phoneNumber = '+919876543210';
    final otp = '123456';
    final mockAstrologer = AstrologerModel(
      id: '1',
      name: 'Test Astrologer',
      phone: phoneNumber,
      email: 'test@example.com',
      // ... other required fields
    );

    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, AuthSuccessState] on successful verification',
      build: () {
        when(mockRepository.verifyOtp(
          phoneNumber: phoneNumber,
          otp: otp,
        )).thenAnswer((_) async => {
              'success': true,
              'astrologer': mockAstrologer,
              'token': 'mock_token_123',
              'sessionId': 'session_123',
            });
        return authBloc;
      },
      act: (bloc) => bloc.add(VerifyOtpEvent(
        phoneNumber: phoneNumber,
        otp: otp,
      )),
      expect: () => [
        isA<AuthLoading>(),
        isA<AuthSuccessState>()
            .having((state) => state.token, 'token', 'mock_token_123')
            .having((state) => state.astrologer, 'astrologer', mockAstrologer),
      ],
    );
  });
}
```

---

## 📝 Example 3: Testing DashboardBloc

```dart
// test/unit/blocs/dashboard_bloc_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:mockito/mockito.dart';
import 'package:astrologer_app/features/dashboard/bloc/dashboard_bloc.dart';
import 'package:astrologer_app/features/dashboard/models/dashboard_stats_model.dart';

@GenerateMocks([DashboardRepository])
void main() {
  late DashboardBloc dashboardBloc;
  late MockDashboardRepository mockRepository;

  setUp(() {
    mockRepository = MockDashboardRepository();
    dashboardBloc = DashboardBloc(repository: mockRepository);
  });

  tearDown(() {
    dashboardBloc.close();
  });

  group('DashboardBloc - LoadDashboardStatsEvent', () {
    final mockStats = DashboardStatsModel(
      todayEarnings: 1500.0,
      totalEarnings: 50000.0,
      callsToday: 12,
      totalCalls: 450,
      isOnline: true,
      totalSessions: 300,
      averageSessionDuration: 25.5,
      averageRating: 4.8,
      todayCount: 12,
    );

    blocTest<DashboardBloc, DashboardState>(
      'emits [DashboardLoading, DashboardLoadedState] on success',
      build: () {
        when(mockRepository.getDashboardStats())
            .thenAnswer((_) async => mockStats);
        return dashboardBloc;
      },
      act: (bloc) => bloc.add(LoadDashboardStatsEvent()),
      expect: () => [
        isA<DashboardLoading>(),
        isA<DashboardLoadedState>()
            .having((state) => state.stats, 'stats', mockStats)
            .having((state) => state.stats.todayEarnings, 'todayEarnings', 1500.0),
      ],
      verify: (_) {
        verify(mockRepository.getDashboardStats()).called(1);
      },
    );

    blocTest<DashboardBloc, DashboardState>(
      'emits [DashboardLoading, DashboardErrorState] on error',
      build: () {
        when(mockRepository.getDashboardStats())
            .thenThrow(Exception('Failed to load stats'));
        return dashboardBloc;
      },
      act: (bloc) => bloc.add(LoadDashboardStatsEvent()),
      expect: () => [
        isA<DashboardLoading>(),
        isA<DashboardErrorState>(),
      ],
    );
  });

  group('DashboardBloc - UpdateOnlineStatusEvent', () {
    blocTest<DashboardBloc, DashboardState>(
      'updates online status successfully',
      build: () {
        when(mockRepository.updateOnlineStatus(true))
            .thenAnswer((_) async => true);
        return dashboardBloc;
      },
      seed: () => DashboardLoadedState(DashboardStatsModel(
        todayEarnings: 1500.0,
        totalEarnings: 50000.0,
        isOnline: false,
        // ... other fields
      )),
      act: (bloc) => bloc.add(UpdateOnlineStatusEvent(true)),
      expect: () => [
        isA<DashboardLoadedState>()
            .having((state) => state.stats.isOnline, 'isOnline', true),
        isA<StatusUpdatedState>()
            .having((state) => state.isOnline, 'isOnline', true),
      ],
    );
  });
}
```

---

## 📝 Example 4: Integration Test

```dart
// test/integration/auth_flow_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:astrologer_app/features/auth/bloc/auth_bloc.dart';
import 'package:astrologer_app/data/repositories/auth/auth_repository_impl.dart';
import 'package:astrologer_app/core/services/api_service.dart';
import 'package:astrologer_app/core/services/storage_service.dart';

void main() {
  group('Complete Auth Flow Integration Test', () {
    late AuthBloc authBloc;
    late AuthRepositoryImpl repository;
    late ApiService apiService;
    late StorageService storageService;

    setUp(() async {
      // Initialize real services (or test doubles)
      storageService = StorageService();
      await storageService.initialize();
      
      apiService = ApiService();
      await apiService.initialize();
      
      repository = AuthRepositoryImpl(
        apiService: apiService,
        storageService: storageService,
      );
      
      authBloc = AuthBloc(repository: repository);
    });

    tearDown(() async {
      await authBloc.close();
      await storageService.clearAuthData();
    });

    test('Complete login flow: check phone → send OTP → verify OTP', () async {
      // 1. Check if phone exists
      authBloc.add(CheckPhoneExistsEvent('+919876543210'));
      await expectLater(
        authBloc.stream,
        emitsInOrder([
          isA<AuthLoading>(),
          isA<PhoneCheckedState>(),
        ]),
      );

      // 2. Send OTP
      authBloc.add(SendOtpEvent('+919876543210'));
      await expectLater(
        authBloc.stream,
        emitsInOrder([
          isA<AuthLoading>(),
          isA<OtpSentState>(),
        ]),
      );

      // 3. Verify OTP
      authBloc.add(VerifyOtpEvent(
        phoneNumber: '+919876543210',
        otp: '123456',
      ));
      await expectLater(
        authBloc.stream,
        emitsInOrder([
          isA<AuthLoading>(),
          isA<AuthSuccessState>(),
        ]),
      );

      // Verify auth data is stored
      final token = await storageService.getAuthToken();
      expect(token, isNotNull);
      expect(token, isNotEmpty);
    });
  });
}
```

---

## 🏃 Running Tests

### Run All Tests
```bash
flutter test
```

### Run Specific Test File
```bash
flutter test test/unit/blocs/auth_bloc_test.dart
```

### Run Tests with Coverage
```bash
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html
```

### Generate Mocks
```bash
flutter pub run build_runner build
```

---

## 📊 Test Coverage Goals

| Layer | Target Coverage | Priority |
|-------|----------------|----------|
| **Repositories** | 90%+ | High |
| **BLoCs** | 95%+ | High |
| **Models** | 80%+ | Medium |
| **Widgets** | 70%+ | Medium |
| **Integration** | 60%+ | Medium |

---

## ✅ Testing Checklist

### Before Committing
- [ ] All unit tests pass
- [ ] No failing tests
- [ ] Coverage above 80%
- [ ] No skipped tests
- [ ] Integration tests pass

### Test Quality
- [ ] Tests are deterministic
- [ ] Tests are isolated
- [ ] Tests are fast
- [ ] Tests have clear names
- [ ] Tests test one thing

---

## 🎯 Best Practices

### DO ✅
- Test one thing per test
- Use descriptive test names
- Arrange-Act-Assert pattern
- Mock external dependencies
- Test error cases
- Use bloc_test for BLoC testing

### DON'T ❌
- Test implementation details
- Write flaky tests
- Skip error case testing
- Test multiple things in one test
- Forget to clean up resources

---

## 📚 Additional Resources

- [BLoC Testing Documentation](https://bloclibrary.dev/#/testing)
- [Mockito Documentation](https://pub.dev/packages/mockito)
- [Flutter Testing Guide](https://docs.flutter.dev/testing)
- [bloc_test Package](https://pub.dev/packages/bloc_test)

---

**Last Updated:** [Current Date]  
**Version:** 1.0  
**Status:** ✅ Complete


