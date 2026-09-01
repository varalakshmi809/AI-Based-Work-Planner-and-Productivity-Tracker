import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProductivityAnalyticsScreen extends StatelessWidget {
  const ProductivityAnalyticsScreen({super.key});

  // ============================================================
  // GET TASK DATA
  // ============================================================

  Future<Map<String, int>> getTaskStatistics() async {
    final snapshot = await FirebaseFirestore.instance.collection('tasks').get();

    int total = snapshot.docs.length;
    int completed = 0;
    int pending = 0;
    int overdue = 0;

    final now = DateTime.now();

    for (final doc in snapshot.docs) {
      final data = doc.data();

      final isCompleted = data['completed'] == true;

      if (isCompleted) {
        completed++;
      } else {
        pending++;

        DateTime? dueDate;

        final value = data['dueDate'];

        if (value is Timestamp) {
          dueDate = value.toDate();
        } else if (value is String) {
          dueDate = DateTime.tryParse(value);
        }

        if (dueDate != null && dueDate.isBefore(now)) {
          overdue++;
        }
      }
    }

    return {
      'total': total,
      'completed': completed,
      'pending': pending,
      'overdue': overdue,
    };
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
          'Productivity Analytics',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF17175F),
        foregroundColor: Colors.white,
      ),

      body: FutureBuilder<Map<String, int>>(
        future: getTaskStatistics(),

        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  'Error loading analytics:\n${snapshot.error}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            );
          }

          final stats =
              snapshot.data ??
              {'total': 0, 'completed': 0, 'pending': 0, 'overdue': 0};

          final total = stats['total'] ?? 0;
          final completed = stats['completed'] ?? 0;
          final pending = stats['pending'] ?? 0;
          final overdue = stats['overdue'] ?? 0;

          final double completionRate = total == 0 ? 0 : completed / total;

          final double percentage = completionRate * 100;

          return RefreshIndicator(
            onRefresh: () async {
              await Future.delayed(const Duration(milliseconds: 500));
            },

            child: ListView(
              padding: const EdgeInsets.all(12),
              children: [
                // ==================================================
                // HEADER
                // ==================================================
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.blue.shade800, Colors.lightBlue.shade400],
                    ),
                    borderRadius: BorderRadius.circular(18),
                  ),

                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.analytics,
                          color: Colors.white,
                          size: 30,
                        ),
                      ),

                      const SizedBox(width: 12),

                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Productivity Analytics',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),

                            SizedBox(height: 7),

                            Text(
                              'Track your tasks and understand your productivity performance.',
                              style: TextStyle(
                                color: Colors.white,
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

                const SizedBox(height: 16),

                // ==================================================
                // TASK OVERVIEW TITLE
                // ==================================================
                const Text(
                  'Task Overview',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 10),

                // ==================================================
                // STATISTICS GRID
                // ==================================================
                GridView.count(
                  crossAxisCount: 2,

                  // IMPORTANT:
                  // This prevents the card content from overflowing.
                  childAspectRatio: 1.65,

                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,

                  shrinkWrap: true,

                  physics: const NeverScrollableScrollPhysics(),

                  children: [
                    _statCard(
                      icon: Icons.task_alt,
                      title: 'Total Tasks',
                      value: total.toString(),
                      color: Colors.blue,
                    ),

                    _statCard(
                      icon: Icons.check_circle,
                      title: 'Completed',
                      value: completed.toString(),
                      color: Colors.green,
                    ),

                    _statCard(
                      icon: Icons.pending_actions,
                      title: 'Pending',
                      value: pending.toString(),
                      color: Colors.orange,
                    ),

                    _statCard(
                      icon: Icons.warning,
                      title: 'Overdue',
                      value: overdue.toString(),
                      color: Colors.red,
                    ),
                  ],
                ),

                const SizedBox(height: 22),

                // ==================================================
                // COMPLETION PROGRESS
                // ==================================================
                const Text(
                  'Completion Progress',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 10),

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    vertical: 25,
                    horizontal: 20,
                  ),

                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),

                  child: Column(
                    children: [
                      SizedBox(
                        width: 150,
                        height: 150,

                        child: Stack(
                          alignment: Alignment.center,

                          children: [
                            SizedBox(
                              width: 140,
                              height: 140,

                              child: CircularProgressIndicator(
                                value: completionRate,
                                strokeWidth: 10,
                                backgroundColor: Colors.grey.shade200,
                                valueColor: const AlwaysStoppedAnimation<Color>(
                                  Colors.blue,
                                ),
                              ),
                            ),

                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '${percentage.toStringAsFixed(1)}%',
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),

                                const SizedBox(height: 3),

                                Text(
                                  'Completed',
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 18),

                      Text(
                        '$completed of $total tasks completed',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),

                      const SizedBox(height: 8),

                      Text(
                        _getProgressMessage(percentage),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 22),

                // ==================================================
                // PRODUCTIVITY SUMMARY
                // ==================================================
                const Text(
                  'Productivity Summary',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 10),

                _summaryRow(
                  icon: Icons.check_circle,
                  title: 'Completed Tasks',
                  value: completed.toString(),
                  color: Colors.green,
                ),

                const SizedBox(height: 8),

                _summaryRow(
                  icon: Icons.pending_actions,
                  title: 'Pending Tasks',
                  value: pending.toString(),
                  color: Colors.orange,
                ),

                const SizedBox(height: 8),

                _summaryRow(
                  icon: Icons.warning,
                  title: 'Overdue Tasks',
                  value: overdue.toString(),
                  color: Colors.red,
                ),

                const SizedBox(height: 22),

                // ==================================================
                // PRODUCTIVITY TIPS
                // ==================================================
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.blue.shade100),
                  ),

                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.lightbulb, color: Colors.orange),
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

                      const SizedBox(height: 14),

                      _tip('Complete overdue tasks first.'),

                      _tip('Focus on high-priority tasks.'),

                      _tip('Break large tasks into smaller tasks.'),

                      _tip('Review your productivity regularly.'),
                    ],
                  ),
                ),

                const SizedBox(height: 25),
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

  Widget _statCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),

      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,

            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),

            child: Icon(icon, color: color, size: 24),
          ),

          const SizedBox(width: 10),

          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: color,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 2),

                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SUMMARY ROW
  // ============================================================

  Widget _summaryRow({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 5),
        ],
      ),

      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,

            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),

            child: Icon(icon, color: color, size: 22),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ),

          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // PRODUCTIVITY TIP
  // ============================================================

  Widget _tip(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),

      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle, color: Colors.green, size: 17),

          const SizedBox(width: 8),

          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 13, height: 1.3),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // PROGRESS MESSAGE
  // ============================================================

  String _getProgressMessage(double percentage) {
    if (percentage >= 90) {
      return 'Excellent! You are completing almost all your tasks.';
    }

    if (percentage >= 75) {
      return 'Great progress! Keep maintaining your productivity.';
    }

    if (percentage >= 50) {
      return 'Good progress. Try to complete more pending tasks.';
    }

    if (percentage > 0) {
      return 'Keep going! Focus on completing your pending tasks.';
    }

    return 'No tasks have been completed yet. Start completing your tasks to improve your productivity.';
  }
}
