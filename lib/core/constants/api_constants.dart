class ApiConstants {
  // Base URL - Update this with your actual server URL
  static const String baseUrl = 'https://astrologerapp-production.up.railway.app';
  
  // Authentication endpoints
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
  static const String uploadImage = '/api/profile/upload-image';
  
  // Headers
  static const Map<String, String> defaultHeaders = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };
  
  // Timeouts
  static const int connectTimeout = 30000; // 30 seconds
  static const int receiveTimeout = 30000; // 30 seconds
}





