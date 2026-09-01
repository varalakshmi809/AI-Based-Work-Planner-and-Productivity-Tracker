import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AiTaskPriorityScreen extends StatelessWidget {
  const AiTaskPriorityScreen({super.key});

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
        return 1;
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
  // CALCULATE SMART SCORE
  // ============================================================

  int calculateSmartScore(Map<String, dynamic> data) {
    int score = 0;

    final priority = (data['priority'] ?? 'Medium').toString();

    final priorityScore = priorityValue(priority);

    // Priority contributes 30 points
    score += priorityScore * 30;

    // ----------------------------------------------------------
    // DUE DATE
    // ----------------------------------------------------------

    if (data['dueDate'] != null && data['dueDate'] is Timestamp) {
      final dueDate = (data['dueDate'] as Timestamp).toDate();

      final now = DateTime.now();

      final difference = DateTime(
        dueDate.year,
        dueDate.month,
        dueDate.day,
      ).difference(DateTime(now.year, now.month, now.day)).inDays;

      if (difference < 0) {
        // Overdue
        score += 50;
      } else if (difference == 0) {
        // Due today
        score += 45;
      } else if (difference == 1) {
        // Due tomorrow
        score += 35;
      } else if (difference <= 3) {
        score += 25;
      } else if (difference <= 7) {
        score += 15;
      } else {
        score += 5;
      }
    }

    // ----------------------------------------------------------
    // CATEGORY BONUS
    // ----------------------------------------------------------

    final category = (data['category'] ?? 'General').toString();

    if (category == 'Study') {
      score += 5;
    } else if (category == 'Work') {
      score += 5;
    } else if (category == 'Meeting') {
      score += 4;
    }

    return score;
  }

  // ============================================================
  // REASON FOR RANKING
  // ============================================================

  String rankingReason(Map<String, dynamic> data) {
    final List<String> reasons = [];

    final priority = (data['priority'] ?? 'Medium').toString();

    if (priority == 'High') {
      reasons.add('High priority');
    } else if (priority == 'Medium') {
      reasons.add('Medium priority');
    }

    if (data['dueDate'] != null && data['dueDate'] is Timestamp) {
      final dueDate = (data['dueDate'] as Timestamp).toDate();

      final now = DateTime.now();

      final today = DateTime(now.year, now.month, now.day);

      final due = DateTime(dueDate.year, dueDate.month, dueDate.day);

      final days = due.difference(today).inDays;

      if (days < 0) {
        reasons.add('Overdue');
      } else if (days == 0) {
        reasons.add('Due today');
      } else if (days == 1) {
        reasons.add('Due tomorrow');
      } else if (days <= 3) {
        reasons.add('Due soon');
      }
    }

    final category = (data['category'] ?? 'General').toString();

    if (category == 'Study') {
      reasons.add('Study task');
    } else if (category == 'Work') {
      reasons.add('Work task');
    }

    if (reasons.isEmpty) {
      return 'Normal priority task';
    }

    return reasons.join(' • ');
  }

  // ============================================================
  // DUE DATE TEXT
  // ============================================================

  String dueDateText(Map<String, dynamic> data) {
    if (data['dueDate'] == null || data['dueDate'] is! Timestamp) {
      return 'No due date';
    }

    final date = (data['dueDate'] as Timestamp).toDate();

    final now = DateTime.now();

    final today = DateTime(now.year, now.month, now.day);

    final due = DateTime(date.year, date.month, date.day);

    final days = due.difference(today).inDays;

    if (days < 0) {
      return 'Overdue';
    }

    if (days == 0) {
      return 'Due Today';
    }

    if (days == 1) {
      return 'Due Tomorrow';
    }

    return '${date.day}/${date.month}/${date.year}';
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
          'AI Task Priority',
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

          // ========================================================
          // ONLY PENDING TASKS
          // ========================================================

          final List<QueryDocumentSnapshot> pendingTasks = [];

          final List<QueryDocumentSnapshot> completedTasks = [];

          for (final doc in docs) {
            final data = doc.data() as Map<String, dynamic>;

            if (data['completed'] == true) {
              completedTasks.add(doc);
            } else {
              pendingTasks.add(doc);
            }
          }

          // ========================================================
          // SORT BY SMART SCORE
          // ========================================================

          pendingTasks.sort((a, b) {
            final dataA = a.data() as Map<String, dynamic>;

            final dataB = b.data() as Map<String, dynamic>;

            final scoreA = calculateSmartScore(dataA);

            final scoreB = calculateSmartScore(dataB);

            return scoreB.compareTo(scoreA);
          });

          // ========================================================
          // EMPTY STATE
          // ========================================================

          if (pendingTasks.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(25),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.emoji_events,
                      size: 85,
                      color: Colors.green,
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'All Tasks Completed!',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'There are no pending tasks for the AI to prioritize.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

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
                      colors: [Colors.blue.shade800, Colors.blue.shade400],
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
                              'AI Smart Ranking',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 12),
                      Text(
                        'Your tasks are automatically ranked based on priority, deadlines and task category.',
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
                // HOW IT WORKS
                // ==================================================
                Card(
                  elevation: 3,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(15),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.info_outline, color: Colors.blue),
                            SizedBox(width: 8),
                            Text(
                              'How AI Ranking Works',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _infoRow(
                          Icons.priority_high,
                          'Priority',
                          'High priority tasks receive a higher score.',
                        ),
                        _infoRow(
                          Icons.calendar_today,
                          'Deadline',
                          'Tasks with closer deadlines are ranked higher.',
                        ),
                        _infoRow(
                          Icons.warning,
                          'Overdue',
                          'Overdue tasks receive the highest urgency.',
                        ),
                        _infoRow(
                          Icons.category,
                          'Category',
                          'Study and work tasks receive a small relevance bonus.',
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // ==================================================
                // RANKED TASKS
                // ==================================================
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Recommended Task Order',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Text(
                        '${pendingTasks.length} Pending',
                        style: const TextStyle(
                          color: Colors.blue,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                ...List.generate(pendingTasks.length, (index) {
                  final task = pendingTasks[index];

                  final data = task.data() as Map<String, dynamic>;

                  final title = (data['title'] ?? 'Untitled Task').toString();

                  final description = (data['description'] ?? '').toString();

                  final priority = (data['priority'] ?? 'Medium').toString();

                  final category = (data['category'] ?? 'General').toString();

                  final score = calculateSmartScore(data);

                  final reason = rankingReason(data);

                  final due = dueDateText(data);

                  return _taskCard(
                    rank: index + 1,
                    title: title,
                    description: description,
                    priority: priority,
                    category: category,
                    score: score,
                    reason: reason,
                    dueDate: due,
                  );
                }),

                const SizedBox(height: 20),

                // ==================================================
                // FINAL TIP
                // ==================================================
                Card(
                  elevation: 3,
                  color: Colors.green.shade50,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.lightbulb,
                          color: Colors.green.shade700,
                          size: 30,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'AI Recommendation',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 17,
                                  color: Colors.green.shade800,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                'Start with the first task in the list. Completing urgent and important tasks first can help you manage your workload effectively.',
                                style: TextStyle(
                                  color: Colors.green.shade900,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
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
  // INFO ROW
  // ============================================================

  Widget _infoRow(IconData icon, String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.blue),
          const SizedBox(width: 10),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(color: Colors.black87, fontSize: 14),
                children: [
                  TextSpan(
                    text: '$title: ',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextSpan(text: description),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // TASK CARD
  // ============================================================

  Widget _taskCard({
    required int rank,
    required String title,
    required String description,
    required String priority,
    required String category,
    required int score,
    required String reason,
    required String dueDate,
  }) {
    final Color color = priorityColor(priority);

    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ------------------------------------------------------
            // RANK + TITLE
            // ------------------------------------------------------
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: rank == 1
                        ? Colors.amber
                        : Colors.blue.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '#$rank',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: rank == 1 ? Colors.white : Colors.blue,
                    ),
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
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (description.isNotEmpty) ...[
                        const SizedBox(height: 5),
                        Text(
                          description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: Colors.grey.shade700),
                        ),
                      ],
                    ],
                  ),
                ),

                // SCORE
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Text(
                        '$score',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                      Text(
                        'Score',
                        style: TextStyle(fontSize: 10, color: color),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            // ------------------------------------------------------
            // DETAILS
            // ------------------------------------------------------
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _chip(Icons.priority_high, priority, color),
                _chip(Icons.category, category, Colors.blue),
                _chip(
                  Icons.calendar_today,
                  dueDate,
                  dueDate == 'Overdue' ? Colors.red : Colors.purple,
                ),
              ],
            ),

            const SizedBox(height: 12),

            // ------------------------------------------------------
            // REASON
            // ------------------------------------------------------
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.auto_awesome, color: Colors.blue, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Why ranked here: $reason',
                      style: const TextStyle(fontSize: 13, height: 1.3),
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

  // ============================================================
  // CHIP
  // ============================================================

  Widget _chip(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 5),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
