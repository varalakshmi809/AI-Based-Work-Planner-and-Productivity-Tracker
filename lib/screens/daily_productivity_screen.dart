import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DailyProductivityScreen extends StatelessWidget {
  const DailyProductivityScreen({super.key});

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
  // GET PRIORITY COLOR
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
  // BUILD PRODUCTIVITY SUGGESTIONS
  // ============================================================

  List<String> generateSuggestions(List<Map<String, dynamic>> tasks) {
    final List<String> suggestions = [];

    int pending = 0;
    int completed = 0;
    int highPriority = 0;
    int overdue = 0;

    final now = DateTime.now();

    for (final task in tasks) {
      final bool isCompleted = task['completed'] == true;

      if (isCompleted) {
        completed++;
      } else {
        pending++;
      }

      final priority = (task['priority'] ?? 'Medium').toString();

      if (!isCompleted && priority == 'High') {
        highPriority++;
      }

      if (!isCompleted &&
          task['dueDate'] != null &&
          task['dueDate'] is Timestamp) {
        final dueDate = (task['dueDate'] as Timestamp).toDate();

        if (dueDate.isBefore(DateTime(now.year, now.month, now.day))) {
          overdue++;
        }
      }
    }

    // ----------------------------------------------------------
    // SUGGESTIONS
    // ----------------------------------------------------------

    if (overdue > 0) {
      suggestions.add(
        '⚠️ You have $overdue overdue task(s). Complete them first.',
      );
    }

    if (highPriority > 0) {
      suggestions.add(
        '🔥 Focus on your $highPriority high-priority task(s) first.',
      );
    }

    if (pending > 5) {
      suggestions.add(
        '📋 You have many pending tasks. Divide them into smaller goals.',
      );
    } else if (pending > 0) {
      suggestions.add(
        '🎯 Try completing your most important task before starting a new one.',
      );
    }

    if (completed >= 3) {
      suggestions.add(
        '👏 Great progress! You have completed $completed task(s).',
      );
    }

    if (completed == 0 && pending > 0) {
      suggestions.add('🚀 Start with one small task to build momentum.');
    }

    if (pending == 0 && completed > 0) {
      suggestions.add('🏆 Excellent! You have completed all your tasks.');
    }

    suggestions.add('⏰ Take short breaks between tasks to maintain focus.');

    suggestions.add('💡 Review your pending tasks at the end of the day.');

    return suggestions;
  }

  // ============================================================
  // PRODUCTIVITY SCORE
  // ============================================================

  int calculateProductivityScore(int completed, int pending) {
    final total = completed + pending;

    if (total == 0) {
      return 0;
    }

    final score = ((completed / total) * 100).round();

    return score.clamp(0, 100);
  }

  // ============================================================
  // SCORE COLOR
  // ============================================================

  Color scoreColor(int score) {
    if (score >= 80) {
      return Colors.green;
    }

    if (score >= 50) {
      return Colors.orange;
    }

    return Colors.red;
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),

      appBar: AppBar(
        title: const Text(
          'Daily Productivity',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF17175F),
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

          final List<Map<String, dynamic>> tasks = [];

          for (final doc in docs) {
            final data = doc.data() as Map<String, dynamic>;

            tasks.add(data);
          }

          int completed = 0;
          int pending = 0;
          int highPriority = 0;
          int overdue = 0;

          final now = DateTime.now();

          for (final task in tasks) {
            final bool isCompleted = task['completed'] == true;

            if (isCompleted) {
              completed++;
            } else {
              pending++;
            }

            final priority = (task['priority'] ?? 'Medium').toString();

            if (!isCompleted && priority == 'High') {
              highPriority++;
            }

            if (!isCompleted &&
                task['dueDate'] != null &&
                task['dueDate'] is Timestamp) {
              final dueDate = (task['dueDate'] as Timestamp).toDate();

              if (dueDate.isBefore(DateTime(now.year, now.month, now.day))) {
                overdue++;
              }
            }
          }

          final score = calculateProductivityScore(completed, pending);

          final suggestions = generateSuggestions(tasks);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ==================================================
                // HEADER
                // ==================================================
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.blue.shade700, Colors.blue.shade400],
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
                          Text(
                            'Your Daily Plan',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 10),
                      Text(
                        'Here is your smart productivity summary based on your current tasks.',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // ==================================================
                // PRODUCTIVITY SCORE
                // ==================================================
                const Text(
                  'Productivity Score',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 10),

                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 100,
                          height: 100,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              SizedBox(
                                width: 90,
                                height: 90,
                                child: CircularProgressIndicator(
                                  value: score / 100,
                                  strokeWidth: 9,
                                  backgroundColor: Colors.grey.shade200,
                                  color: scoreColor(score),
                                ),
                              ),
                              Text(
                                '$score%',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: scoreColor(score),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(width: 20),

                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                score >= 80
                                    ? 'Excellent Work!'
                                    : score >= 50
                                    ? 'Good Progress!'
                                    : 'Let’s Get Started!',
                                style: const TextStyle(
                                  fontSize: 19,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 7),
                              Text(
                                '$completed completed • $pending pending',
                                style: TextStyle(color: Colors.grey.shade700),
                              ),
                            ],
                          ),
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
                  'Task Summary',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 10),

                Row(
                  children: [
                    Expanded(
                      child: _summaryCard(
                        'Completed',
                        completed,
                        Icons.check_circle,
                        Colors.green,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _summaryCard(
                        'Pending',
                        pending,
                        Icons.pending_actions,
                        Colors.orange,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                Row(
                  children: [
                    Expanded(
                      child: _summaryCard(
                        'High Priority',
                        highPriority,
                        Icons.priority_high,
                        Colors.red,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _summaryCard(
                        'Overdue',
                        overdue,
                        Icons.warning,
                        Colors.deepOrange,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // ==================================================
                // AI SUGGESTIONS
                // ==================================================
                const Text(
                  'Smart Suggestions',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 10),

                ...suggestions.map((suggestion) {
                  return Card(
                    elevation: 2,
                    margin: const EdgeInsets.only(bottom: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(15),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.lightbulb, color: Colors.amber),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              suggestion,
                              style: const TextStyle(fontSize: 15, height: 1.4),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),

                const SizedBox(height: 20),

                // ==================================================
                // DAILY PLAN
                // ==================================================
                const Text(
                  'Recommended Plan',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 10),

                _planItem(
                  number: '1',
                  title: 'Complete overdue tasks',
                  subtitle:
                      'Finish tasks that have already passed their due date.',
                  icon: Icons.warning,
                  color: Colors.red,
                ),

                _planItem(
                  number: '2',
                  title: 'Focus on high-priority tasks',
                  subtitle:
                      'Work on important tasks before low-priority activities.',
                  icon: Icons.priority_high,
                  color: Colors.orange,
                ),

                _planItem(
                  number: '3',
                  title: 'Complete medium-priority tasks',
                  subtitle: 'Continue with regular tasks after important work.',
                  icon: Icons.task_alt,
                  color: Colors.blue,
                ),

                _planItem(
                  number: '4',
                  title: 'Review your progress',
                  subtitle:
                      'Check completed and pending tasks at the end of the day.',
                  icon: Icons.insights,
                  color: Colors.green,
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

  Widget _summaryCard(String title, int value, IconData icon, Color color) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              '$value',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // PLAN ITEM
  // ============================================================

  Widget _planItem({
    required String number,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 45,
              height: 45,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Text(
                number,
                style: TextStyle(
                  color: color,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            const SizedBox(width: 12),

            Icon(icon, color: color, size: 28),

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
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      fontSize: 13,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
