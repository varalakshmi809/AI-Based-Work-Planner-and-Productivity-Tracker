import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AiRecommendationScreen extends StatelessWidget {
  const AiRecommendationScreen({super.key});

  // ============================================================
  // PRIORITY VALUE
  // ============================================================

  int priorityValue(String priority) {
    switch (priority.toLowerCase()) {
      case 'high':
        return 3;
      case 'medium':
        return 2;
      case 'low':
        return 1;
      default:
        return 0;
    }
  }

  // ============================================================
  // PRIORITY COLOR
  // ============================================================

  Color priorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      case 'low':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  // ============================================================
  // GET DUE DATE
  // ============================================================

  DateTime? getDueDate(Map<String, dynamic> data) {
    final value = data['dueDate'];

    if (value is Timestamp) {
      return value.toDate();
    }

    return null;
  }

  // ============================================================
  // CHECK OVERDUE
  // ============================================================

  bool isOverdue(Map<String, dynamic> data) {
    final dueDate = getDueDate(data);

    if (dueDate == null) {
      return false;
    }

    final completed = data['completed'] == true;

    if (completed) {
      return false;
    }

    return dueDate.isBefore(DateTime.now());
  }

  // ============================================================
  // GET RECOMMENDATION
  // ============================================================

  String getRecommendation(List<QueryDocumentSnapshot> docs) {
    if (docs.isEmpty) {
      return 'You have no tasks yet. Add a task to start planning your work.';
    }

    int pending = 0;
    int overdue = 0;
    int highPriority = 0;

    for (final doc in docs) {
      final data = doc.data() as Map<String, dynamic>;

      final completed = data['completed'] == true;

      if (!completed) {
        pending++;

        final priority = (data['priority'] ?? 'Medium').toString();

        if (priority.toLowerCase() == 'high') {
          highPriority++;
        }

        if (isOverdue(data)) {
          overdue++;
        }
      }
    }

    if (overdue > 0) {
      return 'You have $overdue overdue task(s). Complete them first to stay on schedule.';
    }

    if (highPriority > 0) {
      return 'Focus on your $highPriority high-priority pending task(s) before starting lower-priority work.';
    }

    if (pending > 0) {
      return 'You have $pending pending task(s). Start with the task having the nearest deadline.';
    }

    return 'Excellent! All your tasks are completed. You are doing great.';
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,

      appBar: AppBar(
        title: const Text(
          'AI Recommendations',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),

      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('tasks').snapshots(),

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
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            );
          }

          final docs = snapshot.data?.docs ?? [];

          // ========================================================
          // FIND IMPORTANT TASKS
          // ========================================================

          final pendingTasks = docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;

            return data['completed'] != true;
          }).toList();

          final overdueTasks = pendingTasks.where((doc) {
            final data = doc.data() as Map<String, dynamic>;

            return isOverdue(data);
          }).toList();

          final highPriorityTasks = pendingTasks.where((doc) {
            final data = doc.data() as Map<String, dynamic>;

            final priority = (data['priority'] ?? 'Medium').toString();

            return priority.toLowerCase() == 'high';
          }).toList();

          // ========================================================
          // SORT PENDING TASKS
          // ========================================================

          pendingTasks.sort((a, b) {
            final dataA = a.data() as Map<String, dynamic>;

            final dataB = b.data() as Map<String, dynamic>;

            final priorityA = priorityValue(
              (dataA['priority'] ?? 'Medium').toString(),
            );

            final priorityB = priorityValue(
              (dataB['priority'] ?? 'Medium').toString(),
            );

            return priorityB.compareTo(priorityA);
          });

          final recommendation = getRecommendation(docs);

          return RefreshIndicator(
            onRefresh: () async {
              await Future.delayed(const Duration(milliseconds: 500));
            },
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // ==================================================
                // AI HEADER
                // ==================================================
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF17175F),
                        const Color(0xFFA66CC7),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.auto_awesome,
                            color: Colors.white,
                            size: 35,
                          ),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'AI Task Recommendations',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 23,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 10),
                      Text(
                        'AI analyzes your tasks and recommends what you should focus on next.',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // ==================================================
                // MAIN RECOMMENDATION
                // ==================================================
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(
                              Icons.lightbulb,
                              color: Colors.orange,
                              size: 30,
                            ),
                            SizedBox(width: 10),
                            Text(
                              'AI Suggestion',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 15),
                        Text(
                          recommendation,
                          style: const TextStyle(fontSize: 16, height: 1.5),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // ==================================================
                // SUMMARY
                // ==================================================
                const Text(
                  'Task Analysis',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: _summaryCard(
                        Icons.pending_actions,
                        'Pending',
                        pendingTasks.length.toString(),
                        Colors.orange,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _summaryCard(
                        Icons.warning,
                        'Overdue',
                        overdueTasks.length.toString(),
                        Colors.red,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                Row(
                  children: [
                    Expanded(
                      child: _summaryCard(
                        Icons.priority_high,
                        'High Priority',
                        highPriorityTasks.length.toString(),
                        Colors.deepPurple,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _summaryCard(
                        Icons.task_alt,
                        'Total',
                        docs.length.toString(),
                        Colors.blue,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 25),

                // ==================================================
                // OVERDUE TASKS
                // ==================================================
                if (overdueTasks.isNotEmpty) ...[
                  const Text(
                    '🔴 Complete These First',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),

                  ...overdueTasks.take(5).map((doc) {
                    final data = doc.data() as Map<String, dynamic>;

                    return _taskCard(data, 'Overdue', Colors.red);
                  }),

                  const SizedBox(height: 20),
                ],

                // ==================================================
                // HIGH PRIORITY
                // ==================================================
                if (highPriorityTasks.isNotEmpty) ...[
                  const Text(
                    '🔥 High Priority Tasks',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),

                  ...highPriorityTasks.take(5).map((doc) {
                    final data = doc.data() as Map<String, dynamic>;

                    return _taskCard(data, 'High Priority', Colors.deepPurple);
                  }),

                  const SizedBox(height: 20),
                ],

                // ==================================================
                // NEXT TASKS
                // ==================================================
                if (pendingTasks.isNotEmpty) ...[
                  const Text(
                    '📌 Recommended Next Tasks',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),

                  ...pendingTasks.take(5).map((doc) {
                    final data = doc.data() as Map<String, dynamic>;

                    return _taskCard(data, 'Recommended', Colors.blue);
                  }),
                ],

                // ==================================================
                // NO PENDING TASKS
                // ==================================================
                if (pendingTasks.isEmpty)
                  Card(
                    elevation: 3,
                    child: Padding(
                      padding: const EdgeInsets.all(25),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.celebration,
                            color: Colors.green,
                            size: 55,
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'All Tasks Completed!',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Great work! You have no pending tasks.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey.shade700),
                          ),
                        ],
                      ),
                    ),
                  ),

                const SizedBox(height: 20),

                // ==================================================
                // AI TIPS
                // ==================================================
                Card(
                  color: Colors.blue.shade50,
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.tips_and_updates, color: Colors.orange),
                            SizedBox(width: 8),
                            Text(
                              'Productivity Tips',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),

                        _tip(
                          'Complete overdue tasks before starting new work.',
                        ),

                        _tip('Focus on high-priority tasks first.'),

                        _tip(
                          'Break large tasks into smaller achievable tasks.',
                        ),

                        _tip('Review your productivity score regularly.'),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                Center(
                  child: Text(
                    'Recommendations update automatically from your Firestore tasks.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                  ),
                ),

                const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
    );
  }

  // ============================================================
  // SUMMARY CARD
  // ============================================================

  Widget _summaryCard(IconData icon, String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 25,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(title, style: TextStyle(color: Colors.grey.shade700)),
        ],
      ),
    );
  }

  // ============================================================
  // TASK CARD
  // ============================================================

  Widget _taskCard(Map<String, dynamic> data, String label, Color labelColor) {
    final title = (data['title'] ?? 'Untitled Task').toString();

    final priority = (data['priority'] ?? 'Medium').toString();

    final category = (data['category'] ?? 'General').toString();

    String dueDate = '';

    if (data['dueDate'] is Timestamp) {
      final date = (data['dueDate'] as Timestamp).toDate();

      dueDate = '${date.day}/${date.month}/${date.year}';
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 5,
              height: 65,
              decoration: BoxDecoration(
                color: priorityColor(priority),
                borderRadius: BorderRadius.circular(5),
              ),
            ),

            const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 6),

                  Text(
                    '$category • $priority',
                    style: TextStyle(
                      color: priorityColor(priority),
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  if (dueDate.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        'Due: $dueDate',
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontSize: 13,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              decoration: BoxDecoration(
                color: labelColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                label,
                style: TextStyle(
                  color: labelColor,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // TIP
  // ============================================================

  Widget _tip(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle, color: Colors.green, size: 18),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: const TextStyle(height: 1.3))),
        ],
      ),
    );
  }
}
