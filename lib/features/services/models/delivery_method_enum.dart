enum DeliveryMethod {
  videoCall,
  audioCall,
  chat,
  report,
}

extension DeliveryMethodExtension on DeliveryMethod {
  String get displayName {
    switch (this) {
      case DeliveryMethod.videoCall:
        return 'Video Call';
      case DeliveryMethod.audioCall:
        return 'Audio Call';
      case DeliveryMethod.chat:
        return 'Chat';
      case DeliveryMethod.report:
        return 'Written Report';
    }
  }

  String get description {
    switch (this) {
      case DeliveryMethod.videoCall:
        return 'Face-to-face video consultation';
      case DeliveryMethod.audioCall:
        return 'Voice call consultation';
      case DeliveryMethod.chat:
        return 'Text-based chat consultation';
      case DeliveryMethod.report:
        return 'Detailed PDF report';
    }
  }

  String get icon {
    switch (this) {
      case DeliveryMethod.videoCall:
        return '📹';
      case DeliveryMethod.audioCall:
        return '📞';
      case DeliveryMethod.chat:
        return '💬';
      case DeliveryMethod.report:
        return '📄';
    }
  }
}

