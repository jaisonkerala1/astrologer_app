class AppConstants {
  // App Information
  static const String appName = 'Astrologer App';
  static const String appVersion = '1.0.0';
  
  // Storage Keys
  static const String tokenKey = 'auth_token';
  static const String userKey = 'user_data';
  static const String isLoggedInKey = 'is_logged_in';
  static const String phoneKey = 'phone_number';
  
  // Validation
  static const int minPhoneLength = 10;
  static const int maxPhoneLength = 15;
  static const int otpLength = 6;
  
  // UI Constants
  static const double defaultPadding = 16.0;
  static const double smallPadding = 8.0;
  static const double largePadding = 24.0;
  static const double borderRadius = 12.0;
  static const double buttonHeight = 48.0;
  
  // Animation Durations
  static const Duration shortAnimation = Duration(milliseconds: 200);
  static const Duration mediumAnimation = Duration(milliseconds: 300);
  static const Duration longAnimation = Duration(milliseconds: 500);
  
  // Currency
  static const String currencySymbol = '₹';
  static const String currencyCode = 'INR';
  
  // Status
  static const String onlineStatus = 'online';
  static const String offlineStatus = 'offline';
  
  // Specializations
  static const List<String> defaultSpecializations = [
    'Vedic Astrology',
    'Tarot Reading',
    'Numerology',
    'Palmistry',
    'Vastu Shastra',
    'Gemstone Consultation',
    'Horoscope Analysis',
    'Love & Relationship',
    'Career Guidance',
    'Health & Wellness',
  ];
  
  // Languages
  static const List<String> defaultLanguages = [
    'English',
    'Hindi',
    'Bengali',
    'Tamil',
    'Telugu',
    'Gujarati',
    'Marathi',
    'Kannada',
    'Malayalam',
    'Punjabi',
  ];
}









