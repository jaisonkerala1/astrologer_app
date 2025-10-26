import 'package:equatable/equatable.dart';
import '../models/live_stream_model.dart';
import '../models/live_comment_model.dart';
import '../models/live_gift_model.dart';
import '../models/live_reaction_model.dart';

abstract class LiveState extends Equatable {
  const LiveState();
  
  @override
  List<Object?> get props => [];
}

class LiveInitial extends LiveState {
  const LiveInitial();
}

class LiveLoading extends LiveState {
  final bool isInitialLoad;
  const LiveLoading({this.isInitialLoad = true});
  @override
  List<Object?> get props => [isInitialLoad];
}

class LiveLoadedState extends LiveState {
  final List<LiveStreamModel> streams;
  final LiveStreamModel? activeStream; // Current broadcasting or viewing stream
  final List<LiveCommentModel> comments;
  final Map<String, dynamic>? analytics;
  final String? successMessage;
  final bool isBroadcasting; // True if user is broadcasting

  const LiveLoadedState({
    required this.streams,
    this.activeStream,
    this.comments = const [],
    this.analytics,
    this.successMessage,
    this.isBroadcasting = false,
  });

  @override
  List<Object?> get props => [
    streams,
    activeStream,
    comments,
    analytics,
    successMessage,
    isBroadcasting,
  ];

  LiveLoadedState copyWith({
    List<LiveStreamModel>? streams,
    LiveStreamModel? activeStream,
    List<LiveCommentModel>? comments,
    Map<String, dynamic>? analytics,
    String? successMessage,
    bool? isBroadcasting,
    bool clearActiveStream = false,
  }) {
    return LiveLoadedState(
      streams: streams ?? this.streams,
      activeStream: clearActiveStream ? null : (activeStream ?? this.activeStream),
      comments: comments ?? this.comments,
      analytics: analytics ?? this.analytics,
      successMessage: successMessage,
      isBroadcasting: isBroadcasting ?? this.isBroadcasting,
    );
  }

  // Helpers
  List<LiveStreamModel> get liveStreams =>
      streams.where((s) => s.isLive).toList();
  
  List<LiveStreamModel> streamsByCategory(LiveStreamCategory category) =>
      streams.where((s) => s.category == category && s.isLive).toList();
  
  int get totalViewers => activeStream?.viewerCount ?? 0;
  int get totalComments => comments.length;
  int get totalLikes => activeStream?.likes ?? 0;
}

class LiveErrorState extends LiveState {
  final String message;
  const LiveErrorState(this.message);
  @override
  List<Object?> get props => [message];
}

class StreamStarting extends LiveState {
  const StreamStarting();
}

class StreamEnding extends LiveState {
  final String streamId;
  const StreamEnding(this.streamId);
  @override
  List<Object?> get props => [streamId];
}

class StreamJoining extends LiveState {
  final String streamId;
  const StreamJoining(this.streamId);
  @override
  List<Object?> get props => [streamId];
}

class CommentSending extends LiveState {
  final String streamId;
  const CommentSending(this.streamId);
  @override
  List<Object?> get props => [streamId];
}

