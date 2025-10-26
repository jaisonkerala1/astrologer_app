import 'package:equatable/equatable.dart';

/// Model representing a unified communication item (message, call, or video call)
class CommunicationItem extends Equatable {
  final String id;
  final CommunicationType type;
  final String contactName;
  final String avatar;
  final DateTime timestamp;
  final String preview;
  final int unreadCount;
  final bool isOnline;
  final CommunicationStatus status;
  final String? duration; // For calls (formatted duration)
  final double? chargedAmount; // For billing display
  final String? sessionId; // Link to backend Session

  const CommunicationItem({
    required this.id,
    required this.type,
    required this.contactName,
    required this.avatar,
    required this.timestamp,
    required this.preview,
    this.unreadCount = 0,
    this.isOnline = false,
    required this.status,
    this.duration,
    this.chargedAmount,
    this.sessionId,
  });

  @override
  List<Object?> get props => [
    id,
    type,
    contactName,
    avatar,
    timestamp,
    preview,
    unreadCount,
    isOnline,
    status,
    duration,
    chargedAmount,
    sessionId,
  ];

  /// Get display icon based on type (IconData for Material Icons)
  String get typeIcon {
    // Deprecated - use typeIconData instead
    switch (type) {
      case CommunicationType.message:
        return '💬';
      case CommunicationType.voiceCall:
        return '☎️';
      case CommunicationType.videoCall:
        return '🎥';
    }
  }

  /// Get status icon for calls (deprecated)
  String? get statusIcon {
    if (type == CommunicationType.message) return null;
    
    switch (status) {
      case CommunicationStatus.missed:
        return '↙️';
      case CommunicationStatus.outgoing:
        return '↗️';
      case CommunicationStatus.incoming:
        return '↙️';
      default:
        return null;
    }
  }

  /// Get formatted time ago
  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) return 'now';
    if (difference.inMinutes < 60) return '${difference.inMinutes}m';
    if (difference.inHours < 24) return '${difference.inHours}h';
    if (difference.inDays < 7) return '${difference.inDays}d';
    return '${(difference.inDays / 7).floor()}w';
  }

  /// From JSON
  factory CommunicationItem.fromJson(Map<String, dynamic> json) {
    return CommunicationItem(
      id: json['_id'] ?? json['id'] ?? '',
      type: _parseType(json['type']),
      contactName: json['contactName'] ?? '',
      avatar: json['avatar'] ?? '',
      timestamp: json['timestamp'] != null 
          ? DateTime.parse(json['timestamp'])
          : DateTime.now(),
      preview: json['preview'] ?? '',
      unreadCount: json['unreadCount'] ?? 0,
      isOnline: json['isOnline'] ?? false,
      status: _parseStatusFromString(json['status']),
      duration: json['duration'],
      chargedAmount: json['chargedAmount'] != null 
          ? (json['chargedAmount'] as num).toDouble()
          : null,
      sessionId: json['sessionId'],
    );
  }

  /// To JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'contactName': contactName,
      'avatar': avatar,
      'timestamp': timestamp.toIso8601String(),
      'preview': preview,
      'unreadCount': unreadCount,
      'isOnline': isOnline,
      'status': status.name,
      'duration': duration,
      'chargedAmount': chargedAmount,
      'sessionId': sessionId,
    };
  }

  /// Convert from legacy call format
  factory CommunicationItem.fromCall(Map<String, dynamic> call) {
    return CommunicationItem(
      id: call['name'] + DateTime.now().millisecondsSinceEpoch.toString(),
      type: CommunicationType.voiceCall,
      contactName: call['name'],
      avatar: call['avatar'],
      timestamp: _parseTime(call['time']),
      preview: call['type'],
      status: _parseCallStatus(call['status']),
      duration: call['duration'],
    );
  }

  /// Convert from legacy message format
  factory CommunicationItem.fromMessage(Map<String, dynamic> message) {
    return CommunicationItem(
      id: message['name'] + DateTime.now().millisecondsSinceEpoch.toString(),
      type: CommunicationType.message,
      contactName: message['name'],
      avatar: message['avatar'],
      timestamp: _parseTime(message['time']),
      preview: message['preview'],
      unreadCount: message['unread'] ?? 0,
      isOnline: message['isOnline'] ?? false,
      status: CommunicationStatus.received,
    );
  }

  static CommunicationType _parseType(String? type) {
    switch (type?.toLowerCase()) {
      case 'message':
        return CommunicationType.message;
      case 'voicecall':
      case 'voice_call':
      case 'call':
        return CommunicationType.voiceCall;
      case 'videocall':
      case 'video_call':
      case 'video':
        return CommunicationType.videoCall;
      default:
        return CommunicationType.message;
    }
  }

  static CommunicationStatus _parseStatusFromString(String? status) {
    switch (status?.toLowerCase()) {
      case 'sent':
        return CommunicationStatus.sent;
      case 'received':
        return CommunicationStatus.received;
      case 'missed':
        return CommunicationStatus.missed;
      case 'incoming':
        return CommunicationStatus.incoming;
      case 'outgoing':
        return CommunicationStatus.outgoing;
      default:
        return CommunicationStatus.received;
    }
  }

  static DateTime _parseTime(String timeStr) {
    // Simple parsing for mock data - in production use proper date parsing
    final now = DateTime.now();
    if (timeStr.contains('now') || timeStr == 'Just now') {
      return now;
    } else if (timeStr.contains('m')) {
      final minutes = int.tryParse(timeStr.replaceAll('m', '').trim()) ?? 0;
      return now.subtract(Duration(minutes: minutes));
    } else if (timeStr.contains('h')) {
      final hours = int.tryParse(timeStr.replaceAll('h', '').replaceAll('ago', '').trim()) ?? 0;
      return now.subtract(Duration(hours: hours));
    } else if (timeStr.contains('d')) {
      final days = int.tryParse(timeStr.replaceAll('d', '').trim()) ?? 0;
      return now.subtract(Duration(days: days));
    }
    return now;
  }

  static CommunicationStatus _parseCallStatus(String status) {
    switch (status.toLowerCase()) {
      case 'missed':
        return CommunicationStatus.missed;
      case 'answered':
      case 'incoming':
        return CommunicationStatus.incoming;
      case 'outgoing':
        return CommunicationStatus.outgoing;
      default:
        return CommunicationStatus.received;
    }
  }
}

/// Type of communication
enum CommunicationType {
  message,
  voiceCall,
  videoCall,
}

/// Status of communication
enum CommunicationStatus {
  sent,
  received,
  missed,
  incoming,
  outgoing,
}

/// Filter options for unified view
enum CommunicationFilter {
  all,
  calls,
  messages,
  video,
}

/// Extension for filter display
extension CommunicationFilterExtension on CommunicationFilter {
  String get label {
    switch (this) {
      case CommunicationFilter.all:
        return 'All';
      case CommunicationFilter.calls:
        return 'Calls';
      case CommunicationFilter.messages:
        return 'Messages';
      case CommunicationFilter.video:
        return 'Video';
    }
  }
}


