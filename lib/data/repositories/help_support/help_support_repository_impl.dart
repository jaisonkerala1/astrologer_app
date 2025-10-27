import 'dart:convert';
import '../../../core/services/api_service.dart';
import '../../../core/services/storage_service.dart';
import '../../../features/help_support/models/help_article.dart';
import '../base_repository.dart';
import 'help_support_repository.dart';

class HelpSupportRepositoryImpl extends BaseRepository implements HelpSupportRepository {
  final ApiService apiService;
  final StorageService storageService;
  
  // In-memory storage for locally created tickets (not persisted to backend)
  final List<SupportTicket> _localTickets = [];

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
      print('⚠️ [HelpSupportRepo] API not available, using dummy data: $e');
      return _generateDummyArticles();
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
      print('⚠️ [HelpSupportRepo] API not available, filtering dummy data by category: $category');
      final allArticles = _generateDummyArticles();
      return allArticles.where((article) => article.category == category).toList();
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
      print('⚠️ [HelpSupportRepo] API not available, searching dummy data for: $query');
      final allArticles = _generateDummyArticles();
      final lowercaseQuery = query.toLowerCase();
      return allArticles.where((article) {
        return article.title.toLowerCase().contains(lowercaseQuery) ||
               article.content.toLowerCase().contains(lowercaseQuery) ||
               article.tags.any((tag) => tag.toLowerCase().contains(lowercaseQuery));
      }).toList();
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
      print('⚠️ [HelpSupportRepo] API not available, finding dummy article by id: $id');
      final allArticles = _generateDummyArticles();
      final article = allArticles.firstWhere(
        (a) => a.id == id,
        orElse: () => allArticles.first,
      );
      return article;
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
      print('⚠️ [HelpSupportRepo] API not available, using dummy FAQ data: $e');
      return _generateDummyFAQs();
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
      print('⚠️ [HelpSupportRepo] API not available, filtering dummy FAQ by category: $category');
      final allFAQs = _generateDummyFAQs();
      return allFAQs.where((faq) => faq.category == category).toList();
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
      print('⚠️ [HelpSupportRepo] API not available, searching dummy FAQ for: $query');
      final allFAQs = _generateDummyFAQs();
      final lowercaseQuery = query.toLowerCase();
      return allFAQs.where((faq) {
        return faq.question.toLowerCase().contains(lowercaseQuery) ||
               faq.answer.toLowerCase().contains(lowercaseQuery);
      }).toList();
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
      print('⚠️ [HelpSupportRepo] API not available, marking FAQ locally (not persisted): $id');
      // Just log - can't persist without backend
    }
  }

  @override
  Future<List<SupportTicket>> getUserTickets(String userId) async {
    print('🔍 [HelpSupportRepo] getUserTickets called for userId: $userId');
    print('🔍 [HelpSupportRepo] Repository instance: ${hashCode}');
    print('🔍 [HelpSupportRepo] Current _localTickets count: ${_localTickets.length}');
    
    try {
      final response = await apiService.get('/api/help-support/tickets', queryParameters: {'userId': userId});
      if (response.data['success'] == true) {
        final List<dynamic> data = response.data['data'] ?? [];
        final apiTickets = data.map((json) => SupportTicket.fromJson(json)).toList();
        print('✅ [HelpSupportRepo] Got ${apiTickets.length} tickets from API');
        print('🔍 [HelpSupportRepo] Merging with ${_localTickets.length} local tickets');
        // Merge with locally created tickets
        final mergedTickets = [..._localTickets, ...apiTickets];
        print('✅ [HelpSupportRepo] Returning ${mergedTickets.length} total tickets');
        return mergedTickets;
      }
      throw Exception('Failed to load support tickets');
    } catch (e) {
      print('⚠️ [HelpSupportRepo] API not available, using dummy tickets + local tickets: $e');
      print('🔍 [HelpSupportRepo] _localTickets count: ${_localTickets.length}');
      for (var i = 0; i < _localTickets.length; i++) {
        print('   📝 Local ticket $i: ${_localTickets[i].id} - ${_localTickets[i].title}');
      }
      final dummyTickets = _generateDummyTickets(userId);
      print('🔍 [HelpSupportRepo] Generated ${dummyTickets.length} dummy tickets');
      // Merge local tickets with dummy tickets (local tickets first so they appear at the top)
      final mergedTickets = [..._localTickets, ...dummyTickets];
      print('✅ [HelpSupportRepo] Returning ${mergedTickets.length} total tickets (${_localTickets.length} local + ${dummyTickets.length} dummy)');
      return mergedTickets;
    }
  }

  @override
  Future<SupportTicket> getTicketById(String id) async {
    // Check local tickets first
    final localTicket = _localTickets.cast<SupportTicket?>().firstWhere(
      (t) => t?.id == id,
      orElse: () => null,
    );
    if (localTicket != null) {
      print('📝 [HelpSupportRepo] Found ticket in local storage: $id');
      return localTicket;
    }
    
    try {
      final response = await apiService.get('/api/help-support/tickets/$id');
      if (response.data['success'] == true) {
        return SupportTicket.fromJson(response.data['data']);
      }
      throw Exception('Failed to load support ticket');
    } catch (e) {
      print('⚠️ [HelpSupportRepo] API not available, finding dummy ticket by id: $id');
      final userId = await _getUserId().catchError((_) => 'dummy_user');
      final allTickets = _generateDummyTickets(userId);
      return allTickets.firstWhere(
        (t) => t.id == id,
        orElse: () => allTickets.first,
      );
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
      print('⚠️ [HelpSupportRepo] API not available, creating local ticket (stored in memory): $e');
      print('🔍 [HelpSupportRepo] Repository instance: ${hashCode}');
      final userId = await _getUserId().catchError((_) => 'dummy_user');
      // Create a local ticket and store it in memory
      final localTicket = SupportTicket(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: title,
        description: description,
        category: category,
        priority: priority,
        status: 'open',
        userId: userId,
        createdAt: DateTime.now(),
        messages: [], // Empty messages list for new ticket
        attachments: [], // Empty attachments list
      );
      
      print('🔍 [HelpSupportRepo] _localTickets BEFORE add: ${_localTickets.length}');
      // Store in memory so it persists across refreshes
      _localTickets.add(localTicket);
      print('📝 [HelpSupportRepo] Stored local ticket in memory.');
      print('🔍 [HelpSupportRepo] _localTickets AFTER add: ${_localTickets.length}');
      print('🔍 [HelpSupportRepo] Created ticket ID: ${localTicket.id}');
      print('🔍 [HelpSupportRepo] Created ticket title: ${localTicket.title}');
      
      return localTicket;
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
      print('⚠️ [HelpSupportRepo] API not available, creating local message: $e');
      final userId = await _getUserId().catchError((_) => 'dummy_user');
      final userName = await _getUserName().catchError((_) => 'User');
      final newMessage = TicketMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        ticketId: ticketId,
        message: message,
        senderId: userId,
        senderName: userName,
        senderType: 'user',
        createdAt: DateTime.now(),
      );
      
      // If this is a local ticket, add the message to it
      final localTicketIndex = _localTickets.indexWhere((t) => t.id == ticketId);
      if (localTicketIndex != -1) {
        final localTicket = _localTickets[localTicketIndex];
        final updatedMessages = [...localTicket.messages, newMessage];
        _localTickets[localTicketIndex] = SupportTicket(
          id: localTicket.id,
          title: localTicket.title,
          description: localTicket.description,
          category: localTicket.category,
          priority: localTicket.priority,
          status: localTicket.status,
          userId: localTicket.userId,
          createdAt: localTicket.createdAt,
          messages: updatedMessages,
          attachments: localTicket.attachments,
        );
        print('📝 [HelpSupportRepo] Added message to local ticket. Total messages: ${updatedMessages.length}');
      }
      
      return newMessage;
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
      print('⚠️ [HelpSupportRepo] API not available, closing ticket locally: $id');
      // Update local ticket status if it exists
      final localTicketIndex = _localTickets.indexWhere((t) => t.id == id);
      if (localTicketIndex != -1) {
        final localTicket = _localTickets[localTicketIndex];
        _localTickets[localTicketIndex] = SupportTicket(
          id: localTicket.id,
          title: localTicket.title,
          description: localTicket.description,
          category: localTicket.category,
          priority: localTicket.priority,
          status: 'closed',  // Update status to closed
          userId: localTicket.userId,
          createdAt: localTicket.createdAt,
          messages: localTicket.messages,
          attachments: localTicket.attachments,
        );
        print('📝 [HelpSupportRepo] Closed local ticket: $id');
      }
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

  // ============================================
  // DUMMY DATA GENERATORS (For Demo Until Backend Ready)
  // ============================================

  List<HelpArticle> _generateDummyArticles() {
    return [
      HelpArticle(
        id: '1',
        title: 'Getting Started with Astrologer App',
        content: '''Welcome to the Astrologer App! This comprehensive guide will help you get started with all the essential features.

## Setting Up Your Profile
1. Navigate to the Profile section
2. Fill in your personal details
3. Add your specializations and experience
4. Upload a professional photo
5. Set your consultation rates

## Managing Your Calendar
The calendar is your central hub for managing consultations. Here you can:
- View all your scheduled consultations
- Set your availability
- Block off vacation days
- See consultation details at a glance

## Handling Consultations
When you receive a consultation request:
1. Review the client's details
2. Prepare any necessary materials
3. Join the call at the scheduled time
4. Complete the consultation
5. Add notes for future reference

## Getting Paid
Your earnings are automatically calculated based on completed consultations. You can:
- View your total earnings
- Track payment history
- Withdraw funds to your bank account

Need more help? Feel free to explore other articles or contact support!''',
        category: 'Getting Started',
        tags: ['beginner', 'setup', 'tutorial', 'onboarding'],
        createdAt: DateTime.now().subtract(const Duration(days: 30)),
        updatedAt: DateTime.now().subtract(const Duration(days: 5)),
        isPopular: true,
        viewCount: 1250,
      ),
      HelpArticle(
        id: '2',
        title: 'How to Schedule Consultations',
        content: '''Learn how to effectively schedule and manage your consultations with clients.

## Setting Your Availability
1. Go to Calendar tab
2. Tap on "Manage Availability"
3. Select days you're available
4. Set time slots for each day
5. Save your changes

## Accepting Consultation Requests
When a client requests a consultation:
- You'll receive a notification
- Review the request details
- Accept or decline based on your availability
- The consultation will appear on your calendar

## Managing Consultations
- View upcoming consultations
- See client details and consultation notes
- Reschedule if needed (with client consent)
- Cancel with proper notice
- Join video calls directly from the app

## Best Practices
- Keep your availability up to date
- Respond to requests promptly
- Be punctual for consultations
- Maintain professional communication
- Follow up after consultations''',
        category: 'Calendar & Scheduling',
        tags: ['calendar', 'scheduling', 'consultations', 'availability'],
        createdAt: DateTime.now().subtract(const Duration(days: 25)),
        updatedAt: DateTime.now().subtract(const Duration(days: 10)),
        isPopular: true,
        viewCount: 980,
      ),
      HelpArticle(
        id: '3',
        title: 'Managing Your Profile',
        content: '''Complete guide to setting up and managing your astrologer profile for maximum impact.

## Profile Essentials
Your profile is your digital business card. Make sure to include:
- Professional photo
- Detailed bio
- Years of experience
- Specializations
- Languages you speak
- Certifications and awards

## Optimizing Your Profile
Tips for a great profile:
- Use a clear, professional photo
- Write an engaging bio that highlights your expertise
- List all your specializations
- Include relevant certifications
- Update regularly with new achievements
- Set competitive rates

## Privacy Settings
Control what clients can see:
- Public profile information
- Contact preferences
- Availability display
- Review visibility

## Verification
Get verified to build trust:
- Submit required documents
- Complete the verification process
- Display your verified badge
- Attract more clients

Remember: A complete, professional profile leads to more consultation requests!''',
        category: 'Account & Profile',
        tags: ['profile', 'account', 'settings', 'optimization'],
        createdAt: DateTime.now().subtract(const Duration(days: 20)),
        updatedAt: DateTime.now().subtract(const Duration(days: 3)),
        isPopular: false,
        viewCount: 450,
      ),
      HelpArticle(
        id: '4',
        title: 'Payment and Billing',
        content: '''Everything you need to know about payments, billing, and earning on the platform.

## How Payments Work
1. Client pays for consultation upfront
2. Funds are held securely
3. After consultation completion, funds are released to you
4. Earnings appear in your wallet
5. Withdraw to your bank account anytime

## Setting Your Rates
- Set your per-minute consultation rate
- Consider your experience level
- Research competitive rates
- Adjust based on demand
- Offer special rates for first-time clients

## Tracking Earnings
Your dashboard shows:
- Today's earnings
- This week's total
- This month's revenue
- All-time earnings
- Consultation count

## Withdrawals
- Minimum withdrawal: ₹500
- Processing time: 2-3 business days
- Bank transfer (no fees)
- UPI transfer (instant, ₹10 fee)
- Payment history tracking

## Payment Issues
If you experience issues:
- Check your bank details are correct
- Ensure minimum balance is met
- Contact support for help
- Review payment history for disputes

Your earnings are secure and transparent!''',
        category: 'Payments',
        tags: ['payment', 'billing', 'earnings', 'withdrawal', 'rates'],
        createdAt: DateTime.now().subtract(const Duration(days: 15)),
        updatedAt: DateTime.now().subtract(const Duration(days: 1)),
        isPopular: true,
        viewCount: 750,
      ),
      HelpArticle(
        id: '5',
        title: 'Troubleshooting Common Issues',
        content: '''Solutions to common technical problems and issues you might encounter.

## App Issues

### App Won't Load
- Check your internet connection
- Force close and reopen the app
- Clear app cache
- Update to latest version
- Restart your device

### Login Problems
- Verify your phone number
- Check OTP expiration
- Request new OTP
- Contact support if persistent

## Consultation Issues

### Video Call Problems
- Test your camera and microphone
- Check internet speed (minimum 2 Mbps)
- Use latest app version
- Try different network
- Close other apps

### Audio Issues
- Grant microphone permissions
- Check phone volume
- Test with other apps
- Restart device
- Update app

## Calendar Sync Issues
- Refresh your calendar
- Check availability settings
- Sync with device calendar
- Update app
- Clear cache

## Payment Issues
- Verify bank details
- Check withdrawal limit
- Wait for processing time
- Review transaction history
- Contact support

## Getting Help
Can't find a solution?
- Search FAQ section
- Submit a support ticket
- Email: support@astrologerapp.com
- Response time: 24-48 hours

We're here to help!''',
        category: 'Technical Issues',
        tags: ['troubleshooting', 'technical', 'problems', 'fixes', 'support'],
        createdAt: DateTime.now().subtract(const Duration(days: 10)),
        updatedAt: DateTime.now().subtract(const Duration(days: 2)),
        isPopular: false,
        viewCount: 320,
      ),
      HelpArticle(
        id: '6',
        title: 'Understanding Consultations',
        content: '''A comprehensive guide to conducting professional astrology consultations through the app.

## Types of Consultations
- Video Consultations (most popular)
- Audio-only Consultations
- Chat Consultations
- Extended Sessions

## Preparing for Consultations
Before each session:
- Review client's consultation request
- Prepare birth chart if details provided
- Have reference materials ready
- Test your audio/video setup
- Be in a quiet, professional environment

## During Consultations
Best practices:
- Start on time
- Greet the client warmly
- Listen actively to their concerns
- Provide clear, actionable guidance
- Allow time for questions
- Take brief notes

## After Consultations
- Complete the consultation in the app
- Add private notes for future reference
- Request client review (optional)
- Earnings are automatically credited
- Follow up if needed

## Professional Etiquette
- Maintain confidentiality
- Be respectful and non-judgmental
- Avoid making health/legal claims
- Set appropriate boundaries
- Provide honest guidance

## Handling Difficult Situations
- Stay calm and professional
- Listen without interrupting
- Clarify misunderstandings
- End session if behavior is inappropriate
- Report serious issues to support

Quality consultations lead to positive reviews and repeat clients!''',
        category: 'Consultations',
        tags: ['consultations', 'sessions', 'clients', 'professional'],
        createdAt: DateTime.now().subtract(const Duration(days: 8)),
        updatedAt: DateTime.now().subtract(const Duration(days: 1)),
        isPopular: true,
        viewCount: 890,
      ),
    ];
  }

  List<FAQItem> _generateDummyFAQs() {
    return [
      FAQItem(
        id: '1',
        question: 'How do I create my astrologer profile?',
        answer: 'To create your profile, go to the Profile section and fill in your details including your specializations, experience, bio, languages, and set your consultation rate. Add a professional photo and any certifications or awards to make your profile stand out.',
        category: 'Account',
        helpfulCount: 45,
        notHelpfulCount: 2,
      ),
      FAQItem(
        id: '2',
        question: 'How can I schedule consultations?',
        answer: 'Navigate to the Calendar section, where you can set your available time slots. When clients request consultations, you\'ll receive notifications and can accept or decline based on your availability.',
        category: 'Calendar',
        helpfulCount: 38,
        notHelpfulCount: 1,
      ),
      FAQItem(
        id: '3',
        question: 'What payment methods are accepted?',
        answer: 'We accept all major credit cards, UPI, net banking, and digital wallets for payments. Your earnings are automatically credited to your wallet after each completed consultation.',
        category: 'Payments',
        helpfulCount: 52,
        notHelpfulCount: 3,
      ),
      FAQItem(
        id: '4',
        question: 'How long does it take to withdraw earnings?',
        answer: 'Bank transfers typically take 2-3 business days to process. UPI transfers are instant but have a small ₹10 fee. The minimum withdrawal amount is ₹500.',
        category: 'Payments',
        helpfulCount: 67,
        notHelpfulCount: 2,
      ),
      FAQItem(
        id: '5',
        question: 'Can I change my consultation rates?',
        answer: 'Yes, you can update your rates anytime from the Profile settings. New rates will apply to future consultations only, not existing bookings.',
        category: 'Account',
        helpfulCount: 34,
        notHelpfulCount: 1,
      ),
      FAQItem(
        id: '6',
        question: 'What should I do if I have technical issues during a consultation?',
        answer: 'First, check your internet connection and app permissions. If the issue persists, you can reschedule the consultation with the client at no charge. Contact support for persistent technical problems.',
        category: 'Technical',
        helpfulCount: 28,
        notHelpfulCount: 4,
      ),
      FAQItem(
        id: '7',
        question: 'How do I set my availability?',
        answer: 'Go to Calendar > Manage Availability. Select the days you\'re available and set your preferred time slots. You can also block specific dates for holidays or personal time.',
        category: 'Calendar',
        helpfulCount: 41,
        notHelpfulCount: 2,
      ),
      FAQItem(
        id: '8',
        question: 'Can I cancel a consultation?',
        answer: 'Yes, but please provide at least 2 hours notice. Frequent cancellations may affect your rating. Use the "Cancel Consultation" button in the consultation details.',
        category: 'Consultations',
        helpfulCount: 19,
        notHelpfulCount: 8,
      ),
      FAQItem(
        id: '9',
        question: 'How are ratings and reviews handled?',
        answer: 'Clients can rate and review you after each consultation. All reviews are verified and appear on your profile. You can respond to reviews professionally.',
        category: 'General',
        helpfulCount: 56,
        notHelpfulCount: 1,
      ),
      FAQItem(
        id: '10',
        question: 'What if a client doesn\'t show up?',
        answer: 'If a client doesn\'t join within 10 minutes of the scheduled time, you can mark the consultation as "No Show". You\'ll still receive payment for the booking.',
        category: 'Consultations',
        helpfulCount: 43,
        notHelpfulCount: 5,
      ),
    ];
  }

  List<SupportTicket> _generateDummyTickets(String userId) {
    return [
      SupportTicket(
        id: '1',
        title: 'Unable to withdraw earnings',
        description: 'I\'m trying to withdraw my earnings but getting an error message saying "Invalid bank details". I\'ve double-checked and they seem correct.',
        category: 'Payment Problems',
        priority: 'High',
        status: 'open',
        userId: userId,
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
        messages: [
          TicketMessage(
            id: 'm1',
            ticketId: '1',
            message: 'I\'m trying to withdraw my earnings but getting an error message saying "Invalid bank details". I\'ve double-checked and they seem correct.',
            senderId: userId,
            senderName: 'You',
            senderType: 'user',
            createdAt: DateTime.now().subtract(const Duration(hours: 2)),
          ),
          TicketMessage(
            id: 'm2',
            ticketId: '1',
            message: 'Thank you for contacting support. I\'ve checked your account and noticed the IFSC code format needs to be updated. Could you please verify it matches your bank\'s official IFSC code?',
            senderId: 'support_1',
            senderName: 'Support Team',
            senderType: 'support',
            createdAt: DateTime.now().subtract(const Duration(hours: 1, minutes: 30)),
          ),
        ],
      ),
      SupportTicket(
        id: '2',
        title: 'Consultation video quality issues',
        description: 'During my last 3 consultations, the video quality was very poor and kept freezing. My internet connection is stable (50 Mbps). Is there a server issue?',
        category: 'Technical Support',
        priority: 'Medium',
        status: 'in-progress',
        userId: userId,
        createdAt: DateTime.now().subtract(const Duration(days: 1, hours: 5)),
        messages: [
          TicketMessage(
            id: 'm3',
            ticketId: '2',
            message: 'During my last 3 consultations, the video quality was very poor and kept freezing. My internet connection is stable (50 Mbps). Is there a server issue?',
            senderId: userId,
            senderName: 'You',
            senderType: 'user',
            createdAt: DateTime.now().subtract(const Duration(days: 1, hours: 5)),
          ),
          TicketMessage(
            id: 'm4',
            ticketId: '2',
            message: 'We\'re investigating this issue. Can you please provide: 1) Device model, 2) App version, 3) Approximate time of the consultations? This will help us identify the problem.',
            senderId: 'tech_1',
            senderName: 'Technical Team',
            senderType: 'support',
            createdAt: DateTime.now().subtract(const Duration(days: 1, hours: 3)),
          ),
          TicketMessage(
            id: 'm5',
            ticketId: '2',
            message: 'Device: Samsung Galaxy S24, App version: 2.1.0, Times: Yesterday 2pm, 5pm, and 7pm IST',
            senderId: userId,
            senderName: 'You',
            senderType: 'user',
            createdAt: DateTime.now().subtract(const Duration(days: 1, hours: 2)),
          ),
        ],
      ),
      SupportTicket(
        id: '3',
        title: 'Request for profile verification badge',
        description: 'I\'ve uploaded all my certifications and have been on the platform for 6 months with 4.8 stars. How can I get the verified badge?',
        category: 'Account Issues',
        priority: 'Low',
        status: 'closed',
        userId: userId,
        createdAt: DateTime.now().subtract(const Duration(days: 5)),
        messages: [
          TicketMessage(
            id: 'm6',
            ticketId: '3',
            message: 'I\'ve uploaded all my certifications and have been on the platform for 6 months with 4.8 stars. How can I get the verified badge?',
            senderId: userId,
            senderName: 'You',
            senderType: 'user',
            createdAt: DateTime.now().subtract(const Duration(days: 5)),
          ),
          TicketMessage(
            id: 'm7',
            ticketId: '3',
            message: 'Congratulations! Your profile meets all requirements for verification. I\'ve initiated the verification process. You should see the badge on your profile within 24-48 hours. Thank you for being a valued member!',
            senderId: 'support_2',
            senderName: 'Verification Team',
            senderType: 'support',
            createdAt: DateTime.now().subtract(const Duration(days: 4, hours: 20)),
          ),
          TicketMessage(
            id: 'm8',
            ticketId: '3',
            message: 'Thank you so much! I can see the badge now. Closing this ticket.',
            senderId: userId,
            senderName: 'You',
            senderType: 'user',
            createdAt: DateTime.now().subtract(const Duration(days: 4, hours: 18)),
          ),
        ],
      ),
    ];
  }
}


