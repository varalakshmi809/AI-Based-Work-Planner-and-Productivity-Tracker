import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AiService {
  static const String _baseUrl = 'https://api.openai.com/v1/chat/completions';

  static Future<Map<String, dynamic>> analyzeTaskPriority({
    required String taskTitle,
    required String description,
    required String priority,
    required String category,
    required String dueDate,
    required String dueTime,
    required int daysRemaining,
    required bool completed,
  }) async {
    final String? apiKey = dotenv.env['OPENAI_API_KEY'];

    print('AI_SERVICE: Checking API Key...');
    if (apiKey == null || apiKey.isEmpty || apiKey == 'your_api_key_here') {
      print('AI_SERVICE ERROR: API Key is missing or default string found.');
      throw Exception(
        'OpenAI API Key is missing. Please add it to assets/.env and perform a Hot Restart.',
      );
    }
    print('AI_SERVICE: API Key found (starts with ${apiKey.substring(0, 7)}...)');

    final String prompt = '''
Analyze the following task and recommend a priority (Low, Medium, or High) and provide a reason.

Task Details:
- Title: $taskTitle
- Description: $description
- User Selected Priority: $priority
- Category: $category
- Due Date: $dueDate
- Due Time: $dueTime
- Days Remaining: $daysRemaining
- Completed: $completed

Rules:
1. If a user selects Low priority but the task is due today or is overdue, recommend High priority.
2. If a task is due far in the future, do not automatically upgrade it.
3. Return the response in strictly JSON format: {"recommendedPriority": "High", "reason": "Explanation"}
''';

    try {
      print('AI_SERVICE: Sending request to OpenAI...');
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode({
          'model': 'gpt-4o-mini',
          'messages': [
            {'role': 'user', 'content': prompt},
          ],
          'response_format': {'type': 'json_object'},
        }),
      );

      print('AI_SERVICE: Received response with status code: ${response.statusCode}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        final String content = data['choices'][0]['message']['content'];
        print('AI_SERVICE: Success! AI Result: $content');
        return Map<String, dynamic>.from(jsonDecode(content));
      } else {
        final errorData = jsonDecode(response.body);
        print('AI_SERVICE ERROR: ${response.body}');
        throw Exception(
          'OpenAI API Error (${response.statusCode}): ${errorData['error']?['message'] ?? 'Unknown error'}',
        );
      }
    } catch (e) {
      print('AI_SERVICE EXCEPTION: $e');
      throw Exception('Failed to analyze task priority: $e');
    }
  }
}
