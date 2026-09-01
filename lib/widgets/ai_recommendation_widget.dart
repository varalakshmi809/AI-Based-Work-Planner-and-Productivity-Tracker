import 'package:flutter/material.dart';
import '../models/task_analysis_response.dart';
import '../services/ai_analysis_service.dart';

class AIRecommendationWidget extends StatefulWidget {
  final String taskTitle;
  final String description;
  final String currentPriority;
  final String category;
  final String dueDate;
  final String dueTime;
  final int daysRemaining;
  final bool completed;
  final Function(String newPriority)? onPriorityChange;

  const AIRecommendationWidget({
    super.key,
    required this.taskTitle,
    required this.description,
    required this.currentPriority,
    required this.category,
    required this.dueDate,
    required this.dueTime,
    required this.daysRemaining,
    required this.completed,
    this.onPriorityChange,
  });

  @override
  State<AIRecommendationWidget> createState() => _AIRecommendationWidgetState();
}

class _AIRecommendationWidgetState extends State<AIRecommendationWidget> {
  late Future<TaskAnalysisResponse> _analysisFuture;

  @override
  void initState() {
    super.initState();
    _loadAnalysis();
  }

  void _loadAnalysis() {
    _analysisFuture = AIAnalysisService.analyzeTaskPriority(
      taskTitle: widget.taskTitle,
      description: widget.description,
      priority: widget.currentPriority,
      category: widget.category,
      dueDate: widget.dueDate,
      dueTime: widget.dueTime,
      daysRemaining: widget.daysRemaining,
      completed: widget.completed,
    );
  }

  Color _getPriorityColor(String priority) {
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

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<TaskAnalysisResponse>(
      future: _analysisFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingState();
        }
        if (snapshot.hasError) {
          return _buildErrorState(snapshot.error);
        }

        final analysis = snapshot.data!;
        final recommendationDifferent =
            analysis.recommendedPriority.toLowerCase() != widget.currentPriority.toLowerCase();

        return _buildAnalysisCard(analysis, recommendationDifferent);
      },
    );
  }

  Widget _buildLoadingState() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F6FA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        children: [
          const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
          const SizedBox(width: 12),
          Text('AI is analyzing your task...', style: TextStyle(color: Colors.grey[600], fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildErrorState(Object? error) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [Icon(Icons.error_outline, color: Colors.red[600]), const SizedBox(width: 12), Text('AI Analysis Error', style: TextStyle(color: Colors.red[600], fontWeight: FontWeight.bold))]),
          const SizedBox(height: 8),
          Text(error.toString(), style: TextStyle(color: Colors.red[600], fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildAnalysisCard(TaskAnalysisResponse analysis, bool isDifferent) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDifferent ? const Color(0xFFFFF3E0) : const Color(0xFFF5F6FA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDifferent ? Colors.orange[300]! : Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [Icon(Icons.lightbulb_outline, color: Colors.amber[700], size: 20), const SizedBox(width: 8), Text('AI Priority Recommendation', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold))]),
          const SizedBox(height: 12),
          Text('Your Priority: ', style: TextStyle(color: Colors.grey[700], fontSize: 13)),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: _getPriorityColor(widget.currentPriority).withOpacity(0.2), borderRadius: BorderRadius.circular(6)),
            child: Text(widget.currentPriority, style: TextStyle(color: _getPriorityColor(widget.currentPriority), fontWeight: FontWeight.bold, fontSize: 12)),
          ),
          if (isDifferent) ...[
            const SizedBox(height: 12),
            Text('Recommended: ', style: TextStyle(color: Colors.grey[700], fontSize: 13)),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: _getPriorityColor(analysis.recommendedPriority).withOpacity(0.2), borderRadius: BorderRadius.circular(6)),
              child: Text(analysis.recommendedPriority, style: TextStyle(color: _getPriorityColor(analysis.recommendedPriority), fontWeight: FontWeight.bold, fontSize: 12)),
            ),
          ],
          const SizedBox(height: 12),
          Text('Reason:', style: TextStyle(color: Colors.grey[700], fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Text(analysis.reason, style: TextStyle(color: Colors.grey[600], fontSize: 12, height: 1.5)),
          if (isDifferent && widget.onPriorityChange != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: ElevatedButton.icon(
                onPressed: () => widget.onPriorityChange!(analysis.recommendedPriority),
                icon: const Icon(Icons.check_circle_outline, size: 18),
                label: const Text('Apply Recommendation'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.amber[700], foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            ),
        ],
      ),
    );
  }
}
