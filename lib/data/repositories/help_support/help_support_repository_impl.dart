import 'dart:convert';
import '../../../core/services/api_service.dart';
import '../../../core/services/storage_service.dart';
import '../../../features/help_support/models/help_article.dart';
import '../base_repository.dart';
import 'help_support_repository.dart';

class HelpSupportRepositoryImpl extends BaseRepository implements HelpSupportRepository {
  final ApiService apiService;
  final StorageService storageService;

  HelpSupportRepositoryImpl({
    required this.apiService,
    required this.storageService,
  });

  @override
  Future<List<HelpArticle>> getHelpArticles() async {
    try {
      final response = await apiService.get('/api/help-support/articles');
      if (response.data['success'] == true) {
        final List<dynamic> data = response.data['data'] ?? [];
        return data.map((json) => HelpArticle.fromJson(json)).toList();
      }
      throw Exception('Failed to load help articles');
    } catch (e) {
      throw Exception(handleError(e));
    }
  }

  @override
  Future<List<HelpArticle>> getHelpArticlesByCategory(String category) async {
    try {
      final response = await apiService.get('/api/help-support/articles', queryParameters: {'category': category});
      if (response.data['success'] == true) {
        final List<dynamic> data = response.data['data'] ?? [];
        return data.map((json) => HelpArticle.fromJson(json)).toList();
      }
      throw Exception('Failed to load help articles');
    } catch (e) {
      throw Exception(handleError(e));
    }
  }

  @override
  Future<List<HelpArticle>> searchHelpArticles(String query) async {
    try {
      final response = await apiService.get('/api/help-support/articles/search', queryParameters: {'q': query});
      if (response.data['success'] == true) {
        final List<dynamic> data = response.data['data'] ?? [];
        return data.map((json) => HelpArticle.fromJson(json)).toList();
      }
      throw Exception('Failed to search help articles');
    } catch (e) {
      throw Exception(handleError(e));
    }
  }

  @override
  Future<HelpArticle> getHelpArticleById(String id) async {
    try {
      final response = await apiService.get('/api/help-support/articles/$id');
      if (response.data['success'] == true) {
        return HelpArticle.fromJson(response.data['data']);
      }
      throw Exception('Failed to load help article');
    } catch (e) {
      throw Exception(handleError(e));
    }
  }

  @override
  Future<List<FAQItem>> getFAQItems() async {
    try {
      final response = await apiService.get('/api/help-support/faq');
      if (response.data['success'] == true) {
        final List<dynamic> data = response.data['data'] ?? [];
        return data.map((json) => FAQItem.fromJson(json)).toList();
      }
      throw Exception('Failed to load FAQ items');
    } catch (e) {
      throw Exception(handleError(e));
    }
  }

  @override
  Future<List<FAQItem>> getFAQItemsByCategory(String category) async {
    try {
      final response = await apiService.get('/api/help-support/faq', queryParameters: {'category': category});
      if (response.data['success'] == true) {
        final List<dynamic> data = response.data['data'] ?? [];
        return data.map((json) => FAQItem.fromJson(json)).toList();
      }
      throw Exception('Failed to load FAQ items');
    } catch (e) {
      throw Exception(handleError(e));
    }
  }

  @override
  Future<List<FAQItem>> searchFAQItems(String query) async {
    try {
      final response = await apiService.get('/api/help-support/faq/search', queryParameters: {'q': query});
      if (response.data['success'] == true) {
        final List<dynamic> data = response.data['data'] ?? [];
        return data.map((json) => FAQItem.fromJson(json)).toList();
      }
      throw Exception('Failed to search FAQ items');
    } catch (e) {
      throw Exception(handleError(e));
    }
  }

  @override
  Future<void> markFAQHelpful(String id, bool isHelpful) async {
    try {
      final response = await apiService.post('/api/help-support/faq/$id/feedback', data: {'helpful': isHelpful});
      if (response.data['success'] != true) {
        throw Exception('Failed to submit feedback');
      }
    } catch (e) {
      throw Exception(handleError(e));
    }
  }

  @override
  Future<List<SupportTicket>> getUserTickets(String userId) async {
    try {
      final response = await apiService.get('/api/help-support/tickets', queryParameters: {'userId': userId});
      if (response.data['success'] == true) {
        final List<dynamic> data = response.data['data'] ?? [];
        return data.map((json) => SupportTicket.fromJson(json)).toList();
      }
      throw Exception('Failed to load support tickets');
    } catch (e) {
      throw Exception(handleError(e));
    }
  }

  @override
  Future<SupportTicket> getTicketById(String id) async {
    try {
      final response = await apiService.get('/api/help-support/tickets/$id');
      if (response.data['success'] == true) {
        return SupportTicket.fromJson(response.data['data']);
      }
      throw Exception('Failed to load support ticket');
    } catch (e) {
      throw Exception(handleError(e));
    }
  }

  @override
  Future<SupportTicket> createSupportTicket({
    required String title,
    required String description,
    required String category,
    required String priority,
  }) async {
    try {
      final userId = await _getUserId();
      final response = await apiService.post('/api/help-support/tickets', data: {
        'title': title,
        'description': description,
        'category': category,
        'priority': priority,
        'userId': userId,
      });
      if (response.data['success'] == true) {
        return SupportTicket.fromJson(response.data['data']);
      }
      throw Exception('Failed to create support ticket');
    } catch (e) {
      throw Exception(handleError(e));
    }
  }

  @override
  Future<TicketMessage> addTicketMessage({
    required String ticketId,
    required String message,
  }) async {
    try {
      final userId = await _getUserId();
      final userName = await _getUserName();
      final response = await apiService.post('/api/help-support/tickets/$ticketId/messages', data: {
        'message': message,
        'senderId': userId,
        'senderName': userName,
        'senderType': 'user',
      });
      if (response.data['success'] == true) {
        return TicketMessage.fromJson(response.data['data']);
      }
      throw Exception('Failed to add ticket message');
    } catch (e) {
      throw Exception(handleError(e));
    }
  }

  @override
  Future<void> closeTicket(String id) async {
    try {
      final response = await apiService.patch('/api/help-support/tickets/$id/close');
      if (response.data['success'] != true) {
        throw Exception('Failed to close ticket');
      }
    } catch (e) {
      throw Exception(handleError(e));
    }
  }

  @override
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

  @override
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

  @override
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

  @override
  List<String> getPriorityLevels() {
    return ['Low', 'Medium', 'High', 'Urgent'];
  }

  Future<String> _getUserId() async {
    final userData = await storageService.getUserData();
    if (userData != null) {
      final userDataMap = jsonDecode(userData);
      return userDataMap['id'] ?? userDataMap['_id'] ?? '';
    }
    throw Exception('User ID not found');
  }

  Future<String> _getUserName() async {
    final userData = await storageService.getUserData();
    if (userData != null) {
      final userDataMap = jsonDecode(userData);
      return userDataMap['name'] ?? '';
    }
    return 'User';
  }
}


