import 'package:flutter/material.dart';

class TaskStatisticsWidget extends StatelessWidget {
  final int totalTasks;
  final int completedTasks;
  final int pendingTasks;
  final int highPriorityTasks;

  const TaskStatisticsWidget({
    super.key,
    required this.totalTasks,
    required this.completedTasks,
    required this.pendingTasks,
    required this.highPriorityTasks,
  });

  @override
  Widget build(BuildContext context) {
    final double percentage = totalTasks == 0
        ? 0
        : (completedTasks / totalTasks) * 100;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 5, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Task Progress",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 15),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _statCard(
                icon: Icons.assignment,
                title: "Total",
                value: totalTasks,
                color: Colors.blue,
              ),

              _statCard(
                icon: Icons.check_circle,
                title: "Done",
                value: completedTasks,
                color: Colors.green,
              ),

              _statCard(
                icon: Icons.pending_actions,
                title: "Pending",
                value: pendingTasks,
                color: Colors.orange,
              ),

              _statCard(
                icon: Icons.priority_high,
                title: "High",
                value: highPriorityTasks,
                color: Colors.red,
              ),
            ],
          ),

          const SizedBox(height: 20),

          Text(
            "Completion: ${percentage.toStringAsFixed(1)}%",
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),

          const SizedBox(height: 8),

          LinearProgressIndicator(
            value: totalTasks == 0 ? 0 : completedTasks / totalTasks,
            minHeight: 10,
            borderRadius: BorderRadius.circular(10),
            backgroundColor: Colors.grey.shade300,
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
          ),
        ],
      ),
    );
  }

  Widget _statCard({
    required IconData icon,
    required String title,
    required int value,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),

        const SizedBox(height: 5),

        Text(
          value.toString(),
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),

        Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }
}
