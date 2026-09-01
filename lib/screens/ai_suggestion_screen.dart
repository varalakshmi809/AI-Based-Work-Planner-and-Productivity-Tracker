import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/ai_service.dart';

class AiSuggestionScreen extends StatefulWidget {
  const AiSuggestionScreen({super.key});

  @override
  State<AiSuggestionScreen> createState() => _AiSuggestionScreenState();
}

class _AiSuggestionScreenState extends State<AiSuggestionScreen> {
  Map<String, dynamic>? aiResponse;
  bool isAnalyzing = false;
  String? error;

  // ============================================================
  // PRIORITY VALUE
  // ============================================================

  int priorityValue(String priority) {
    switch (priority) {
      case 'High':
        return 3;
      case 'Medium':
        return 2;
      case 'Low':
        return 1;
      default:
        return 0;
    }
  }

  // ============================================================
  // PRIORITY COLOR
  // ============================================================

  Color priorityColor(String priority) {
    switch (priority) {
      case 'High':
        return Colors.red;
      case 'Medium':
        return Colors.orange;
      case 'Low':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  // ============================================================
  // GET DUE DATE
  // ============================================================

  DateTime? getDueDate(Map<String, dynamic> data) {
    final dynamic value = data['dueDate'];
    if (value is Timestamp) {
      return value.toDate();
    }
    return null;
  }

  // ============================================================
  // CALL AI SERVICE
  // ============================================================

  Future<void> analyzeTask(Map<String, dynamic> data) async {
    setState(() {
      isAnalyzing = true;
      error = null;
    });

    try {
      final dueDateValue = getDueDate(data);
      final now = DateTime.now();
      final daysRemaining =
          dueDateValue != null ? dueDateValue.difference(now).inDays : 999;

      final response = await AiService.analyzeTaskPriority(
        taskTitle: data['title']?.toString() ?? 'Untitled',
        description: data['description']?.toString() ?? '',
        priority: data['priority']?.toString() ?? 'Medium',
        category: data['category']?.toString() ?? 'General',
        dueDate: dueDateValue?.toString() ?? 'Not set',
        dueTime: data['dueTime']?.toString() ?? 'Not set',
        daysRemaining: daysRemaining,
        completed: data['completed'] == true,
      );

      if (mounted) {
        setState(() {
          aiResponse = response;
          isAnalyzing = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          error = e.toString();
          isAnalyzing = false;
        });
      }
    }
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final User? user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF5F7FB),
        appBar: AppBar(
          title: const Text(
            'AI Suggestions',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
          backgroundColor: const Color(0xFF17175F),
          foregroundColor: Colors.white,
        ),
        body: const Center(child: Text('Please login to view AI suggestions.')),
      );
    }

    final Stream<QuerySnapshot<Map<String, dynamic>>> taskStream =
        FirebaseFirestore.instance
            .collection('tasks')
            .where('userId', isEqualTo: user.uid)
            .where('completed', isEqualTo: false)
            .snapshots();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        title: const Text(
          'AI Suggestions',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF17175F),
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: taskStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  'Error loading tasks:\n${snapshot.error}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red, fontSize: 16),
                ),
              ),
            );
          }

          final List<QueryDocumentSnapshot<Map<String, dynamic>>> docs = [
            ...(snapshot.data?.docs ?? []),
          ];

          if (docs.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(25),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(25),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.10),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check_circle,
                        size: 75,
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'No Pending Tasks',
                      style:
                          TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Great job! You have completed all your tasks.',
                      textAlign: TextAlign.center,
                      style:
                          TextStyle(fontSize: 15, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
            );
          }

          // Sort by priority and date
          docs.sort((a, b) {
            final dataA = a.data();
            final dataB = b.data();
            final priorityA = (dataA['priority'] ?? 'Medium').toString();
            final priorityB = (dataB['priority'] ?? 'Medium').toString();
            final int priorityComparison =
                priorityValue(priorityB).compareTo(priorityValue(priorityA));

            if (priorityComparison != 0) return priorityComparison;

            final dateA = getDueDate(dataA);
            final dateB = getDueDate(dataB);
            if (dateA != null && dateB != null) return dateA.compareTo(dateB);
            if (dateA != null) return -1;
            if (dateB != null) return 1;
            return 0;
          });

          final QueryDocumentSnapshot<Map<String, dynamic>> recommendedTask =
              docs.first;
          final Map<String, dynamic> data = recommendedTask.data();

          final String title = (data['title'] ?? 'No Title').toString();
          final String description = (data['description'] ?? '').toString();
          final String userPriority = (data['priority'] ?? 'Medium').toString();
          final String category = (data['category'] ?? 'General').toString();
          final String dueTime = (data['dueTime'] ?? '').toString();
          final DateTime? dueDateValue = getDueDate(data);
          final now = DateTime.now();
          final daysRemaining =
              dueDateValue != null ? dueDateValue.difference(now).inDays : -1;

          String dueDateStr = '';
          if (dueDateValue != null) {
            dueDateStr =
                '${dueDateValue.day}/${dueDateValue.month}/${dueDateValue.year}';
          }

          // Auto-trigger analysis if not already done for this task
          if (aiResponse == null && !isAnalyzing && error == null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              analyzeTask(data);
            });
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(18),
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF17175F), Color(0xFF4F46E5)],
                    ),
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.psychology, size: 65, color: Colors.white),
                      const SizedBox(height: 12),
                      const Text(
                        'AI Recommendation',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        isAnalyzing
                            ? 'AI analyzing your task parameters...'
                            : error != null
                                ? 'AI Analysis Failed'
                                : aiResponse != null
                                    ? 'AI Analysis Complete'
                                    : 'Ready for Analysis',
                        style: const TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.amber.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.star, color: Colors.amber),
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Text(
                                'Recommended Task',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            if (!isAnalyzing)
                              IconButton(
                                icon: const Icon(Icons.refresh, color: Color(0xFF17175F)),
                                onPressed: () => analyzeTask(data),
                                tooltip: 'Re-analyze',
                              ),
                          ],
                        ),
                        const Divider(height: 30),
                        _detail(Icons.task_alt, 'Task', title),
                        if (description.isNotEmpty)
                          _detail(
                            Icons.description_outlined,
                            'Description',
                            description,
                          ),
                        _detail(
                          Icons.priority_high,
                          'User Priority',
                          userPriority,
                          color: priorityColor(userPriority),
                        ),
                        if (aiResponse != null)
                          _detail(
                            Icons.auto_awesome,
                            'AI Recommended Priority',
                            aiResponse!['recommendedPriority'],
                            color: priorityColor(
                              aiResponse!['recommendedPriority'],
                            ),
                          ),
                        _detail(Icons.category_outlined, 'Category', category),
                        if (dueDateStr.isNotEmpty)
                          _detail(
                            Icons.calendar_today_outlined,
                            'Due Date',
                            dueDateStr,
                          ),
                        if (dueTime.isNotEmpty)
                          _detail(Icons.access_time, 'Due Time', dueTime),
                        if (daysRemaining != -1)
                          _detail(
                            Icons.timer_outlined,
                            'Days Remaining',
                            daysRemaining.toString(),
                          ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 18),

                if (isAnalyzing)
                  const Column(
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 10),
                      Text('AI is thinking...'),
                    ],
                  )
                else if (error != null)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.error_outline, color: Colors.red, size: 40),
                        const SizedBox(height: 8),
                        Text(
                          'Analysis Failed',
                          style: TextStyle(
                              color: Colors.red.shade900,
                              fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          error!,
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.red.shade700, fontSize: 13),
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: () => analyzeTask(data),
                          child: const Text('Try Again'),
                        ),
                      ],
                    ),
                  )
                else if (aiResponse != null) ...[
                  // AI Priority Alert
                  if (userPriority != aiResponse!['recommendedPriority'])
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 18),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.warning_amber_rounded,
                                  color: Colors.red),
                              SizedBox(width: 8),
                              Text(
                                'AI Priority Alert',
                                style: TextStyle(
                                  color: Colors.red,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'You marked this task as $userPriority priority, but AI recommends treating it as ${aiResponse!['recommendedPriority']} priority because the deadline is very close.',
                            style: TextStyle(color: Colors.red.shade900),
                          ),
                        ],
                      ),
                    ),

                  // AI Suggestion Box
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.blue.shade100),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.smart_toy, color: Colors.blue, size: 28),
                            SizedBox(width: 10),
                            Text(
                              'AI Reason',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 15),
                        Text(
                          aiResponse!['reason'] ?? 'No reason provided',
                          style: const TextStyle(fontSize: 16, height: 1.5),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 20),

                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.check_circle_outline),
                    label: const Text(
                      'Mark Task as Completed',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: () async {
                      try {
                        await FirebaseFirestore.instance
                            .collection('tasks')
                            .doc(recommendedTask.id)
                            .update({'completed': true});

                        if (!context.mounted) return;

                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Task completed successfully!'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      } catch (e) {
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text('Error: $e'),
                              backgroundColor: Colors.red),
                        );
                      }
                    },
                  ),
                ),

                const SizedBox(height: 12),

                Text(
                  'AI analyzes priority and due dates to recommend what you should work on next.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _detail(IconData icon, String title, String value,
      {Color color = Colors.blue}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 23),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: color == Colors.blue ? Colors.black87 : color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
