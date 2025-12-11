import 'package:equatable/equatable.dart';
import '../models/live_stream_model.dart';

abstract class LiveEvent extends Equatable {
  const LiveEvent();

  @override
  List<Object?> get props => [];
}

// Broadcasting Events
class StartLiveStreamEvent extends LiveEvent {
  final String title;
  final String description;
  final LiveStreamCategory category;
  final List<String> tags;

  const StartLiveStreamEvent({
    required this.title,
    required this.description,
    required this.category,
    required this.tags,
  });

  @override
  List<Object?> get props => [title, description, category, tags];
}

class EndLiveStreamEvent extends LiveEvent {
  final String streamId;
  const EndLiveStreamEvent(this.streamId);
  @override
  List<Object?> get props => [streamId];
}

class UpdateStreamInfoEvent extends LiveEvent {
  final String streamId;
  final String? title;
  final String? description;

  const UpdateStreamInfoEvent(this.streamId, {this.title, this.description});
  @override
  List<Object?> get props => [streamId, title, description];
}

// Viewing Events
class LoadLiveStreamsEvent extends LiveEvent {
  final LiveStreamCategory? category;
  final String? search;

  const LoadLiveStreamsEvent({this.category, this.search});
  @override
  List<Object?> get props => [category, search];
}

class LoadStreamByIdEvent extends LiveEvent {
  final String id;
  const LoadStreamByIdEvent(this.id);
  @override
  List<Object?> get props => [id];
}

class JoinStreamEvent extends LiveEvent {
  final String streamId;
  const JoinStreamEvent(this.streamId);
  @override
  List<Object?> get props => [streamId];
}

class LeaveStreamEvent extends LiveEvent {
  final String streamId;
  const LeaveStreamEvent(this.streamId);
  @override
  List<Object?> get props => [streamId];
}

// Interaction Events
class LoadStreamCommentsEvent extends LiveEvent {
  final String streamId;
  const LoadStreamCommentsEvent(this.streamId);
  @override
  List<Object?> get props => [streamId];
}

class SendCommentEvent extends LiveEvent {
  final String streamId;
  final String message;

  const SendCommentEvent(this.streamId, this.message);
  @override
  List<Object?> get props => [streamId, message];
}

class SendGiftEvent extends LiveEvent {
  final String streamId;
  final String giftName;
  final int giftValue;

  const SendGiftEvent(this.streamId, this.giftName, this.giftValue);
  @override
  List<Object?> get props => [streamId, giftName, giftValue];
}

class SendReactionEvent extends LiveEvent {
  final String streamId;
  final String emoji;

  const SendReactionEvent(this.streamId, this.emoji);
  @override
  List<Object?> get props => [streamId, emoji];
}

// Analytics Events
class LoadStreamAnalyticsEvent extends LiveEvent {
  final String streamId;
  const LoadStreamAnalyticsEvent(this.streamId);
  @override
  List<Object?> get props => [streamId];
}

class RefreshLiveEvent extends LiveEvent {
  const RefreshLiveEvent();
}

// Audio Level Event
class AudioLevelUpdatedEvent extends LiveEvent {
  final double level; // 0.0 to 1.0
  
  const AudioLevelUpdatedEvent(this.level);
  
  @override
  List<Object?> get props => [level];
}


