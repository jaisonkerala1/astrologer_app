import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class AgoraTokenService {
  static const String _baseUrl = 'https://astrologerapp-production.up.railway.app';

  static Future<Map<String, dynamic>?> generateToken({
    required String channelName,
    int? uid,
    String role = 'audience',
  }) async {
    try {
      debugPrint('🎫 Requesting token for channel: $channelName, UID: $uid, role: $role');

      final response = await http.post(
        Uri.parse('$_baseUrl/api/agora/token'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'channelName': channelName,
          'uid': uid,
          'role': role,
        }),
      );

      debugPrint('🎫 Token response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          debugPrint('✅ Token generated successfully');
          return data['data'];
        } else {
          debugPrint('❌ Token generation failed: ${data['message']}');
          return null;
        }
      } else {
        debugPrint('❌ Token request failed with status: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      debugPrint('❌ Error requesting token: $e');
      return null;
    }
  }
}
