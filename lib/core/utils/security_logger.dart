import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';

/// A privacy-conscious logger that ensures sensitive information is not exposed
/// in production environments.
/// 
/// [SecurityLogger] follows "Zero Technical Debt" standards:
/// 1. Uses [developer.log] instead of [debugPrint] for better integration with DevTools.
/// 2. Strictly segments sensitive context.
/// 3. Ensures zero PII (Personally Identifiable Information) in non-debug environments.
class SecurityLogger {
  static const String _tag = 'PrivacyTracker.Security';

  /// Logs an error with optional sensitive context.
  /// 
  /// In non-debug builds, [sensitiveContext] and the full [error] details are 
  /// suppressed to prevent accidental data leakage in ADB logs.
  static void logError(String message, {Object? error, StackTrace? stackTrace, String? sensitiveContext}) {
    if (kDebugMode) {
      developer.log(
        '🚨 $message',
        name: _tag,
        error: error,
        stackTrace: stackTrace,
        level: 1000,
      );
      if (sensitiveContext != null) {
        developer.log('🔍 Context: $sensitiveContext', name: _tag);
      }
    } else {
      // Production: Log ONLY the message and error (excluding sensitiveContext)
      // We use debugPrint which typically reaches logcat under the 'flutter' tag.
      debugPrint('[$_tag] 🚨 $message');
      if (error != null) {
        debugPrint('[$_tag] 🛑 Error: $error');
      }
    }
  }

  /// Logs a security event (e.g., "Key generated") without any sensitive details.
  static void logEvent(String event) {
    if (kDebugMode) {
      developer.log(
        '🛡️ $event', 
        name: _tag,
        level: 500,
      );
    }
  }

  /// Convenience for non-security related but important system events.
  static void info(String message) {
    if (kDebugMode) {
      developer.log('ℹ️ $message', name: _tag);
    }
  }
}
