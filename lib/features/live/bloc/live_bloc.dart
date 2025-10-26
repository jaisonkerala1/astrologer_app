import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/repositories/live/live_repository.dart';
import 'live_event.dart';
import 'live_state.dart';

class LiveBloc extends Bloc<LiveEvent, LiveState> {
  final LiveRepository repository;

  LiveBloc({required this.repository}) : super(const LiveInitial()) {
    on<StartLiveStreamEvent>(_onStartLiveStream);
    on<EndLiveStreamEvent>(_onEndLiveStream);
    on<UpdateStreamInfoEvent>(_onUpdateStreamInfo);
    on<LoadLiveStreamsEvent>(_onLoadLiveStreams);
    on<LoadStreamByIdEvent>(_onLoadStreamById);
    on<JoinStreamEvent>(_onJoinStream);
    on<LeaveStreamEvent>(_onLeaveStream);
    on<LoadStreamCommentsEvent>(_onLoadStreamComments);
    on<SendCommentEvent>(_onSendComment);
    on<SendGiftEvent>(_onSendGift);
    on<SendReactionEvent>(_onSendReaction);
    on<LoadStreamAnalyticsEvent>(_onLoadStreamAnalytics);
    on<RefreshLiveEvent>(_onRefresh);
  }

  Future<void> _onStartLiveStream(StartLiveStreamEvent event, Emitter<LiveState> emit) async {
    emit(const StreamStarting());
    try {
      final stream = await repository.startLiveStream(
        title: event.title,
        description: event.description,
        category: event.category,
        tags: event.tags,
      );
      emit(LiveLoadedState(
        streams: [stream],
        activeStream: stream,
        isBroadcasting: true,
        successMessage: 'Live stream started successfully',
      ));
    } catch (e) {
      emit(LiveErrorState(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onEndLiveStream(EndLiveStreamEvent event, Emitter<LiveState> emit) async {
    emit(StreamEnding(event.streamId));
    try {
      final stream = await repository.endLiveStream(event.streamId);
      if (state is LiveLoadedState) {
        final currentState = state as LiveLoadedState;
        emit(currentState.copyWith(
          activeStream: stream,
          isBroadcasting: false,
          successMessage: 'Live stream ended',
          clearActiveStream: true,
        ));
      }
    } catch (e) {
      emit(LiveErrorState(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onUpdateStreamInfo(UpdateStreamInfoEvent event, Emitter<LiveState> emit) async {
    try {
      final stream = await repository.updateStreamInfo(
        event.streamId,
        title: event.title,
        description: event.description,
      );
      if (state is LiveLoadedState) {
        final currentState = state as LiveLoadedState;
        emit(currentState.copyWith(
          activeStream: stream,
          successMessage: 'Stream info updated',
        ));
      }
    } catch (e) {
      emit(LiveErrorState(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onLoadLiveStreams(LoadLiveStreamsEvent event, Emitter<LiveState> emit) async {
    emit(const LiveLoading());
    try {
      final streams = await repository.getLiveStreams(
        category: event.category,
        search: event.search,
      );
      emit(LiveLoadedState(streams: streams));
    } catch (e) {
      emit(LiveErrorState(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onLoadStreamById(LoadStreamByIdEvent event, Emitter<LiveState> emit) async {
    try {
      final stream = await repository.getStreamById(event.id);
      if (state is LiveLoadedState) {
        final currentState = state as LiveLoadedState;
        emit(currentState.copyWith(activeStream: stream));
      } else {
        emit(LiveLoadedState(streams: [stream], activeStream: stream));
      }
    } catch (e) {
      emit(LiveErrorState(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onJoinStream(JoinStreamEvent event, Emitter<LiveState> emit) async {
    emit(StreamJoining(event.streamId));
    try {
      final stream = await repository.joinStream(event.streamId);
      final comments = await repository.getStreamComments(event.streamId);
      
      if (state is LiveLoadedState) {
        final currentState = state as LiveLoadedState;
        emit(currentState.copyWith(
          activeStream: stream,
          comments: comments,
          successMessage: 'Joined stream',
        ));
      } else {
        emit(LiveLoadedState(
          streams: [stream],
          activeStream: stream,
          comments: comments,
        ));
      }
    } catch (e) {
      emit(LiveErrorState(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onLeaveStream(LeaveStreamEvent event, Emitter<LiveState> emit) async {
    try {
      await repository.leaveStream(event.streamId);
      if (state is LiveLoadedState) {
        final currentState = state as LiveLoadedState;
        emit(currentState.copyWith(
          clearActiveStream: true,
          comments: [],
        ));
      }
    } catch (e) {
      emit(LiveErrorState(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onLoadStreamComments(LoadStreamCommentsEvent event, Emitter<LiveState> emit) async {
    try {
      final comments = await repository.getStreamComments(event.streamId);
      if (state is LiveLoadedState) {
        final currentState = state as LiveLoadedState;
        emit(currentState.copyWith(comments: comments));
      }
    } catch (e) {
      print('Error loading comments: $e');
    }
  }

  Future<void> _onSendComment(SendCommentEvent event, Emitter<LiveState> emit) async {
    emit(CommentSending(event.streamId));
    try {
      final comment = await repository.sendComment(event.streamId, event.message);
      if (state is LiveLoadedState) {
        final currentState = state as LiveLoadedState;
        final updatedComments = List.of(currentState.comments)..add(comment);
        emit(currentState.copyWith(comments: updatedComments));
      }
    } catch (e) {
      emit(LiveErrorState(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onSendGift(SendGiftEvent event, Emitter<LiveState> emit) async {
    try {
      await repository.sendGift(event.streamId, event.giftName, event.giftValue);
      add(LoadStreamCommentsEvent(event.streamId));
    } catch (e) {
      emit(LiveErrorState(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onSendReaction(SendReactionEvent event, Emitter<LiveState> emit) async {
    try {
      await repository.sendReaction(event.streamId, event.emoji);
      // Reactions are typically fire-and-forget, no state update needed
    } catch (e) {
      print('Error sending reaction: $e');
    }
  }

  Future<void> _onLoadStreamAnalytics(LoadStreamAnalyticsEvent event, Emitter<LiveState> emit) async {
    try {
      final analytics = await repository.getStreamAnalytics(event.streamId);
      if (state is LiveLoadedState) {
        final currentState = state as LiveLoadedState;
        emit(currentState.copyWith(analytics: analytics));
      }
    } catch (e) {
      print('Error loading analytics: $e');
    }
  }

  Future<void> _onRefresh(RefreshLiveEvent event, Emitter<LiveState> emit) async {
    add(const LoadLiveStreamsEvent());
  }
}


