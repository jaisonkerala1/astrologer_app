import 'dart:convert';
import 'package:http/http.dart' as http;

class AIEnhancementService {
  static const String _openRouterApiKey = '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';
  static const String _openRouterUrl = 'https://openrouter.ai/api/v1/chat/completions';
  
  static const String _claudeModel = 'anthropic/claude-3-haiku:beta';
  
  /// Generate 3 enhanced bio versions using Claude Haiku
  static Future<Map<String, String>> enhanceBio(String originalBio, {
    required String name,
    required int experience,
    required List<String> specializations,
    required List<String> languages,
    required String awards,
    required String certificates,
  }) async {
    try {
      final prompt = _buildBioEnhancementPrompt(
        originalBio,
        name: name,
        experience: experience,
        specializations: specializations,
        languages: languages,
        awards: awards,
        certificates: certificates,
      );
      
      final response = await http.post(
        Uri.parse(_openRouterUrl),
        headers: {
          'Authorization': 'Bearer $_openRouterApiKey',
          'Content-Type': 'application/json',
          'HTTP-Referer': 'https://astrologer-app.com',
          'X-Title': 'Astrologer App Bio Enhancer',
        },
        body: jsonEncode({
          'model': _claudeModel,
          'messages': [
            {
              'role': 'user',
              'content': prompt,
            }
          ],
          'max_tokens': 2000,
          'temperature': 0.7,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        // Check for API errors in response
        if (data.containsKey('error')) {
          throw Exception('API Error: ${data['error']['message'] ?? 'Unknown error'}');
        }
        
        if (data.containsKey('choices') && data['choices'].isNotEmpty) {
          final content = data['choices'][0]['message']['content'];
          return _parseBioVersions(content);
        } else {
          throw Exception('No content received from API');
        }
      } else {
        final errorData = jsonDecode(response.body);
        final errorMessage = errorData['error']?['message'] ?? 'Unknown API error';
        throw Exception('API Error ${response.statusCode}: $errorMessage');
      }
    } catch (e) {
      throw Exception('Failed to enhance bio: $e');
    }
  }

  static String _buildBioEnhancementPrompt(
    String originalBio, {
    required String name,
    required int experience,
    required List<String> specializations,
    required List<String> languages,
    required String awards,
    required String certificates,
  }) {
    final specializationsText = specializations.isNotEmpty ? specializations.join(', ') : 'Not specified';
    final languagesText = languages.isNotEmpty ? languages.join(', ') : 'Not specified';
    final awardsText = awards.isNotEmpty ? awards : 'No awards specified';
    final certificatesText = certificates.isNotEmpty ? certificates : 'No certifications specified';
    
    return '''
You are a professional bio writing expert specializing in astrologer profiles. 

**Astrologer Profile Information:**
- Name: $name
- Experience: $experience years
- Specializations: $specializationsText
- Languages: $languagesText
- Awards: $awardsText
- Certifications: $certificatesText

**Current Bio:**
"$originalBio"

Create 3 enhanced versions of this bio, each with a different tone and style:

1. **Professional & Formal**: Write a polished, authoritative bio that emphasizes expertise, credentials, and professional achievements. Use formal language and highlight years of experience, certifications, and specializations.

2. **Warm & Personal**: Write a friendly, approachable bio that connects emotionally with clients. Focus on personal journey, passion for helping others, and genuine care. Use warm, conversational language.

3. **Modern & Engaging**: Write a contemporary, dynamic bio that appeals to younger audiences. Use modern language, highlight unique approaches, and include engaging elements that make the astrologer stand out.

Requirements:
- Each bio should be 100-200 words
- Use the provided profile information (name, experience, specializations, languages, awards, certifications) to create personalized content
- Maintain the core information from the original bio while enhancing it with profile details
- Make each version distinctly different in tone and approach
- Ensure all versions are authentic and professional
- Focus on how the astrologer can help clients
- Incorporate relevant specializations, experience, and credentials naturally
- Use the astrologer's name appropriately in the bio

Format your response as:
PROFESSIONAL: [bio text]
WARM: [bio text]  
MODERN: [bio text]
''';
  }

  static Map<String, String> _parseBioVersions(String content) {
    final lines = content.split('\n');
    final Map<String, String> versions = {};
    
    String currentVersion = '';
    String currentBio = '';
    
    for (String line in lines) {
      line = line.trim();
      
      if (line.startsWith('PROFESSIONAL:')) {
        if (currentVersion.isNotEmpty) {
          versions[currentVersion] = currentBio.trim();
        }
        currentVersion = 'Professional & Formal';
        currentBio = line.substring(13).trim();
      } else if (line.startsWith('WARM:')) {
        if (currentVersion.isNotEmpty) {
          versions[currentVersion] = currentBio.trim();
        }
        currentVersion = 'Warm & Personal';
        currentBio = line.substring(5).trim();
      } else if (line.startsWith('MODERN:')) {
        if (currentVersion.isNotEmpty) {
          versions[currentVersion] = currentBio.trim();
        }
        currentVersion = 'Modern & Engaging';
        currentBio = line.substring(7).trim();
      } else if (line.isNotEmpty && currentVersion.isNotEmpty) {
        currentBio += ' $line';
      }
    }
    
    // Add the last version
    if (currentVersion.isNotEmpty) {
      versions[currentVersion] = currentBio.trim();
    }
    
    return versions;
  }
}
