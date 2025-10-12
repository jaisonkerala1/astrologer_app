import 'package:sms_autofill/sms_autofill.dart';

/// Helper class for OTP auto-detection functionality
/// Provides utilities for Android SMS Retriever API and iOS autofill
class OTPHelper {
  /// Get the app's hash signature for Android SMS Retriever API
  /// 
  /// This hash must be included in SMS messages sent from backend
  /// to enable zero-permission OTP auto-detection on Android.
  /// 
  /// Usage:
  /// ```dart
  /// final hash = await OTPHelper.getAppSignature();
  /// print('App Hash: $hash');
  /// // Send this hash to your backend team
  /// ```
  /// 
  /// Note: Hash is different for debug and release builds
  static Future<String?> getAppSignature() async {
    try {
      final signature = await SmsAutoFill().getAppSignature;
      return signature;
    } catch (e) {
      print('Error getting app signature: $e');
      return null;
    }
  }

  /// Print app signature to console for easy copying
  /// 
  /// Run this once in debug mode to get your app's hash signature
  static Future<void> printAppSignature() async {
    final signature = await getAppSignature();
    if (signature != null) {
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      print('📱 APP HASH SIGNATURE');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      print('');
      print('  $signature');
      print('');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      print('');
      print('📤 Send this hash to your backend team');
      print('');
      print('📨 SMS Format Example:');
      print('   Your verification code is 123456');
      print('');
      print('   $signature');
      print('');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    } else {
      print('❌ Failed to get app signature');
    }
  }

  /// Get SMS message template for backend team
  /// 
  /// Returns the recommended SMS format that includes:
  /// - OTP code placeholder
  /// - App hash signature
  /// - iOS domain (optional)
  static Future<String> getSMSTemplate({String? domain}) async {
    final hash = await getAppSignature();
    
    if (domain != null) {
      // Template for both Android & iOS
      return '''
Your verification code is {OTP_CODE}

@$domain #{OTP_CODE}
${hash ?? 'HASH_SIGNATURE'}
''';
    } else {
      // Template for Android only
      return '''
Your verification code is {OTP_CODE}

${hash ?? 'HASH_SIGNATURE'}
''';
    }
  }

  /// Validate OTP format
  static bool isValidOTP(String? otp) {
    if (otp == null || otp.isEmpty) return false;
    if (otp.length != 6) return false;
    return RegExp(r'^\d{6}$').hasMatch(otp);
  }

  /// Extract OTP from SMS text
  /// Useful for manual SMS parsing if needed
  static String? extractOTPFromSMS(String sms) {
    // Match 4-8 digit codes
    final regexPatterns = [
      RegExp(r'\b\d{6}\b'),  // 6 digits
      RegExp(r'\b\d{5}\b'),  // 5 digits
      RegExp(r'\b\d{4}\b'),  // 4 digits
    ];

    for (var pattern in regexPatterns) {
      final match = pattern.firstMatch(sms);
      if (match != null) {
        return match.group(0);
      }
    }

    return null;
  }
}

