class ApiConstants {
  // Base URL - Update this with your actual server URL
  static const String baseUrl = 'https://astrologerapp-production.up.railway.app';
  
  // Authentication endpoints
  static const String checkPhone = '/api/auth/check-phone';
  static const String sendOtp = '/api/auth/send-otp';
  static const String verifyOtp = '/api/auth/verify-otp';
  static const String signup = '/api/auth/signup';
  static const String refreshToken = '/api/auth/refresh-token';
  static const String logout = '/api/auth/logout';
  static const String deleteAccount = '/api/auth/delete-account';
  
  // Dashboard endpoints
  static const String dashboardStats = '/api/dashboard/stats';
  static const String updateStatus = '/api/dashboard/status';
  
  // Profile endpoints
  static const String profile = '/api/profile';
  static const String updateProfile = '/api/profile';
  static const String uploadProfileImage = '/api/profile/upload-image';
  static const String updateSpecializations = '/api/profile/specializations';
  static const String updateLanguages = '/api/profile/languages';
  static const String updateRate = '/api/profile/rate';
  
  // Verification endpoints
  static const String verificationRequest = '/api/profile/verification/request';
  static const String verificationStatus = '/api/profile/verification/status';
  
  // Chat endpoints
  static const String chatConversations = '/api/chat/conversations';
  static const String chatActiveConversation = '/api/chat/active';
  static const String chatCreateConversation = '/api/chat/conversations';
  static const String chatAddMessage = '/api/chat/conversations';
  static const String chatUpdateSettings = '/api/chat/conversations';
  static const String chatClearHistory = '/api/chat/history';
  static const String chatDeleteConversation = '/api/chat/conversations';
  static const String loonaGenerate = '/api/chat/loona/generate';
  
  // Notification endpoints
  static const String notifications = '/api/notifications';
  static const String notificationMarkRead = '/api/notifications';
  static const String notificationMarkAllRead = '/api/notifications/read-all';
  static const String notificationArchive = '/api/notifications';
  static const String notificationDelete = '/api/notifications';
  static const String notificationClearAll = '/api/notifications/clear-all';
  static const String notificationSettings = '/api/notifications/settings';
  
  // Headers
  static const Map<String, String> defaultHeaders = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };
  
  // Timeouts
  static const int connectTimeout = 30000; // 30 seconds
  static const int receiveTimeout = 30000; // 30 seconds
}





