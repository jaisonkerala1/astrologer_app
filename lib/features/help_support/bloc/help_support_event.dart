import 'package:equatable/equatable.dart';

abstract class HelpSupportEvent extends Equatable {
  const HelpSupportEvent();

  @override
  List<Object?> get props => [];
}

// Help Articles Events
class LoadHelpArticlesEvent extends HelpSupportEvent {
  const LoadHelpArticlesEvent();
}

class LoadHelpArticlesByCategoryEvent extends HelpSupportEvent {
  final String category;
  const LoadHelpArticlesByCategoryEvent(this.category);
  @override
  List<Object?> get props => [category];
}

class SearchHelpArticlesEvent extends HelpSupportEvent {
  final String query;
  const SearchHelpArticlesEvent(this.query);
  @override
  List<Object?> get props => [query];
}

class LoadHelpArticleDetailEvent extends HelpSupportEvent {
  final String id;
  const LoadHelpArticleDetailEvent(this.id);
  @override
  List<Object?> get props => [id];
}

// FAQ Events
class LoadFAQItemsEvent extends HelpSupportEvent {
  const LoadFAQItemsEvent();
}

class LoadFAQItemsByCategoryEvent extends HelpSupportEvent {
  final String category;
  const LoadFAQItemsByCategoryEvent(this.category);
  @override
  List<Object?> get props => [category];
}

class SearchFAQItemsEvent extends HelpSupportEvent {
  final String query;
  const SearchFAQItemsEvent(this.query);
  @override
  List<Object?> get props => [query];
}

class MarkFAQHelpfulEvent extends HelpSupportEvent {
  final String id;
  final bool isHelpful;
  const MarkFAQHelpfulEvent(this.id, this.isHelpful);
  @override
  List<Object?> get props => [id, isHelpful];
}

// Support Tickets Events
class LoadUserTicketsEvent extends HelpSupportEvent {
  const LoadUserTicketsEvent();
}

class LoadTicketDetailEvent extends HelpSupportEvent {
  final String id;
  const LoadTicketDetailEvent(this.id);
  @override
  List<Object?> get props => [id];
}

class CreateSupportTicketEvent extends HelpSupportEvent {
  final String title;
  final String description;
  final String category;
  final String priority;
  
  const CreateSupportTicketEvent({
    required this.title,
    required this.description,
    required this.category,
    required this.priority,
  });
  
  @override
  List<Object?> get props => [title, description, category, priority];
}

class AddTicketMessageEvent extends HelpSupportEvent {
  final String ticketId;
  final String message;
  
  const AddTicketMessageEvent({
    required this.ticketId,
    required this.message,
  });
  
  @override
  List<Object?> get props => [ticketId, message];
}

class CloseTicketEvent extends HelpSupportEvent {
  final String id;
  const CloseTicketEvent(this.id);
  @override
  List<Object?> get props => [id];
}

class RefreshHelpSupportEvent extends HelpSupportEvent {
  const RefreshHelpSupportEvent();
}


