import 'package:equatable/equatable.dart';

/// Help article model for documentation
class HelpArticle extends Equatable {
  final String id;
  final String title;
  final String content;
  final String category;
  final List<String> tags;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isPopular;
  final int viewCount;

  const HelpArticle({
    required this.id,
    required this.title,
    required this.content,
    required this.category,
    required this.tags,
    required this.createdAt,
    required this.updatedAt,
    this.isPopular = false,
    this.viewCount = 0,
  });

  factory HelpArticle.fromJson(Map<String, dynamic> json) {
    return HelpArticle(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      content: json['content'] ?? '',
      category: json['category'] ?? '',
      tags: List<String>.from(json['tags'] ?? []),
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updatedAt'] ?? DateTime.now().toIso8601String()),
      isPopular: json['isPopular'] ?? false,
      viewCount: json['viewCount'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'category': category,
      'tags': tags,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'isPopular': isPopular,
      'viewCount': viewCount,
    };
  }

  @override
  List<Object?> get props => [
        id,
        title,
        content,
        category,
        tags,
        createdAt,
        updatedAt,
        isPopular,
        viewCount,
      ];
}

/// FAQ item model
class FAQItem extends Equatable {
  final String id;
  final String question;
  final String answer;
  final String category;
  final bool isExpanded;
  final int helpfulCount;
  final int notHelpfulCount;

  const FAQItem({
    required this.id,
    required this.question,
    required this.answer,
    required this.category,
    this.isExpanded = false,
    this.helpfulCount = 0,
    this.notHelpfulCount = 0,
  });

  factory FAQItem.fromJson(Map<String, dynamic> json) {
    return FAQItem(
      id: json['id'] ?? '',
      question: json['question'] ?? '',
      answer: json['answer'] ?? '',
      category: json['category'] ?? '',
      isExpanded: json['isExpanded'] ?? false,
      helpfulCount: json['helpfulCount'] ?? 0,
      notHelpfulCount: json['notHelpfulCount'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'question': question,
      'answer': answer,
      'category': category,
      'isExpanded': isExpanded,
      'helpfulCount': helpfulCount,
      'notHelpfulCount': notHelpfulCount,
    };
  }

  FAQItem copyWith({
    String? id,
    String? question,
    String? answer,
    String? category,
    bool? isExpanded,
    int? helpfulCount,
    int? notHelpfulCount,
  }) {
    return FAQItem(
      id: id ?? this.id,
      question: question ?? this.question,
      answer: answer ?? this.answer,
      category: category ?? this.category,
      isExpanded: isExpanded ?? this.isExpanded,
      helpfulCount: helpfulCount ?? this.helpfulCount,
      notHelpfulCount: notHelpfulCount ?? this.notHelpfulCount,
    );
  }

  @override
  List<Object?> get props => [
        id,
        question,
        answer,
        category,
        isExpanded,
        helpfulCount,
        notHelpfulCount,
      ];
}

/// Support ticket model
class SupportTicket extends Equatable {
  final String id;
  final String title;
  final String description;
  final String category;
  final String priority;
  final String status;
  final String userId;
  final String? assignedTo;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final List<TicketMessage> messages;
  final List<String> attachments;

  const SupportTicket({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.priority,
    required this.status,
    required this.userId,
    this.assignedTo,
    required this.createdAt,
    this.updatedAt,
    this.messages = const [],
    this.attachments = const [],
  });

  factory SupportTicket.fromJson(Map<String, dynamic> json) {
    return SupportTicket(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      category: json['category'] ?? '',
      priority: json['priority'] ?? 'medium',
      status: json['status'] ?? 'open',
      userId: json['userId'] ?? '',
      assignedTo: json['assignedTo'],
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
      messages: (json['messages'] as List<dynamic>?)
              ?.map((msg) => TicketMessage.fromJson(msg))
              .toList() ??
          [],
      attachments: List<String>.from(json['attachments'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'category': category,
      'priority': priority,
      'status': status,
      'userId': userId,
      'assignedTo': assignedTo,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'messages': messages.map((msg) => msg.toJson()).toList(),
      'attachments': attachments,
    };
  }

  @override
  List<Object?> get props => [
        id,
        title,
        description,
        category,
        priority,
        status,
        userId,
        assignedTo,
        createdAt,
        updatedAt,
        messages,
        attachments,
      ];
}

/// Ticket message model
class TicketMessage extends Equatable {
  final String id;
  final String ticketId;
  final String message;
  final String senderId;
  final String senderName;
  final String senderType; // 'user' or 'support'
  final DateTime createdAt;
  final List<String> attachments;

  const TicketMessage({
    required this.id,
    required this.ticketId,
    required this.message,
    required this.senderId,
    required this.senderName,
    required this.senderType,
    required this.createdAt,
    this.attachments = const [],
  });

  factory TicketMessage.fromJson(Map<String, dynamic> json) {
    return TicketMessage(
      id: json['id'] ?? '',
      ticketId: json['ticketId'] ?? '',
      message: json['message'] ?? '',
      senderId: json['senderId'] ?? '',
      senderName: json['senderName'] ?? '',
      senderType: json['senderType'] ?? 'user',
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      attachments: List<String>.from(json['attachments'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'ticketId': ticketId,
      'message': message,
      'senderId': senderId,
      'senderName': senderName,
      'senderType': senderType,
      'createdAt': createdAt.toIso8601String(),
      'attachments': attachments,
    };
  }

  @override
  List<Object?> get props => [
        id,
        ticketId,
        message,
        senderId,
        senderName,
        senderType,
        createdAt,
        attachments,
      ];
}



