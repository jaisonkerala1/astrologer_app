import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/repositories/help_support/help_support_repository.dart';
import '../models/help_article.dart';
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
    // Preserve existing tickets if state is already loaded
    final existingTickets = state is HelpSupportLoadedState 
        ? (state as HelpSupportLoadedState).tickets 
        : <SupportTicket>[];
    
    print('🔍 [HelpSupportBloc] Loading articles, preserving ${existingTickets.length} existing tickets');
    
    emit(const HelpSupportLoading());
    try {
      final articles = await repository.getHelpArticles();
      final faqs = await repository.getFAQItems();
      
      print('✅ [HelpSupportBloc] Articles loaded, emitting state with ${existingTickets.length} tickets');
      
      emit(HelpSupportLoadedState(
        helpArticles: articles,
        faqItems: faqs,
        tickets: existingTickets, // PRESERVE existing tickets!
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
    print('🎫 [HelpSupportBloc] LoadUserTicketsEvent triggered');
    print('🔍 [HelpSupportBloc] BLoC instance: ${hashCode}');
    print('🔍 [HelpSupportBloc] Repository instance: ${repository.hashCode}');
    try {
      final tickets = await repository.getUserTickets('current_user'); // Will be replaced with actual user ID
      print('✅ [HelpSupportBloc] Got ${tickets.length} tickets from repository');
      for (var i = 0; i < tickets.length; i++) {
        print('   🎫 Ticket $i: ${tickets[i].id} - ${tickets[i].title} - ${tickets[i].status}');
      }
      if (state is HelpSupportLoadedState) {
        final currentState = state as HelpSupportLoadedState;
        print('🔍 [HelpSupportBloc] Updating existing LoadedState with ${tickets.length} tickets');
        emit(currentState.copyWith(tickets: tickets));
      } else {
        print('🔍 [HelpSupportBloc] Creating new LoadedState with ${tickets.length} tickets');
        emit(HelpSupportLoadedState(
          helpArticles: [],
          faqItems: [],
          tickets: tickets,
        ));
      }
    } catch (e) {
      print('❌ [HelpSupportBloc] Error loading tickets: $e');
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
    // Store current state before emitting TicketCreating
    final previousState = state is HelpSupportLoadedState ? state as HelpSupportLoadedState : null;
    
    emit(const TicketCreating());
    
    try {
      print('🎫 [HelpSupportBloc] Creating ticket: ${event.title}');
      final ticket = await repository.createSupportTicket(
        title: event.title,
        description: event.description,
        category: event.category,
        priority: event.priority,
      );
      
      print('✅ [HelpSupportBloc] Ticket created successfully: ${ticket.id}');
      
      // Use previous state to emit updated state with new ticket
      if (previousState != null) {
        final updatedTickets = List<SupportTicket>.from(previousState.tickets)..add(ticket);
        emit(previousState.copyWith(
          tickets: updatedTickets,
          successMessage: 'Support ticket created successfully',
        ));
      } else {
        // Fallback: Create new loaded state with just the new ticket
        emit(HelpSupportLoadedState(
          helpArticles: [],
          faqItems: [],
          tickets: [ticket],
          successMessage: 'Support ticket created successfully',
        ));
      }
    } catch (e) {
      print('❌ [HelpSupportBloc] Error creating ticket: $e');
      
      // Emit back to previous state with error message, don't lose data
      if (previousState != null) {
        emit(previousState.copyWith(
          successMessage: null,
        ));
        // Emit error state briefly, then go back to loaded state
        emit(HelpSupportErrorState(e.toString().replaceAll('Exception: ', '')));
        await Future.delayed(const Duration(milliseconds: 100));
        emit(previousState);
      } else {
        emit(HelpSupportErrorState(e.toString().replaceAll('Exception: ', '')));
      }
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
    print('🔄 [HelpSupportBloc] Refreshing all help & support data');
    // Reload all data (articles, FAQs, and tickets)
    add(const LoadHelpArticlesEvent());
    add(const LoadUserTicketsEvent());
  }
}


