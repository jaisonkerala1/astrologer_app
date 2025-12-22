import 'package:bloc_test/bloc_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:astrologer_app/features/auth/bloc/auth_bloc.dart';
import 'package:astrologer_app/features/auth/bloc/auth_event.dart';
import 'package:astrologer_app/features/auth/bloc/auth_state.dart';
import 'package:astrologer_app/data/repositories/auth/auth_repository.dart';
import 'package:astrologer_app/core/services/api_service.dart';

// Mock Repositories
class MockAuthRepository extends Mock implements AuthRepository {}

// Mock Services
class MockApiService extends Mock implements ApiService {}

// Mock Bloc
class MockAuthBloc extends MockBloc<AuthEvent, AuthState> implements AuthBloc {}






























































