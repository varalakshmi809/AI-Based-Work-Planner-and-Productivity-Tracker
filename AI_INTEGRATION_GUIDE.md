# AI Integration Setup Guide

This document explains how the AI-based task priority recommendation system works.

## Architecture

```
Flutter App → Firebase Auth → Cloud Function → OpenAI API → Recommendation → Flutter App
```

## How It Works

### 1. Secure API Key Storage

- API key stored in Firebase Functions Secrets
- Flutter app calls authenticated Cloud Function
- OpenAI API communication handled securely by backend
- Recommendation returned to Flutter app

### 2. Task Analysis Parameters

| Parameter | Purpose | Example |
|-----------|---------|---------|
| taskTitle | Task name | "Submit ML Assignment" |
| description | Task details | "Complete homework" |
| priority | User priority | "Low", "Medium", "High" |
| category | Task category | "Study", "Work", "Personal" |
| dueDate | Deadline | "2026-09-01" |
| dueTime | Time | "17:30" |
| daysRemaining | Days left | 0 |
| completed | Status | false |

### 3. AI Response

```json
{
  "recommendedPriority": "High",
  "reason": "Task is due today at 5:30 PM - urgent to complete."
}
```

## Setup Instructions

### Step 1: Configure Firebase Functions

```bash
firebase functions:config:set openai.api_key="your-key"
firebase deploy --only functions:analyzeTaskPriority
```

### Step 2: Use in Flutter

```dart
import 'package:ai_work_planner/services/ai_analysis_service.dart';

final recommendation = await AIAnalysisService.analyzeTaskPriority(
  taskTitle: "Submit Assignment",
  description: "ML homework",
  priority: "Low",
  category: "Study",
  dueDate: "2026-09-01",
  dueTime: "17:30",
  daysRemaining: 0,
  completed: false,
);

print(recommendation.recommendedPriority); // "High"
print(recommendation.reason); // Explanation
```

### Step 3: Display in UI

```dart
AIRecommendationWidget(
  taskTitle: task.title,
  description: task.description,
  currentPriority: task.priority,
  category: task.category,
  dueDate: task.dueDate,
  dueTime: task.dueTime,
  daysRemaining: daysRemaining,
  completed: task.completed,
  onPriorityChange: (newPriority) {
    updateTaskPriority(task.id, newPriority);
  },
)
```

## Security Features

✅ API Key Protection - Stored in Firebase Secrets
✅ Authentication Required - Only authenticated users
✅ Rate Limiting - Built-in Firebase Functions protection
✅ Error Handling - Graceful degradation if API fails

## API Costs

- OpenAI GPT-4o-mini: ~$0.00015 per task
- Monthly estimate: ~$4-5 for 1000 analyses

## References

- [Firebase Functions](https://firebase.google.com/docs/functions)
- [OpenAI API](https://platform.openai.com/docs)
- [Flutter Cloud Functions](https://firebase.flutter.dev/docs/functions/overview)
