import 'package:get_it/get_it.dart';
import '../../core/services/api_service.dart';
import '../../core/services/storage_service.dart';
import '../../core/services/socket_service.dart';
import '../../data/repositories/auth/auth_repository.dart';
import '../../data/repositories/auth/auth_repository_impl.dart';
import '../../data/repositories/dashboard/dashboard_repository.dart';
import '../../data/repositories/dashboard/dashboard_repository_impl.dart';
import '../../data/repositories/consultations/consultations_repository.dart';
import '../../data/repositories/consultations/consultations_repository_impl.dart';
import '../../data/repositories/profile/profile_repository.dart';
import '../../data/repositories/profile/profile_repository_impl.dart';
import '../../data/repositories/calendar/calendar_repository.dart';
import '../../data/repositories/calendar/calendar_repository_impl.dart';
import '../../data/repositories/earnings/earnings_repository.dart';
import '../../data/repositories/earnings/earnings_repository_impl.dart';
import '../../data/repositories/communication/communication_repository.dart';
import '../../data/repositories/communication/communication_repository_impl.dart';
import '../../data/repositories/heal/heal_repository.dart';
import '../../data/repositories/heal/heal_repository_impl.dart';
import '../../data/repositories/help_support/help_support_repository.dart';
import '../../data/repositories/help_support/help_support_repository_impl.dart';
import '../../data/repositories/live/live_repository.dart';
import '../../data/repositories/live/live_repository_impl.dart';
import '../../data/repositories/notifications/notifications_repository.dart';
import '../../data/repositories/notifications/notifications_repository_impl.dart';
import '../../data/repositories/clients/clients_repository.dart';
import '../../data/repositories/clients/clients_repository_impl.dart';
import '../../features/auth/bloc/auth_bloc.dart';
import '../../features/dashboard/bloc/dashboard_bloc.dart';
import '../../features/consultations/bloc/consultations_bloc.dart';
import '../../features/profile/bloc/profile_bloc.dart';
import '../../features/calendar/bloc/calendar_bloc.dart';
import '../../features/earnings/bloc/earnings_bloc.dart';
import '../../features/communication/bloc/communication_bloc.dart';
import '../../features/communication/bloc/call_bloc.dart';
import '../../features/heal/bloc/heal_bloc.dart';
import '../../features/help_support/bloc/help_support_bloc.dart';
import '../../features/live/bloc/live_bloc.dart';
import '../../features/live/bloc/live_comment_bloc.dart';
import '../../features/notifications/bloc/notifications_bloc.dart';
import '../../features/clients/bloc/clients_bloc.dart';
import '../../features/reviews/repository/reviews_repository.dart';
import '../../features/reviews/bloc/reviews_bloc.dart';
import '../../features/heal/bloc/discussion_bloc.dart';
import '../../features/heal/services/discussion_api_service.dart';

/// Service Locator for Dependency Injection
/// Using GetIt for service registration and retrieval
final getIt = GetIt.instance;

/// Setup all dependencies
/// Call this once in main.dart before runApp()
Future<void> setupServiceLocator() async {
  // ============================================================================
  // CORE SERVICES (Singletons)
  // ============================================================================
  
  // Storage Service - needs to be initialized first
  final storageService = StorageService();
  await storageService.initialize();
  getIt.registerLazySingleton<StorageService>(() => storageService);
  
  // API Service
  final apiService = ApiService();
  await apiService.initialize();
  getIt.registerLazySingleton<ApiService>(() => apiService);
  
  // Socket Service (Real-time WebSocket)
  final socketService = SocketService();
  getIt.registerLazySingleton<SocketService>(() => socketService);

  // ============================================================================
  // REPOSITORIES (Singletons)
  // ============================================================================
  
  // Auth Repository
  getIt.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(
      apiService: getIt<ApiService>(),
      storageService: getIt<StorageService>(),
    ),
  );
  
  // Dashboard Repository
  getIt.registerLazySingleton<DashboardRepository>(
    () => DashboardRepositoryImpl(
      apiService: getIt<ApiService>(),
      storageService: getIt<StorageService>(),
    ),
  );
  
  // Consultations Repository
  getIt.registerLazySingleton<ConsultationsRepository>(
    () => ConsultationsRepositoryImpl(
      apiService: getIt<ApiService>(),
      storageService: getIt<StorageService>(),
    ),
  );
  
  // Profile Repository
  getIt.registerLazySingleton<ProfileRepository>(
    () => ProfileRepositoryImpl(
      apiService: getIt<ApiService>(),
      storageService: getIt<StorageService>(),
    ),
  );
  
  // Reviews Repository (already existed)
  getIt.registerLazySingleton<ReviewsRepository>(
    () => ReviewsRepository(
      apiService: getIt<ApiService>(),
      storageService: getIt<StorageService>(),
    ),
  );
  
  // Calendar Repository
  getIt.registerLazySingleton<CalendarRepository>(
    () => CalendarRepositoryImpl(
      apiService: getIt<ApiService>(),
      storageService: getIt<StorageService>(),
    ),
  );
  
  // Earnings Repository
  getIt.registerLazySingleton<EarningsRepository>(
    () => EarningsRepositoryImpl(
      apiService: getIt<ApiService>(),
      storageService: getIt<StorageService>(),
    ),
  );
  
  // Communication Repository
  getIt.registerLazySingleton<CommunicationRepository>(
    () => CommunicationRepositoryImpl(
      apiService: getIt<ApiService>(),
      storageService: getIt<StorageService>(),
    ),
  );
  
  // Heal Repository
  getIt.registerLazySingleton<HealRepository>(
    () => HealRepositoryImpl(
      apiService: getIt<ApiService>(),
      storageService: getIt<StorageService>(),
    ),
  );
  
  // Help & Support Repository
  getIt.registerLazySingleton<HelpSupportRepository>(
    () => HelpSupportRepositoryImpl(
      apiService: getIt<ApiService>(),
      storageService: getIt<StorageService>(),
    ),
  );
  
  // Live Repository
  getIt.registerLazySingleton<LiveRepository>(
    () => LiveRepositoryImpl(
      apiService: getIt<ApiService>(),
      storageService: getIt<StorageService>(),
    ),
  );
  
  // Notifications Repository
  getIt.registerLazySingleton<NotificationsRepository>(
    () => NotificationsRepositoryImpl(
      apiService: getIt<ApiService>(),
      storageService: getIt<StorageService>(),
    ),
  );
  
  // Clients Repository
  getIt.registerLazySingleton<ClientsRepository>(
    () => ClientsRepositoryImpl(
      apiService: getIt<ApiService>(),
      storageService: getIt<StorageService>(),
    ),
  );

  // ============================================================================
  // BLoCs (Factories - new instance each time)
  // ============================================================================
  
  // Auth BLoC
  getIt.registerFactory<AuthBloc>(
    () => AuthBloc(repository: getIt<AuthRepository>()),
  );
  
  // Dashboard BLoC
  getIt.registerFactory<DashboardBloc>(
    () => DashboardBloc(repository: getIt<DashboardRepository>()),
  );
  
  // Consultations BLoC
  getIt.registerFactory<ConsultationsBloc>(
    () => ConsultationsBloc(repository: getIt<ConsultationsRepository>()),
  );
  
  // Profile BLoC
  getIt.registerFactory<ProfileBloc>(
    () => ProfileBloc(repository: getIt<ProfileRepository>()),
  );
  
  // Reviews BLoC
  getIt.registerFactory<ReviewsBloc>(
    () => ReviewsBloc(reviewsRepository: getIt<ReviewsRepository>()),
  );
  
  // Calendar BLoC
  getIt.registerFactory<CalendarBloc>(
    () => CalendarBloc(repository: getIt<CalendarRepository>()),
  );
  
  // Earnings BLoC
  getIt.registerFactory<EarningsBloc>(
    () => EarningsBloc(repository: getIt<EarningsRepository>()),
  );
  
  // Communication BLoC
  getIt.registerFactory<CommunicationBloc>(
    () => CommunicationBloc(
      repository: getIt<CommunicationRepository>(),
      socketService: getIt<SocketService>(),
    ),
  );

  // Call BLoC (Singleton - global call state)
  getIt.registerLazySingleton<CallBloc>(
    () => CallBloc(socketService: getIt<SocketService>()),
  );
  
  // Heal BLoC (Singleton to preserve state across navigation)
  getIt.registerLazySingleton<HealBloc>(
    () => HealBloc(
      repository: getIt<HealRepository>(),
      socketService: getIt<SocketService>(),
    ),
  );
  
  // Help & Support BLoC
  getIt.registerFactory<HelpSupportBloc>(
    () => HelpSupportBloc(repository: getIt<HelpSupportRepository>()),
  );
  
  // Live BLoC
  getIt.registerFactory<LiveBloc>(
    () => LiveBloc(repository: getIt<LiveRepository>()),
  );
  
  // Live Comment BLoC
  getIt.registerFactory<LiveCommentBloc>(
    () => LiveCommentBloc(
      socketService: getIt<SocketService>(),
      liveRepository: getIt<LiveRepository>(),
    ),
  );
  
  // Notifications BLoC
  getIt.registerFactory<NotificationsBloc>(
    () => NotificationsBloc(repository: getIt<NotificationsRepository>()),
  );
  
  // Clients BLoC
  getIt.registerFactory<ClientsBloc>(
    () => ClientsBloc(repository: getIt<ClientsRepository>()),
  );
  
  // Discussion API Service
  getIt.registerLazySingleton<DiscussionApiService>(
    () => DiscussionApiService(apiService: getIt<ApiService>()),
  );
  
  // Discussion BLoC
  getIt.registerFactory<DiscussionBloc>(
    () => DiscussionBloc(
      apiService: getIt<DiscussionApiService>(),
      socketService: getIt<SocketService>(),
    ),
  );

  print('✅ Service Locator: All dependencies registered successfully');
  print('   - Core Services: API, Storage, Socket (Real-time)');
  print('   - 14 Repositories/Services: Auth, Dashboard, Consultations, Profile, Reviews, Calendar, Earnings, Communication, Heal, HelpSupport, Live, Notifications, Clients, Discussion');
  print('   - 15 BLoCs: Auth, Dashboard, Consultations, Profile, Reviews, Calendar, Earnings, Communication, Heal, HelpSupport, Live, LiveComment, Notifications, Clients, Discussion');
}

/// Reset service locator (useful for testing)
Future<void> resetServiceLocator() async {
  await getIt.reset();
}

