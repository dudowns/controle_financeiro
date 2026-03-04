import 'package:flutter/foundation.dart';

class LoggerService {
  static void info(String message) {
    if (kDebugMode) {
      debugPrint('📘 INFO: $message');
    }
  }

  static void success(String message) {
    if (kDebugMode) {
      debugPrint('✅ SUCCESS: $message');
    }
  }

  static void warning(String message) {
    if (kDebugMode) {
      debugPrint('⚠️ WARNING: $message');
    }
  }

  static void error(String message, [dynamic error]) {
    if (kDebugMode) {
      debugPrint('❌ ERROR: $message');
      if (error != null) {
        debugPrint('   Details: $error');
      }
    }
  }

  static void database(String message) {
    if (kDebugMode) {
      debugPrint('💾 DB: $message');
    }
  }

  static void network(String message) {
    if (kDebugMode) {
      debugPrint('🌐 NETWORK: $message');
    }
  }
}
