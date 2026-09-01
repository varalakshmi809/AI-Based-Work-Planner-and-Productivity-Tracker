import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),

      appBar: AppBar(
        title: const Text("Dashboard"),
        centerTitle: true,
        backgroundColor: const Color(0xFF17175F),
        foregroundColor: Colors.white,
      ),

      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection("tasks").snapshots(),

        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                "Error: ${snapshot.error}",
                style: const TextStyle(color: Colors.red),
              ),
            );
          }

          final docs = snapshot.data?.docs ?? [];

          int totalTasks = docs.length;
          int completedTasks = 0;
          int pendingTasks = 0;
          int highPriority = 0;
          int mediumPriority = 0;
          int lowPriority = 0;

          for (final doc in docs) {
            final data = doc.data() as Map<String, dynamic>;

            final completed = data["completed"] == true;

            final priority = (data["priority"] ?? "Medium").toString();

            if (completed) {
              completedTasks++;
            } else {
              pendingTasks++;
            }

            if (priority == "High") {
              highPriority++;
            } else if (priority == "Medium") {
              mediumPriority++;
            } else if (priority == "Low") {
              lowPriority++;
            }
          }

          double completionPercentage = totalTasks == 0
              ? 0
              : completedTasks / totalTasks;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // =========================
                // SUMMARY
                // =========================
                Row(
                  children: [
                    Expanded(
                      child: dashboardCard(
                        icon: Icons.assignment,
                        title: "Total Tasks",
                        value: totalTasks,
                        color: Colors.blue,
                      ),
                    ),

                    const SizedBox(width: 12),

                    Expanded(
                      child: dashboardCard(
                        icon: Icons.check_circle,
                        title: "Completed",
                        value: completedTasks,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: dashboardCard(
                        icon: Icons.pending_actions,
                        title: "Pending",
                        value: pendingTasks,
                        color: Colors.orange,
                      ),
                    ),

                    const SizedBox(width: 12),

                    Expanded(
                      child: dashboardCard(
                        icon: Icons.priority_high,
                        title: "High Priority",
                        value: highPriority,
                        color: Colors.red,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 25),

                // =========================
                // COMPLETION PROGRESS
                // =========================
                Card(
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Task Completion",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 20),

                        Center(
                          child: SizedBox(
                            height: 150,
                            width: 150,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                SizedBox(
                                  height: 150,
                                  width: 150,
                                  child: CircularProgressIndicator(
                                    value: completionPercentage,
                                    strokeWidth: 15,
                                    backgroundColor: Colors.grey.shade300,
                                    valueColor:
                                        const AlwaysStoppedAnimation<Color>(
                                          Colors.green,
                                        ),
                                  ),
                                ),

                                Text(
                                  "${(completionPercentage * 100).toStringAsFixed(0)}%",
                                  style: const TextStyle(
                                    fontSize: 25,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        Center(
                          child: Text(
                            "$completedTasks of $totalTasks tasks completed",
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // =========================
                // PRIORITY ANALYSIS
                // =========================
                Card(
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Priority Analysis",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 20),

                        priorityRow("High Priority", highPriority, Colors.red),

                        const SizedBox(height: 15),

                        priorityRow(
                          "Medium Priority",
                          mediumPriority,
                          Colors.orange,
                        ),

                        const SizedBox(height: 15),

                        priorityRow("Low Priority", lowPriority, Colors.green),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // =========================
                // PRODUCTIVITY MESSAGE
                // =========================
                Card(
                  color: Colors.blue.shade50,
                  elevation: 3,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.lightbulb,
                          color: Colors.orange,
                          size: 35,
                        ),

                        const SizedBox(width: 15),

                        Expanded(
                          child: Text(
                            productivityMessage(
                              totalTasks,
                              completedTasks,
                              pendingTasks,
                            ),
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // =====================================================
  // DASHBOARD CARD
  // =====================================================

  Widget dashboardCard({
    required IconData icon,
    required String title,
    required int value,
    required Color color,
  }) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 35),

            const SizedBox(height: 8),

            Text(
              value.toString(),
              style: TextStyle(
                fontSize: 25,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),

            const SizedBox(height: 5),

            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  // =====================================================
  // PRIORITY ROW
  // =====================================================

  Widget priorityRow(String title, int value, Color color) {
    return Row(
      children: [
        Container(
          height: 14,
          width: 14,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),

        const SizedBox(width: 10),

        Expanded(child: Text(title, style: const TextStyle(fontSize: 16))),

        Text(
          value.toString(),
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 17,
          ),
        ),
      ],
    );
  }

  // =====================================================
  // PRODUCTIVITY MESSAGE
  // =====================================================

  String productivityMessage(int total, int completed, int pending) {
    if (total == 0) {
      return "No tasks available. Add your first task to start tracking productivity.";
    }

    if (completed == total) {
      return "Excellent! 🎉 All your tasks are completed.";
    }

    if (completed > pending) {
      return "Great progress! 👍 You have completed more tasks than pending tasks.";
    }

    if (pending > completed) {
      return "Focus on your pending tasks. Complete high-priority tasks first.";
    }

    return "Keep working consistently to improve your productivity.";
  }
}
