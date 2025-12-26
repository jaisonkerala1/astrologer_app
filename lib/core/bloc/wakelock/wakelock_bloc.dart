import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/services/wakelock_service.dart';
import 'wakelock_event.dart';
import 'wakelock_state.dart';

/// Reusable Wakelock BLoC
/// Manages screen wake state for live streaming, video calls, etc.
class WakelockBloc extends Bloc<WakelockEvent, WakelockState> {
  final WakelockService _wakelockService;

  WakelockBloc({WakelockService? wakelockService})
      : _wakelockService = wakelockService ?? WakelockService(),
        super(const WakelockInitial()) {
    on<EnableWakelockEvent>(_onEnableWakelock);
    on<DisableWakelockEvent>(_onDisableWakelock);
    on<ForceDisableWakelockEvent>(_onForceDisableWakelock);
    on<AppPausedEvent>(_onAppPaused);
    on<AppResumedEvent>(_onAppResumed);
  }

  Future<void> _onEnableWakelock(
    EnableWakelockEvent event,
    Emitter<WakelockState> emit,
  ) async {
    try {
      print('🔋 [WAKELOCK BLOC] Enabling wakelock...');
      final success = await _wakelockService.enable();
      if (success) {
        print('✅ [WAKELOCK BLOC] Wakelock enabled (sessions: ${_wakelockService.activeSessions})');
        emit(WakelockEnabled(
          activeSessions: _wakelockService.activeSessions,
        ));
      } else {
        print('❌ [WAKELOCK BLOC] Failed to enable wakelock');
        emit(WakelockError('Failed to enable wakelock'));
      }
    } catch (e) {
      print('❌ [WAKELOCK BLOC] Error enabling wakelock: $e');
      emit(WakelockError('Error enabling wakelock: ${e.toString()}'));
    }
  }

  Future<void> _onDisableWakelock(
    DisableWakelockEvent event,
    Emitter<WakelockState> emit,
  ) async {
    try {
      print('🔋 [WAKELOCK BLOC] Disabling wakelock...');
      final success = await _wakelockService.disable();
      if (success) {
        if (_wakelockService.activeSessions <= 0) {
          print('✅ [WAKELOCK BLOC] Wakelock disabled (no active sessions)');
          emit(const WakelockDisabled());
        } else {
          // Still has active sessions, keep enabled
          print('ℹ️ [WAKELOCK BLOC] Wakelock still active (sessions: ${_wakelockService.activeSessions})');
          emit(WakelockEnabled(
            activeSessions: _wakelockService.activeSessions,
          ));
        }
      } else {
        print('❌ [WAKELOCK BLOC] Failed to disable wakelock');
        emit(WakelockError('Failed to disable wakelock'));
      }
    } catch (e) {
      print('❌ [WAKELOCK BLOC] Error disabling wakelock: $e');
      emit(WakelockError('Error disabling wakelock: ${e.toString()}'));
    }
  }

  Future<void> _onForceDisableWakelock(
    ForceDisableWakelockEvent event,
    Emitter<WakelockState> emit,
  ) async {
    try {
      await _wakelockService.forceDisable();
      emit(const WakelockDisabled());
    } catch (e) {
      emit(WakelockError('Error force disabling wakelock: ${e.toString()}'));
    }
  }

  Future<void> _onAppPaused(
    AppPausedEvent event,
    Emitter<WakelockState> emit,
  ) async {
    final wasEnabled = state is WakelockEnabled;
    
    // Temporarily disable to save battery
    try {
      print('⏸️ [WAKELOCK BLOC] App paused - disabling wakelock (was enabled: $wasEnabled)');
      await _wakelockService.forceDisable();
      emit(WakelockPaused(wasEnabledBeforePause: wasEnabled));
    } catch (e) {
      print('❌ [WAKELOCK BLOC] Error pausing wakelock: $e');
      emit(WakelockError('Error pausing wakelock: ${e.toString()}'));
    }
  }

  Future<void> _onAppResumed(
    AppResumedEvent event,
    Emitter<WakelockState> emit,
  ) async {
    if (state is WakelockPaused) {
      final pausedState = state as WakelockPaused;
      
      // Re-enable if it was enabled before pause and shouldReEnable is true
      if (pausedState.wasEnabledBeforePause && event.shouldReEnable) {
        print('▶️ [WAKELOCK BLOC] App resumed - re-enabling wakelock');
        add(const EnableWakelockEvent());
      } else {
        print('▶️ [WAKELOCK BLOC] App resumed - keeping wakelock disabled');
        emit(const WakelockDisabled());
      }
    }
  }

  @override
  Future<void> close() {
    // Ensure wakelock is disabled when BLoC is closed
    _wakelockService.forceDisable();
    return super.close();
  }
}

