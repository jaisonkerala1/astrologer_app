import '../models/help_article.dart';

/// Service for help and support functionality
class HelpSupportService {
  static const String _baseUrl = 'https://your-api-url.com/api/help-support';

  /// Get all help articles
  Future<List<HelpArticle>> getHelpArticles() async {
    // Simulate API call with mock data
    await Future.delayed(const Duration(milliseconds: 500));
    
    return _getMockHelpArticles();
  }

  /// Get help articles by category
  Future<List<HelpArticle>> getHelpArticlesByCategory(String category) async {
    await Future.delayed(const Duration(milliseconds: 300));
    
    final allArticles = _getMockHelpArticles();
    return allArticles.where((article) => article.category == category).toList();
  }

  /// Search help articles
  Future<List<HelpArticle>> searchHelpArticles(String query) async {
    await Future.delayed(const Duration(milliseconds: 400));
    
    final allArticles = _getMockHelpArticles();
    final lowercaseQuery = query.toLowerCase();
    
    return allArticles.where((article) {
      return article.title.toLowerCase().contains(lowercaseQuery) ||
             article.content.toLowerCase().contains(lowercaseQuery) ||
             article.tags.any((tag) => tag.toLowerCase().contains(lowercaseQuery));
    }).toList();
  }

  /// Get all FAQ items
  Future<List<FAQItem>> getFAQItems() async {
    await Future.delayed(const Duration(milliseconds: 300));
    
    return _getMockFAQItems();
  }

  /// Get FAQ items by category
  Future<List<FAQItem>> getFAQItemsByCategory(String category) async {
    await Future.delayed(const Duration(milliseconds: 200));
    
    final allFAQ = _getMockFAQItems();
    return allFAQ.where((faq) => faq.category == category).toList();
  }

  /// Search FAQ items
  Future<List<FAQItem>> searchFAQItems(String query) async {
    await Future.delayed(const Duration(milliseconds: 300));
    
    final allFAQ = _getMockFAQItems();
    final lowercaseQuery = query.toLowerCase();
    
    return allFAQ.where((faq) {
      return faq.question.toLowerCase().contains(lowercaseQuery) ||
             faq.answer.toLowerCase().contains(lowercaseQuery);
    }).toList();
  }

  /// Create support ticket
  Future<SupportTicket> createSupportTicket({
    required String title,
    required String description,
    required String category,
    required String priority,
    required String userId,
  }) async {
    await Future.delayed(const Duration(milliseconds: 800));
    
    final ticket = SupportTicket(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      description: description,
      category: category,
      priority: priority,
      status: 'open',
      userId: userId,
      createdAt: DateTime.now(),
    );
    
    // In real implementation, save to API
    return ticket;
  }

  /// Get user's support tickets
  Future<List<SupportTicket>> getUserTickets(String userId) async {
    await Future.delayed(const Duration(milliseconds: 400));
    
    return _getMockUserTickets(userId);
  }

  /// Add message to ticket
  Future<TicketMessage> addTicketMessage({
    required String ticketId,
    required String message,
    required String senderId,
    required String senderName,
    required String senderType,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));
    
    final ticketMessage = TicketMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      ticketId: ticketId,
      message: message,
      senderId: senderId,
      senderName: senderName,
      senderType: senderType,
      createdAt: DateTime.now(),
    );
    
    // In real implementation, save to API
    return ticketMessage;
  }

  /// Get help categories
  List<String> getHelpCategories() {
    return [
      'Getting Started',
      'Account & Profile',
      'Calendar & Scheduling',
      'Consultations',
      'Payments',
      'Technical Issues',
      'General',
    ];
  }

  /// Get FAQ categories
  List<String> getFAQCategories() {
    return [
      'General',
      'Account',
      'Calendar',
      'Consultations',
      'Payments',
      'Technical',
    ];
  }

  /// Get ticket categories
  List<String> getTicketCategories() {
    return [
      'Account Issues',
      'Calendar Problems',
      'Consultation Issues',
      'Payment Problems',
      'Technical Support',
      'Feature Request',
      'Bug Report',
      'Other',
    ];
  }

  /// Get priority levels
  List<String> getPriorityLevels() {
    return ['Low', 'Medium', 'High', 'Urgent'];
  }

  /// Mock data for help articles
  List<HelpArticle> _getMockHelpArticles() {
    return [
      HelpArticle(
        id: '1',
        title: 'Getting Started with Astrologer App',
        content: 'Welcome to the Astrologer App! This guide will help you get started with all the essential features...',
        category: 'Getting Started',
        tags: ['beginner', 'setup', 'tutorial'],
        createdAt: DateTime.now().subtract(const Duration(days: 30)),
        updatedAt: DateTime.now().subtract(const Duration(days: 5)),
        isPopular: true,
        viewCount: 1250,
      ),
      HelpArticle(
        id: '2',
        title: 'How to Schedule Consultations',
        content: 'Learn how to schedule and manage your consultations with clients...',
        category: 'Calendar & Scheduling',
        tags: ['calendar', 'scheduling', 'consultations'],
        createdAt: DateTime.now().subtract(const Duration(days: 25)),
        updatedAt: DateTime.now().subtract(const Duration(days: 10)),
        isPopular: true,
        viewCount: 980,
      ),
      HelpArticle(
        id: '3',
        title: 'Managing Your Profile',
        content: 'Complete guide to setting up and managing your astrologer profile...',
        category: 'Account & Profile',
        tags: ['profile', 'account', 'settings'],
        createdAt: DateTime.now().subtract(const Duration(days: 20)),
        updatedAt: DateTime.now().subtract(const Duration(days: 3)),
        isPopular: false,
        viewCount: 450,
      ),
      HelpArticle(
        id: '4',
        title: 'Payment and Billing',
        content: 'Everything you need to know about payments, billing, and earnings...',
        category: 'Payments',
        tags: ['payment', 'billing', 'earnings'],
        createdAt: DateTime.now().subtract(const Duration(days: 15)),
        updatedAt: DateTime.now().subtract(const Duration(days: 1)),
        isPopular: true,
        viewCount: 750,
      ),
      HelpArticle(
        id: '5',
        title: 'Troubleshooting Common Issues',
        content: 'Solutions to common technical problems and issues...',
        category: 'Technical Issues',
        tags: ['troubleshooting', 'technical', 'problems'],
        createdAt: DateTime.now().subtract(const Duration(days: 10)),
        updatedAt: DateTime.now().subtract(const Duration(days: 2)),
        isPopular: false,
        viewCount: 320,
      ),
    ];
  }

  /// Mock data for FAQ items
  List<FAQItem> _getMockFAQItems() {
    return [
      FAQItem(
        id: '1',
        question: 'How do I create my astrologer profile?',
        answer: 'To create your profile, go to the Profile section and fill in your details including your specializations, experience, and bio.',
        category: 'Account',
        helpfulCount: 45,
        notHelpfulCount: 2,
      ),
      FAQItem(
        id: '2',
        question: 'How can I schedule consultations?',
        answer: 'Navigate to the Calendar section, select your available time slots, and set your consultation preferences.',
        category: 'Calendar',
        helpfulCount: 38,
        notHelpfulCount: 1,
      ),
      FAQItem(
        id: '3',
        question: 'What payment methods are accepted?',
        answer: 'We accept all major credit cards, UPI, net banking, and digital wallets for payments.',
        category: 'Payments',
        helpfulCount: 52,
        notHelpfulCount: 3,
      ),
      FAQItem(
        id: '4',
        question: 'How do I manage my availability?',
        answer: 'Go to Calendar > Availability to set your working hours and days. You can also block specific dates.',
        category: 'Calendar',
        helpfulCount: 29,
        notHelpfulCount: 1,
      ),
      FAQItem(
        id: '5',
        question: 'Can I reschedule a consultation?',
        answer: 'Yes, you can reschedule consultations up to 2 hours before the scheduled time from the Calendar section.',
        category: 'Consultations',
        helpfulCount: 41,
        notHelpfulCount: 2,
      ),
      FAQItem(
        id: '6',
        question: 'How do I contact support?',
        answer: 'You can contact support through the Help & Support section in your profile, or create a support ticket.',
        category: 'General',
        helpfulCount: 33,
        notHelpfulCount: 0,
      ),
    ];
  }

  /// Mock data for user tickets
  List<SupportTicket> _getMockUserTickets(String userId) {
    return [
      SupportTicket(
        id: '1',
        title: 'Calendar not syncing properly',
        description: 'My calendar is not showing the correct availability times.',
        category: 'Technical Support',
        priority: 'Medium',
        status: 'open',
        userId: userId,
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
        messages: [
          TicketMessage(
            id: '1',
            ticketId: '1',
            message: 'My calendar is not showing the correct availability times.',
            senderId: userId,
            senderName: 'You',
            senderType: 'user',
            createdAt: DateTime.now().subtract(const Duration(days: 2)),
          ),
        ],
      ),
      SupportTicket(
        id: '2',
        title: 'Payment issue with consultation',
        description: 'I was charged twice for the same consultation.',
        category: 'Payment Problems',
        priority: 'High',
        status: 'in_progress',
        userId: userId,
        assignedTo: 'support_agent_1',
        createdAt: DateTime.now().subtract(const Duration(days: 5)),
        updatedAt: DateTime.now().subtract(const Duration(hours: 2)),
        messages: [
          TicketMessage(
            id: '1',
            ticketId: '2',
            message: 'I was charged twice for the same consultation.',
            senderId: userId,
            senderName: 'You',
            senderType: 'user',
            createdAt: DateTime.now().subtract(const Duration(days: 5)),
          ),
          TicketMessage(
            id: '2',
            ticketId: '2',
            message: 'We are looking into this issue and will resolve it within 24 hours.',
            senderId: 'support_agent_1',
            senderName: 'Support Team',
            senderType: 'support',
            createdAt: DateTime.now().subtract(const Duration(hours: 2)),
          ),
        ],
      ),
    ];
  }
}


