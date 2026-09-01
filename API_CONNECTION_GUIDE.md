# API Connection Setup Guide

## Overview
Your Flutter project is configured to connect to the OpenAI API for AI task analysis features.

## Current Setup

✅ **Environment Configuration**
- `.env` file is set up with `OPENAI_API_KEY`
- `flutter_dotenv` loads the key at app startup
- All required dependencies are included in `pubspec.yaml`

✅ **API Service**
- `AiService` handles all OpenAI API calls
- Used in `AiSuggestionScreen` for analyzing task priorities
- Includes error handling and logging

## Testing the Connection

### Method 1: Use the Debug Screen (Easiest)
1. Log in to the app as admin
2. Go to **Admin Dashboard**
3. Click the **API** icon (🔌) in the top-right corner
4. Click **"Run Test"** to verify the connection

The test will show:
- ✅ If your API key is valid
- ✅ If the connection to OpenAI is working
- ✅ A sample response from the AI

### Method 2: Test in Your App
1. Navigate to **AI Suggestions** screen
2. Select a task and click "Analyze with AI"
3. The app will call the API to analyze the task
4. Results will appear on screen

### Method 3: Manual Testing
Run this in your Flutter console:
```dart
import 'package:ai_work_planner/services/api_test_service.dart';

// Call this function
final result = await ApiTestService.testApiConnection();
print(result);
```

## Troubleshooting

### ❌ "API Key is missing"
- **Solution**: Make sure `OPENAI_API_KEY` is in `assets/.env`
- The app loads `.env` at startup, so you need to **Hot Restart** (not hot reload) after changes

### ❌ "API Key is invalid (401)"
- **Solution**: Your API key might be:
  - Expired - generate a new one at https://platform.openai.com/api-keys
  - Revoked - check your OpenAI account
  - Incorrect - verify you copied it correctly

### ❌ "Rate limited (429)"
- **Solution**: You've made too many API calls
- Wait a few moments and try again
- Check your OpenAI usage at https://platform.openai.com/account/usage/overview

### ❌ "Network error"
- **Solution**: Check your internet connection
- Make sure your firewall isn't blocking openai.com

## Important Notes

1. **Never commit the `.env` file** with real API keys to version control
2. **Add `.env` to `.gitignore`** to prevent accidental commits
3. The API key in `.env` is loaded as plain text - treat it as sensitive data
4. Test API calls cost money - monitor your OpenAI usage

## Files Created/Modified

**New Files:**
- `lib/services/api_test_service.dart` - API connection testing utility
- `lib/screens/api_debug_screen.dart` - Debug UI for testing

**Modified Files:**
- `lib/screens/admin_screen.dart` - Added API debug button to AppBar

## Next Steps

1. **Test the connection** using the methods above
2. **Monitor API usage** at https://platform.openai.com/account/usage/overview
3. **Review logs** when testing to see detailed request/response info
4. **Implement error handling** in your screens (already done in `AiSuggestionScreen`)

---

**Need Help?**
- Check the console output (print statements) for detailed error messages
- Verify your OpenAI API key at https://platform.openai.com
- Check OpenAI API documentation: https://platform.openai.com/docs/api-reference
