import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProductivityInsightsScreen extends StatelessWidget {
  const ProductivityInsightsScreen({super.key});

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
  // BUILD SCREEN
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),

      appBar: AppBar(
        title: const Text(
          'Productivity Insights',
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

          int totalTasks = docs.length;
          int completedTasks = 0;
          int pendingTasks = 0;
          int highPriorityTasks = 0;
          int mediumPriorityTasks = 0;
          int lowPriorityTasks = 0;

          int studyTasks = 0;
          int workTasks = 0;
          int personalTasks = 0;
          int shoppingTasks = 0;
          int meetingTasks = 0;

          int overdueTasks = 0;

          final now = DateTime.now();

          // ========================================================
          // ANALYZE TASKS
          // ========================================================

          for (final doc in docs) {
            final data = doc.data() as Map<String, dynamic>;

            final bool completed = data['completed'] == true;

            final String priority = (data['priority'] ?? 'Medium').toString();

            final String category = (data['category'] ?? 'General').toString();

            if (completed) {
              completedTasks++;
            } else {
              pendingTasks++;
            }

            // Priority
            if (priority == 'High') {
              highPriorityTasks++;
            } else if (priority == 'Medium') {
              mediumPriorityTasks++;
            } else if (priority == 'Low') {
              lowPriorityTasks++;
            }

            // Category
            switch (category) {
              case 'Study':
                studyTasks++;
                break;
              case 'Work':
                workTasks++;
                break;
              case 'Personal':
                personalTasks++;
                break;
              case 'Shopping':
                shoppingTasks++;
                break;
              case 'Meeting':
                meetingTasks++;
                break;
            }

            // Overdue
            if (!completed &&
                data['dueDate'] != null &&
                data['dueDate'] is Timestamp) {
              final dueDate = (data['dueDate'] as Timestamp).toDate();

              if (dueDate.isBefore(DateTime(now.year, now.month, now.day))) {
                overdueTasks++;
              }
            }
          }

          // ========================================================
          // COMPLETION PERCENTAGE
          // ========================================================

          double completionPercentage = 0;

          if (totalTasks > 0) {
            completionPercentage = (completedTasks / totalTasks) * 100;
          }

          final int percentage = completionPercentage.round();

          // ========================================================
          // PRODUCTIVITY MESSAGE
          // ========================================================

          String productivityMessage;
          IconData productivityIcon;
          Color productivityColor;

          if (totalTasks == 0) {
            productivityMessage =
                'Start adding tasks to track your productivity.';
            productivityIcon = Icons.info_outline;
            productivityColor = Colors.blue;
          } else if (percentage >= 80) {
            productivityMessage =
                'Excellent productivity! Keep up the great work.';
            productivityIcon = Icons.emoji_events;
            productivityColor = Colors.green;
          } else if (percentage >= 50) {
            productivityMessage =
                'Good progress! Try to complete a few more tasks.';
            productivityIcon = Icons.trending_up;
            productivityColor = Colors.orange;
          } else {
            productivityMessage =
                'You have several pending tasks. Start with the highest priority task.';
            productivityIcon = Icons.warning_amber;
            productivityColor = Colors.red;
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
                      colors: [Colors.blue.shade700, Colors.blue.shade400],
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.insights, color: Colors.white, size: 35),
                          SizedBox(width: 10),
                          Text(
                            'Productivity Insights',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 23,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 10),
                      Text(
                        'Analyze your task completion and productivity.',
                        style: TextStyle(color: Colors.white, fontSize: 15),
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
                          width: 110,
                          height: 110,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              SizedBox(
                                width: 100,
                                height: 100,
                                child: CircularProgressIndicator(
                                  value: completionPercentage / 100,
                                  strokeWidth: 10,
                                  backgroundColor: Colors.grey.shade200,
                                  color: productivityColor,
                                ),
                              ),
                              Text(
                                '$percentage%',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: productivityColor,
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
                              Row(
                                children: [
                                  Icon(
                                    productivityIcon,
                                    color: productivityColor,
                                  ),
                                  const SizedBox(width: 7),
                                  Expanded(
                                    child: Text(
                                      percentage >= 80
                                          ? 'Excellent!'
                                          : percentage >= 50
                                          ? 'Good Progress'
                                          : 'Needs Improvement',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: productivityColor,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                productivityMessage,
                                style: TextStyle(
                                  color: Colors.grey.shade700,
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

                // ==================================================
                // TASK OVERVIEW
                // ==================================================
                const Text(
                  'Task Overview',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 10),

                Row(
                  children: [
                    Expanded(
                      child: _statCard(
                        title: 'Total',
                        value: totalTasks,
                        icon: Icons.task,
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _statCard(
                        title: 'Completed',
                        value: completedTasks,
                        icon: Icons.check_circle,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                Row(
                  children: [
                    Expanded(
                      child: _statCard(
                        title: 'Pending',
                        value: pendingTasks,
                        icon: Icons.pending_actions,
                        color: Colors.orange,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _statCard(
                        title: 'Overdue',
                        value: overdueTasks,
                        icon: Icons.warning,
                        color: Colors.red,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // ==================================================
                // PRIORITY ANALYSIS
                // ==================================================
                const Text(
                  'Priority Analysis',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 10),

                _analysisCard(
                  title: 'High Priority',
                  value: highPriorityTasks,
                  color: priorityColor('High'),
                  icon: Icons.priority_high,
                  total: totalTasks,
                ),

                _analysisCard(
                  title: 'Medium Priority',
                  value: mediumPriorityTasks,
                  color: priorityColor('Medium'),
                  icon: Icons.remove,
                  total: totalTasks,
                ),

                _analysisCard(
                  title: 'Low Priority',
                  value: lowPriorityTasks,
                  color: priorityColor('Low'),
                  icon: Icons.keyboard_arrow_down,
                  total: totalTasks,
                ),

                const SizedBox(height: 20),

                // ==================================================
                // CATEGORY ANALYSIS
                // ==================================================
                const Text(
                  'Category Analysis',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 10),

                _categoryCard('Study', studyTasks, Icons.school, Colors.purple),

                _categoryCard('Work', workTasks, Icons.work, Colors.blue),

                _categoryCard(
                  'Personal',
                  personalTasks,
                  Icons.person,
                  Colors.green,
                ),

                _categoryCard(
                  'Shopping',
                  shoppingTasks,
                  Icons.shopping_cart,
                  Colors.orange,
                ),

                _categoryCard(
                  'Meeting',
                  meetingTasks,
                  Icons.meeting_room,
                  Colors.red,
                ),

                const SizedBox(height: 20),

                // ==================================================
                // RECOMMENDATIONS
                // ==================================================
                const Text(
                  'Productivity Recommendations',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 10),

                if (overdueTasks > 0)
                  _recommendationCard(
                    icon: Icons.warning,
                    color: Colors.red,
                    title: 'Complete Overdue Tasks',
                    message:
                        'You have $overdueTasks overdue task(s). Consider completing them first.',
                  ),

                if (highPriorityTasks > 0)
                  _recommendationCard(
                    icon: Icons.priority_high,
                    color: Colors.orange,
                    title: 'Focus on Important Tasks',
                    message:
                        'You have $highPriorityTasks high-priority task(s). Give them your attention first.',
                  ),

                if (pendingTasks > 0)
                  _recommendationCard(
                    icon: Icons.pending_actions,
                    color: Colors.blue,
                    title: 'Reduce Pending Tasks',
                    message:
                        'Try completing at least one pending task before adding new tasks.',
                  ),

                if (totalTasks > 0 && completedTasks == totalTasks)
                  _recommendationCard(
                    icon: Icons.emoji_events,
                    color: Colors.green,
                    title: 'Excellent!',
                    message:
                        'All your tasks are completed. Great productivity!',
                  ),

                if (totalTasks == 0)
                  _recommendationCard(
                    icon: Icons.add_task,
                    color: Colors.blue,
                    title: 'Add Your First Task',
                    message:
                        'Start creating tasks to begin tracking your productivity.',
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

  Widget _statCard({
    required String title,
    required int value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              '$value',
              style: TextStyle(
                fontSize: 25,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 5),
            Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // PRIORITY ANALYSIS CARD
  // ============================================================

  Widget _analysisCard({
    required String title,
    required int value,
    required Color color,
    required IconData icon,
    required int total,
  }) {
    double progress = 0;

    if (total > 0) {
      progress = value / total;
    }

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          children: [
            Row(
              children: [
                Icon(icon, color: color),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                Text(
                  '$value',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              borderRadius: BorderRadius.circular(10),
              backgroundColor: Colors.grey.shade200,
              color: color,
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // CATEGORY CARD
  // ============================================================

  Widget _categoryCard(String title, int value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.12),
          child: Icon(icon, color: color),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 7),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '$value tasks',
            style: TextStyle(color: color, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // RECOMMENDATION CARD
  // ============================================================

  Widget _recommendationCard({
    required IconData icon,
    required Color color,
    required String title,
    required String message,
  }) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              backgroundColor: color.withValues(alpha: 0.12),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    message,
                    style: TextStyle(color: Colors.grey.shade700, height: 1.3),
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
