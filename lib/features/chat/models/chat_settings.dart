class ChatSettings {
  final bool rememberConversations;
  final bool shareUserInfo;
  final String preferredLanguage;
  final bool notificationsEnabled;
  final DateTime lastCleared;

  ChatSettings({
    this.rememberConversations = true,
    this.shareUserInfo = true,
    this.preferredLanguage = 'en',
    this.notificationsEnabled = true,
    required this.lastCleared,
  });

  factory ChatSettings.fromJson(Map<String, dynamic> json) {
    return ChatSettings(
      rememberConversations: json['rememberConversations'] ?? true,
      shareUserInfo: json['shareUserInfo'] ?? true,
      preferredLanguage: json['preferredLanguage'] ?? 'en',
      notificationsEnabled: json['notificationsEnabled'] ?? true,
      lastCleared: DateTime.parse(json['lastCleared'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'rememberConversations': rememberConversations,
      'shareUserInfo': shareUserInfo,
      'preferredLanguage': preferredLanguage,
      'notificationsEnabled': notificationsEnabled,
      'lastCleared': lastCleared.toIso8601String(),
    };
  }

  ChatSettings copyWith({
    bool? rememberConversations,
    bool? shareUserInfo,
    String? preferredLanguage,
    bool? notificationsEnabled,
    DateTime? lastCleared,
  }) {
    return ChatSettings(
      rememberConversations: rememberConversations ?? this.rememberConversations,
      shareUserInfo: shareUserInfo ?? this.shareUserInfo,
      preferredLanguage: preferredLanguage ?? this.preferredLanguage,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      lastCleared: lastCleared ?? this.lastCleared,
    );
  }
}






























