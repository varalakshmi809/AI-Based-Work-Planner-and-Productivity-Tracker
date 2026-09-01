class TaskAnalysisResponse {
  final String recommendedPriority;
  final String reason;
  final DateTime analyzedAt;

  TaskAnalysisResponse({
    required this.recommendedPriority,
    required this.reason,
    required this.analyzedAt,
  });

  factory TaskAnalysisResponse.fromJson(Map<String, dynamic> json) {
    return TaskAnalysisResponse(
      recommendedPriority: json['recommendedPriority'] ?? 'Medium',
      reason: json['reason'] ?? 'Unable to analyze task',
      analyzedAt: DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'recommendedPriority': recommendedPriority,
      'reason': reason,
      'analyzedAt': analyzedAt.toIso8601String(),
    };
  }

  bool get priorityChanged {
    return true;
  }
}
