import '../../../features/help_support/models/help_article.dart';

/// Abstract interface for Help & Support operations
abstract class HelpSupportRepository {
  // Help Articles
  Future<List<HelpArticle>> getHelpArticles();
  Future<List<HelpArticle>> getHelpArticlesByCategory(String category);
  Future<List<HelpArticle>> searchHelpArticles(String query);
  Future<HelpArticle> getHelpArticleById(String id);
  
  // FAQ
  Future<List<FAQItem>> getFAQItems();
  Future<List<FAQItem>> getFAQItemsByCategory(String category);
  Future<List<FAQItem>> searchFAQItems(String query);
  Future<void> markFAQHelpful(String id, bool isHelpful);
  
  // Support Tickets
  Future<List<SupportTicket>> getUserTickets(String userId);
  Future<SupportTicket> getTicketById(String id);
  Future<SupportTicket> createSupportTicket({
    required String title,
    required String description,
    required String category,
    required String priority,
  });
  Future<TicketMessage> addTicketMessage({
    required String ticketId,
    required String message,
  });
  Future<void> closeTicket(String id);
  
  // Categories
  List<String> getHelpCategories();
  List<String> getFAQCategories();
  List<String> getTicketCategories();
  List<String> getPriorityLevels();
}


