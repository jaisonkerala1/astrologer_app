import 'package:equatable/equatable.dart';

/// Wakelock States
abstract class WakelockState extends Equatable {
  const WakelockState();

  @override
  List<Object?> get props => [];
}

/// Initial state (wakelock disabled)
class WakelockInitial extends WakelockState {
  const WakelockInitial();
}

/// Wakelock enabled (screen will stay awake)
class WakelockEnabled extends WakelockState {
  final int activeSessions;

  const WakelockEnabled({this.activeSessions = 1});

  @override
  List<Object?> get props => [activeSessions];
}

/// Wakelock disabled (screen can sleep)
class WakelockDisabled extends WakelockState {
  const WakelockDisabled();
}

/// Wakelock temporarily disabled (app paused)
class WakelockPaused extends WakelockState {
  final bool wasEnabledBeforePause;

  const WakelockPaused({required this.wasEnabledBeforePause});

  @override
  List<Object?> get props => [wasEnabledBeforePause];
}

/// Error state
class WakelockError extends WakelockState {
  final String message;

  const WakelockError(this.message);

  @override
  List<Object?> get props => [message];
}

