import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/repositories/help_support/help_support_repository.dart';
import 'help_support_event.dart';
import 'help_support_state.dart';

class HelpSupportBloc extends Bloc<HelpSupportEvent, HelpSupportState> {
  final HelpSupportRepository repository;

  HelpSupportBloc({required this.repository}) : super(const HelpSupportInitial()) {
    on<LoadHelpArticlesEvent>(_onLoadHelpArticles);
    on<LoadHelpArticlesByCategoryEvent>(_onLoadHelpArticlesByCategory);
    on<SearchHelpArticlesEvent>(_onSearchHelpArticles);
    on<LoadHelpArticleDetailEvent>(_onLoadHelpArticleDetail);
    on<LoadFAQItemsEvent>(_onLoadFAQItems);
    on<LoadFAQItemsByCategoryEvent>(_onLoadFAQItemsByCategory);
    on<SearchFAQItemsEvent>(_onSearchFAQItems);
    on<MarkFAQHelpfulEvent>(_onMarkFAQHelpful);
    on<LoadUserTicketsEvent>(_onLoadUserTickets);
    on<LoadTicketDetailEvent>(_onLoadTicketDetail);
    on<CreateSupportTicketEvent>(_onCreateSupportTicket);
    on<AddTicketMessageEvent>(_onAddTicketMessage);
    on<CloseTicketEvent>(_onCloseTicket);
    on<RefreshHelpSupportEvent>(_onRefresh);
  }

  Future<void> _onLoadHelpArticles(LoadHelpArticlesEvent event, Emitter<HelpSupportState> emit) async {
    emit(const HelpSupportLoading());
    try {
      final articles = await repository.getHelpArticles();
      final faqs = await repository.getFAQItems();
      emit(HelpSupportLoadedState(
        helpArticles: articles,
        faqItems: faqs,
        tickets: [],
      ));
    } catch (e) {
      emit(HelpSupportErrorState(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onLoadHelpArticlesByCategory(
    LoadHelpArticlesByCategoryEvent event,
    Emitter<HelpSupportState> emit,
  ) async {
    try {
      final articles = await repository.getHelpArticlesByCategory(event.category);
      if (state is HelpSupportLoadedState) {
        final currentState = state as HelpSupportLoadedState;
        emit(currentState.copyWith(helpArticles: articles));
      }
    } catch (e) {
      emit(HelpSupportErrorState(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onSearchHelpArticles(
    SearchHelpArticlesEvent event,
    Emitter<HelpSupportState> emit,
  ) async {
    try {
      final articles = await repository.searchHelpArticles(event.query);
      if (state is HelpSupportLoadedState) {
        final currentState = state as HelpSupportLoadedState;
        emit(currentState.copyWith(
          helpArticles: articles,
          searchQuery: event.query,
        ));
      }
    } catch (e) {
      emit(HelpSupportErrorState(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onLoadHelpArticleDetail(
    LoadHelpArticleDetailEvent event,
    Emitter<HelpSupportState> emit,
  ) async {
    emit(ArticleLoading(event.id));
    try {
      final article = await repository.getHelpArticleById(event.id);
      if (state is HelpSupportLoadedState) {
        final currentState = state as HelpSupportLoadedState;
        emit(currentState.copyWith(selectedArticle: article));
      }
    } catch (e) {
      emit(HelpSupportErrorState(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onLoadFAQItems(LoadFAQItemsEvent event, Emitter<HelpSupportState> emit) async {
    try {
      final faqs = await repository.getFAQItems();
      if (state is HelpSupportLoadedState) {
        final currentState = state as HelpSupportLoadedState;
        emit(currentState.copyWith(faqItems: faqs));
      }
    } catch (e) {
      emit(HelpSupportErrorState(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onLoadFAQItemsByCategory(
    LoadFAQItemsByCategoryEvent event,
    Emitter<HelpSupportState> emit,
  ) async {
    try {
      final faqs = await repository.getFAQItemsByCategory(event.category);
      if (state is HelpSupportLoadedState) {
        final currentState = state as HelpSupportLoadedState;
        emit(currentState.copyWith(faqItems: faqs));
      }
    } catch (e) {
      emit(HelpSupportErrorState(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onSearchFAQItems(SearchFAQItemsEvent event, Emitter<HelpSupportState> emit) async {
    try {
      final faqs = await repository.searchFAQItems(event.query);
      if (state is HelpSupportLoadedState) {
        final currentState = state as HelpSupportLoadedState;
        emit(currentState.copyWith(
          faqItems: faqs,
          searchQuery: event.query,
        ));
      }
    } catch (e) {
      emit(HelpSupportErrorState(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onMarkFAQHelpful(MarkFAQHelpfulEvent event, Emitter<HelpSupportState> emit) async {
    try {
      await repository.markFAQHelpful(event.id, event.isHelpful);
    } catch (e) {
      print('Error marking FAQ helpful: $e');
    }
  }

  Future<void> _onLoadUserTickets(LoadUserTicketsEvent event, Emitter<HelpSupportState> emit) async {
    try {
      final tickets = await repository.getUserTickets('current_user'); // Will be replaced with actual user ID
      if (state is HelpSupportLoadedState) {
        final currentState = state as HelpSupportLoadedState;
        emit(currentState.copyWith(tickets: tickets));
      } else {
        emit(HelpSupportLoadedState(
          helpArticles: [],
          faqItems: [],
          tickets: tickets,
        ));
      }
    } catch (e) {
      emit(HelpSupportErrorState(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onLoadTicketDetail(LoadTicketDetailEvent event, Emitter<HelpSupportState> emit) async {
    try {
      final ticket = await repository.getTicketById(event.id);
      if (state is HelpSupportLoadedState) {
        final currentState = state as HelpSupportLoadedState;
        emit(currentState.copyWith(selectedTicket: ticket));
      }
    } catch (e) {
      emit(HelpSupportErrorState(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onCreateSupportTicket(
    CreateSupportTicketEvent event,
    Emitter<HelpSupportState> emit,
  ) async {
    emit(const TicketCreating());
    try {
      final ticket = await repository.createSupportTicket(
        title: event.title,
        description: event.description,
        category: event.category,
        priority: event.priority,
      );
      if (state is HelpSupportLoadedState) {
        final currentState = state as HelpSupportLoadedState;
        final updatedTickets = List.of(currentState.tickets)..add(ticket);
        emit(currentState.copyWith(
          tickets: updatedTickets,
          successMessage: 'Support ticket created successfully',
        ));
      }
    } catch (e) {
      emit(HelpSupportErrorState(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onAddTicketMessage(
    AddTicketMessageEvent event,
    Emitter<HelpSupportState> emit,
  ) async {
    emit(MessageSending(event.ticketId));
    try {
      final message = await repository.addTicketMessage(
        ticketId: event.ticketId,
        message: event.message,
      );
      
      // Reload ticket to get updated messages
      add(LoadTicketDetailEvent(event.ticketId));
    } catch (e) {
      emit(HelpSupportErrorState(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onCloseTicket(CloseTicketEvent event, Emitter<HelpSupportState> emit) async {
    try {
      await repository.closeTicket(event.id);
      add(const LoadUserTicketsEvent());
    } catch (e) {
      emit(HelpSupportErrorState(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onRefresh(RefreshHelpSupportEvent event, Emitter<HelpSupportState> emit) async {
    add(const LoadHelpArticlesEvent());
  }
}


