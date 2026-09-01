import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  // Firebase Configuration
  static String get firebaseApiKey {
    return dotenv.env['FIREBASE_API_KEY'] ?? '';
  }

  // Environment
  static String get appEnvironment {
    return dotenv.env['APP_ENV'] ?? 'development';
  }

  // Check if in development mode
  static bool get isDevelopment {
    return appEnvironment == 'development';
  }

  // Check if in production mode
  static bool get isProduction {
    return appEnvironment == 'production';
  }
}
