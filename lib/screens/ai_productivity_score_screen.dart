import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AiProductivityScoreScreen extends StatelessWidget {
  const AiProductivityScoreScreen({super.key});

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
  // GET SCORE COLOR
  // ============================================================

  Color scoreColor(double score) {
    if (score >= 80) {
      return Colors.green;
    } else if (score >= 60) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }

  // ============================================================
  // GET PRODUCTIVITY LEVEL
  // ============================================================

  String productivityLevel(double score) {
    if (score >= 90) {
      return 'Excellent';
    } else if (score >= 75) {
      return 'Very Good';
    } else if (score >= 60) {
      return 'Good';
    } else if (score >= 40) {
      return 'Average';
    } else {
      return 'Needs Improvement';
    }
  }

  // ============================================================
  // GET MESSAGE
  // ============================================================

  String productivityMessage(double score) {
    if (score >= 90) {
      return 'Excellent productivity! Keep maintaining this performance.';
    }

    if (score >= 75) {
      return 'Great work! You are managing your tasks effectively.';
    }

    if (score >= 60) {
      return 'Good progress. Try completing more pending tasks.';
    }

    if (score >= 40) {
      return 'You are making progress. Focus on high-priority tasks first.';
    }

    return 'Try to complete your urgent and overdue tasks first.';
  }

  // ============================================================
  // CALCULATE SCORE
  // ============================================================

  double calculateScore({
    required int totalTasks,
    required int completedTasks,
    required int overdueTasks,
    required int highPriorityCompleted,
  }) {
    if (totalTasks == 0) {
      return 0;
    }

    double completionScore = (completedTasks / totalTasks) * 100;

    double priorityBonus = highPriorityCompleted * 2;

    double overduePenalty = overdueTasks * 3;

    double score = completionScore + priorityBonus - overduePenalty;

    if (score > 100) {
      score = 100;
    }

    if (score < 0) {
      score = 0;
    }

    return score;
  }

  // ============================================================
  // GET DUE DATE
  // ============================================================

  DateTime? getDueDate(Map<String, dynamic> data) {
    final value = data['dueDate'];

    if (value is Timestamp) {
      return value.toDate();
    }

    if (value is String) {
      return DateTime.tryParse(value);
    }

    return null;
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
          'AI Productivity Score',
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
          // TASK COUNTS
          // ========================================================

          int totalTasks = docs.length;
          int completedTasks = 0;
          int pendingTasks = 0;
          int overdueTasks = 0;
          int highPriorityCompleted = 0;

          final now = DateTime.now();

          for (final doc in docs) {
            final data = doc.data() as Map<String, dynamic>;

            final completed = data['completed'] == true;

            final priority = (data['priority'] ?? 'Medium').toString();

            if (completed) {
              completedTasks++;

              if (priority.toLowerCase() == 'high') {
                highPriorityCompleted++;
              }
            } else {
              pendingTasks++;

              final dueDate = getDueDate(data);

              if (dueDate != null && dueDate.isBefore(now)) {
                overdueTasks++;
              }
            }
          }

          // ========================================================
          // SCORE
          // ========================================================

          final score = calculateScore(
            totalTasks: totalTasks,
            completedTasks: completedTasks,
            overdueTasks: overdueTasks,
            highPriorityCompleted: highPriorityCompleted,
          );

          final level = productivityLevel(score);

          final message = productivityMessage(score);

          final color = scoreColor(score);

          final completionPercentage = totalTasks == 0
              ? 0.0
              : (completedTasks / totalTasks) * 100;

          // ========================================================
          // BODY
          // ========================================================

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
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
                        Colors.blue.shade700,
                        Colors.deepPurple.shade600,
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
                              'AI Productivity Analysis',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 10),
                      Text(
                        'Your productivity score is automatically calculated from your task performance.',
                        style: TextStyle(color: Colors.white, fontSize: 14),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 25),

                // ==================================================
                // SCORE CIRCLE
                // ==================================================
                Container(
                  width: 240,
                  height: 240,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: color.withValues(alpha: 0.25),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 210,
                        height: 210,
                        child: CircularProgressIndicator(
                          value: score / 100,
                          strokeWidth: 17,
                          backgroundColor: Colors.grey.shade200,
                          valueColor: AlwaysStoppedAnimation<Color>(color),
                        ),
                      ),

                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            score.toStringAsFixed(0),
                            style: TextStyle(
                              fontSize: 48,
                              fontWeight: FontWeight.bold,
                              color: color,
                            ),
                          ),
                          const Text(
                            'out of 100',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 18),

                // ==================================================
                // LEVEL
                // ==================================================
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 9,
                  ),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    level,
                    style: TextStyle(
                      color: color,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                const SizedBox(height: 18),

                // ==================================================
                // AI MESSAGE
                // ==================================================
                Card(
                  elevation: 3,
                  color: Colors.blue.shade50,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.lightbulb,
                          color: Colors.orange,
                          size: 28,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            message,
                            style: const TextStyle(fontSize: 15, height: 1.4),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 25),

                // ==================================================
                // STATISTICS
                // ==================================================
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Performance Overview',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),

                const SizedBox(height: 12),

                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.45,
                  children: [
                    _statCard(
                      Icons.task,
                      'Total Tasks',
                      totalTasks.toString(),
                      Colors.blue,
                    ),
                    _statCard(
                      Icons.check_circle,
                      'Completed',
                      completedTasks.toString(),
                      Colors.green,
                    ),
                    _statCard(
                      Icons.pending_actions,
                      'Pending',
                      pendingTasks.toString(),
                      Colors.orange,
                    ),
                    _statCard(
                      Icons.warning,
                      'Overdue',
                      overdueTasks.toString(),
                      Colors.red,
                    ),
                  ],
                ),

                const SizedBox(height: 25),

                // ==================================================
                // COMPLETION RATE
                // ==================================================
                Card(
                  elevation: 3,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Task Completion Rate',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '${completionPercentage.toStringAsFixed(0)}%',
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),

                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: LinearProgressIndicator(
                            value: completionPercentage / 100,
                            minHeight: 12,
                            backgroundColor: Colors.grey.shade200,
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              Colors.green,
                            ),
                          ),
                        ),

                        const SizedBox(height: 10),

                        Text(
                          '$completedTasks of $totalTasks tasks completed',
                          style: TextStyle(color: Colors.grey.shade700),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // ==================================================
                // HIGH PRIORITY
                // ==================================================
                Card(
                  elevation: 3,
                  child: ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: Colors.red,
                      child: Icon(Icons.priority_high, color: Colors.white),
                    ),
                    title: const Text(
                      'High-Priority Tasks Completed',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: const Text('Important tasks completed'),
                    trailing: Text(
                      highPriorityCompleted.toString(),
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // ==================================================
                // SCORE FORMULA
                // ==================================================
                Card(
                  elevation: 3,
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.calculate, color: Colors.blue),
                            SizedBox(width: 8),
                            Text(
                              'Score Calculation',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 15),

                        _formulaRow(
                          'Completion',
                          'Completed tasks increase the score.',
                        ),

                        _formulaRow(
                          'Priority',
                          'High-priority completed tasks receive bonus points.',
                        ),

                        _formulaRow(
                          'Overdue',
                          'Overdue tasks reduce the score.',
                        ),

                        _formulaRow(
                          'Limit',
                          'Final score remains between 0 and 100.',
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                Text(
                  'The score updates automatically when Firestore tasks change.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
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
  // STAT CARD
  // ============================================================

  Widget _statCard(IconData icon, String title, String value, Color color) {
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
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 27),
              const Spacer(),
              Text(
                value,
                style: TextStyle(
                  color: color,
                  fontSize: 25,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Text(
            title,
            style: TextStyle(
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // FORMULA ROW
  // ============================================================

  Widget _formulaRow(String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle, color: Colors.green, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
