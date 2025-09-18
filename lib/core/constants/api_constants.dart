class ApiConstants {
  // Base URL - Update this with your actual server URL
  static const String baseUrl = 'http://192.168.29.99:7566/api';
  
  // Authentication endpoints
  static const String sendOtp = '/auth/send-otp';
  static const String verifyOtp = '/auth/verify-otp';
  static const String signup = '/auth/signup';
  static const String refreshToken = '/auth/refresh-token';
  static const String logout = '/auth/logout';
  
  // Dashboard endpoints
  static const String dashboardStats = '/dashboard/stats';
  static const String updateStatus = '/dashboard/status';
  
  // Profile endpoints
  static const String profile = '/profile';
  static const String updateProfile = '/profile';
  static const String uploadImage = '/profile/upload-image';
  
  // Headers
  static const Map<String, String> defaultHeaders = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };
  
  // Timeouts
  static const int connectTimeout = 30000; // 30 seconds
  static const int receiveTimeout = 30000; // 30 seconds
}





