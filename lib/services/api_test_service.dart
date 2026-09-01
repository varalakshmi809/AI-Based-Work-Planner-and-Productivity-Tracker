import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiTestService {
  static const String _baseUrl = 'https://api.openai.com/v1/chat/completions';

  /// Test if OpenAI API connection is working
  static Future<Map<String, dynamic>> testApiConnection() async {
    final String? apiKey = dotenv.env['OPENAI_API_KEY'];

    print('🔍 API_TEST: Starting connection test...');

    // Check 1: API Key exists
    if (apiKey == null || apiKey.isEmpty) {
      print('❌ API_TEST: API Key is missing!');
      return {
        'success': false,
        'message': 'API Key is missing. Add OPENAI_API_KEY to assets/.env',
        'stage': 'API_KEY_CHECK',
      };
    }

    if (apiKey == 'your_api_key_here') {
      print('❌ API_TEST: API Key is still the default placeholder!');
      return {
        'success': false,
        'message':
            'API Key is still set to default. Replace with actual key in assets/.env',
        'stage': 'API_KEY_VALIDATION',
      };
    }

    print('✅ API_TEST: API Key found (${apiKey.length} chars)');

    // Check 2: Make test request
    try {
      print('📡 API_TEST: Sending test request to OpenAI...');
      final response = await http
          .post(
            Uri.parse(_baseUrl),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $apiKey',
            },
            body: jsonEncode({
              'model': 'gpt-4o-mini',
              'messages': [
                {
                  'role': 'user',
                  'content': 'Say "API Connection Successful" in one sentence.',
                },
              ],
            }),
          )
          .timeout(const Duration(seconds: 15));

      print('📩 API_TEST: Received response (Status: ${response.statusCode})');

      // Check 3: Parse response
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        final String content = data['choices'][0]['message']['content'];
        print('✅ API_TEST: Success! Response: $content');
        return {
          'success': true,
          'message': 'API connection is working!',
          'stage': 'SUCCESS',
          'response': content,
        };
      } else if (response.statusCode == 401) {
        print('❌ API_TEST: Unauthorized (401) - Invalid API Key');
        return {
          'success': false,
          'message': 'API Key is invalid or expired',
          'stage': 'AUTHENTICATION_FAILED',
          'statusCode': response.statusCode,
          'error': jsonDecode(response.body),
        };
      } else if (response.statusCode == 429) {
        print('❌ API_TEST: Rate limited (429)');
        return {
          'success': false,
          'message': 'Rate limited - Too many requests',
          'stage': 'RATE_LIMITED',
          'statusCode': response.statusCode,
        };
      } else {
        final errorBody = jsonDecode(response.body);
        print(
          '❌ API_TEST: Error ${response.statusCode} - ${errorBody['error']?['message']}',
        );
        return {
          'success': false,
          'message':
              'API Error: ${errorBody['error']?['message'] ?? 'Unknown error'}',
          'stage': 'API_ERROR',
          'statusCode': response.statusCode,
          'error': errorBody,
        };
      }
    } on http.ClientException catch (e) {
      print('❌ API_TEST: Network error - $e');
      return {
        'success': false,
        'message': 'Network error: ${e.message}',
        'stage': 'NETWORK_ERROR',
        'error': e.toString(),
      };
    } catch (e) {
      print('❌ API_TEST: Unexpected error - $e');
      return {
        'success': false,
        'message': 'Unexpected error: $e',
        'stage': 'UNEXPECTED_ERROR',
        'error': e.toString(),
      };
    }
  }
}
