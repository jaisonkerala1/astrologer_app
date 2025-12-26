import 'package:equatable/equatable.dart';

/// Wakelock Events
abstract class WakelockEvent extends Equatable {
  const WakelockEvent();

  @override
  List<Object?> get props => [];
}

/// Enable wakelock (e.g., when starting live stream)
class EnableWakelockEvent extends WakelockEvent {
  const EnableWakelockEvent();
}

/// Disable wakelock (e.g., when ending live stream)
class DisableWakelockEvent extends WakelockEvent {
  const DisableWakelockEvent();
}

/// Force disable wakelock (e.g., when app goes to background)
class ForceDisableWakelockEvent extends WakelockEvent {
  const ForceDisableWakelockEvent();
}

/// App lifecycle events
class AppPausedEvent extends WakelockEvent {
  const AppPausedEvent();
}

class AppResumedEvent extends WakelockEvent {
  final bool shouldReEnable; // Whether to re-enable if was active before pause

  const AppResumedEvent({this.shouldReEnable = true});
  
  @override
  List<Object?> get props => [shouldReEnable];
}

