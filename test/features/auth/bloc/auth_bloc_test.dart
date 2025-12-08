import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:astrologer_app/features/auth/bloc/auth_bloc.dart';
import 'package:astrologer_app/features/auth/bloc/auth_event.dart';
import 'package:astrologer_app/features/auth/bloc/auth_state.dart';
import '../../../mocks.dart';

void main() {
  late AuthBloc authBloc;
  late MockAuthRepository mockAuthRepository;

  setUp(() {
    mockAuthRepository = MockAuthRepository();
    // We can't easily mock the internal ApiService singleton without refactoring,
    // so we focus on testing the interactions with the injected AuthRepository.
    authBloc = AuthBloc(repository: mockAuthRepository);
  });

  tearDown(() {
    authBloc.close();
  });

  group('AuthBloc', () {
    test('initial state is AuthInitial', () {
      expect(authBloc.state, isA<AuthInitial>());
    });

    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, PhoneCheckedState] when CheckPhoneExistsEvent is added and succeeds',
      build: () {
        when(() => mockAuthRepository.checkPhoneExists(any()))
            .thenAnswer((_) async => {'exists': true, 'message': 'User exists'});
        return authBloc;
      },
      act: (bloc) => bloc.add(CheckPhoneExistsEvent('1234567890')),
      expect: () => [
        isA<AuthLoading>(),
        isA<PhoneCheckedState>()
            .having((s) => s.exists, 'exists', true)
            .having((s) => s.phoneNumber, 'phoneNumber', '1234567890'),
      ],
      verify: (_) {
        verify(() => mockAuthRepository.checkPhoneExists('1234567890')).called(1);
      },
    );

    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, AuthErrorState] when CheckPhoneExistsEvent fails',
      build: () {
        when(() => mockAuthRepository.checkPhoneExists(any()))
            .thenThrow(Exception('Network Error'));
        return authBloc;
      },
      act: (bloc) => bloc.add(CheckPhoneExistsEvent('1234567890')),
      expect: () => [
        isA<AuthLoading>(),
        isA<AuthErrorState>().having((s) => s.message, 'message', contains('Network Error')),
      ],
    );
  });
}

