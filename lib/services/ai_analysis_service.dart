import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../models/task_analysis_response.dart';

class AIAnalysisService {
  static final FirebaseFunctions _functions = FirebaseFunctions.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static Future<TaskAnalysisResponse> analyzeTaskPriority({
    required String taskTitle,
    required String description,
    required String priority,
    required String category,
    required String dueDate,
    required String dueTime,
    required int daysRemaining,
    required bool completed,
  }) async {
    try {
      if (_auth.currentUser == null) {
        throw Exception('User must be authenticated to analyze tasks');
      }

      debugPrint('[AI Analysis] Calling analyzeTaskPriority function...');
      final HttpsCallable callable = _functions.httpsCallable('analyzeTaskPriority');
      final response = await callable.call({
        'taskTitle': taskTitle,
        'description': description,
        'priority': priority,
        'category': category,
        'dueDate': dueDate,
        'dueTime': dueTime,
        'daysRemaining': daysRemaining,
        'completed': completed,
      });

      debugPrint('[AI Analysis] Response received: ${response.data}');
      return TaskAnalysisResponse.fromJson(response.data);
    } catch (e) {
      debugPrint('[AI Analysis] Error: $e');
      rethrow;
    }
  }

  static Future<String> getAIRecommendation({
    required String taskTitle,
    required String priority,
    required String dueDate,
  }) async {
    try {
      final response = await analyzeTaskPriority(
        taskTitle: taskTitle,
        description: '',
        priority: priority,
        category: 'General',
        dueDate: dueDate,
        dueTime: '00:00',
        daysRemaining: _calculateDaysRemaining(dueDate),
        completed: false,
      );
      return response.reason;
    } catch (e) {
      return 'Unable to get AI recommendation';
    }
  }

  static int _calculateDaysRemaining(String dueDateString) {
    try {
      final dueDate = DateTime.parse(dueDateString);
      final now = DateTime.now();
      return dueDate.difference(now).inDays;
    } catch (e) {
      return 0;
    }
  }

  static bool isAnalysisAvailable() => _auth.currentUser != null;
  static String? getCurrentUserId() => _auth.currentUser?.uid;
}
