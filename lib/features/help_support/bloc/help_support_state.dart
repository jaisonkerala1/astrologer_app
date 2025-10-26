import 'package:equatable/equatable.dart';
import '../models/help_article.dart';

abstract class HelpSupportState extends Equatable {
  const HelpSupportState();
  
  @override
  List<Object?> get props => [];
}

class HelpSupportInitial extends HelpSupportState {
  const HelpSupportInitial();
}

class HelpSupportLoading extends HelpSupportState {
  final bool isInitialLoad;
  const HelpSupportLoading({this.isInitialLoad = true});
  @override
  List<Object?> get props => [isInitialLoad];
}

class HelpSupportLoadedState extends HelpSupportState {
  final List<HelpArticle> helpArticles;
  final List<FAQItem> faqItems;
  final List<SupportTicket> tickets;
  final HelpArticle? selectedArticle;
  final SupportTicket? selectedTicket;
  final String? successMessage;
  final String? searchQuery;

  HelpSupportLoadedState({
    required this.helpArticles,
    required this.faqItems,
    required this.tickets,
    this.selectedArticle,
    this.selectedTicket,
    this.successMessage,
    this.searchQuery,
  });

  @override
  List<Object?> get props => [
    helpArticles,
    faqItems,
    tickets,
    selectedArticle,
    selectedTicket,
    successMessage,
    searchQuery,
  ];

  HelpSupportLoadedState copyWith({
    List<HelpArticle>? helpArticles,
    List<FAQItem>? faqItems,
    List<SupportTicket>? tickets,
    HelpArticle? selectedArticle,
    SupportTicket? selectedTicket,
    String? successMessage,
    String? searchQuery,
    bool clearSelectedArticle = false,
    bool clearSelectedTicket = false,
  }) {
    return HelpSupportLoadedState(
      helpArticles: helpArticles ?? this.helpArticles,
      faqItems: faqItems ?? this.faqItems,
      tickets: tickets ?? this.tickets,
      selectedArticle: clearSelectedArticle ? null : (selectedArticle ?? this.selectedArticle),
      selectedTicket: clearSelectedTicket ? null : (selectedTicket ?? this.selectedTicket),
      successMessage: successMessage,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }

  // Helpers
  List<HelpArticle> get popularArticles =>
      helpArticles.where((a) => a.isPopular).toList();
  
  List<SupportTicket> get openTickets =>
      tickets.where((t) => t.status == 'open').toList();
  
  List<SupportTicket> get closedTickets =>
      tickets.where((t) => t.status == 'closed').toList();
  
  int get totalArticles => helpArticles.length;
  int get totalFAQs => faqItems.length;
  int get totalTickets => tickets.length;
}

class HelpSupportErrorState extends HelpSupportState {
  final String message;
  const HelpSupportErrorState(this.message);
  @override
  List<Object?> get props => [message];
}

class TicketCreating extends HelpSupportState {
  const TicketCreating();
}

class MessageSending extends HelpSupportState {
  final String ticketId;
  const MessageSending(this.ticketId);
  @override
  List<Object?> get props => [ticketId];
}

class ArticleLoading extends HelpSupportState {
  final String articleId;
  const ArticleLoading(this.articleId);
  @override
  List<Object?> get props => [articleId];
}


