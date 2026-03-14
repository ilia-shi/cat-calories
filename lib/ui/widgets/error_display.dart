import 'package:flutter/material.dart';

/// Utility class for displaying errors to users
class ErrorDisplay {
  /// Show a snackbar with an error message
  static void showError(BuildContext context, String message, {
    String? title,
    Duration duration = const Duration(seconds: 5),
    VoidCallback? onRetry,
  }) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (title != null)
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  Text(
                    message,
                    style: const TextStyle(color: Colors.white),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: Colors.red[700],
        duration: duration,
        action: onRetry != null
            ? SnackBarAction(
          label: 'Retry',
          textColor: Colors.white,
          onPressed: onRetry,
        )
            : null,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  /// Show a dialog with error details (for more severe errors)
  static Future<void> showErrorDialog(
      BuildContext context, {
        required String title,
        required String message,
        String? details,
        VoidCallback? onRetry,
      }) async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        icon: Icon(Icons.error_outline, color: Colors.red[700], size: 48),
        title: Text(title),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(message),
              if (details != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: SelectableText(
                    details,
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                      color: Colors.grey[800],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
          if (onRetry != null)
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                onRetry();
              },
              child: const Text('Retry'),
            ),
        ],
      ),
    );
  }

  /// Show a warning snackbar (less severe than error)
  static void showWarning(BuildContext context, String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.warning_amber, color: Colors.black87),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: Colors.black87),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.amber[300],
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  /// Show a success snackbar
  static void showSuccess(BuildContext context, String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.green[600],
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  /// Format a database exception for user display
  static String formatDatabaseError(dynamic error) {
    final errorString = error.toString();

    // Common SQLite errors with user-friendly messages
    if (errorString.contains('SQLITE_CONSTRAINT')) {
      return 'This item already exists or conflicts with existing data.';
    }
    if (errorString.contains('SQLITE_FULL')) {
      return 'Storage is full. Please free up some space.';
    }
    if (errorString.contains('SQLITE_CORRUPT')) {
      return 'Database is corrupted. Please contact support.';
    }
    if (errorString.contains('SQLITE_READONLY')) {
      return 'Cannot save changes. Storage is read-only.';
    }
    if (errorString.contains('SQLITE_IOERR')) {
      return 'Storage error. Please check your device storage.';
    }
    if (errorString.contains('SQLITE_MISMATCH')) {
      return 'Data format error. Please try again or contact support.';
    }
    if (errorString.contains('no such table')) {
      return 'Database structure error. Please restart the app.';
    }
    if (errorString.contains('no such column')) {
      return 'Database needs update. Please restart the app.';
    }

    // Generic fallback
    return 'An error occurred while saving data. Please try again.';
  }

  /// Get technical details for debugging (shown in release builds optionally)
  static String getTechnicalDetails(dynamic error, [StackTrace? stackTrace]) {
    final buffer = StringBuffer();
    buffer.writeln('Error: ${error.runtimeType}');
    buffer.writeln(error.toString());
    if (stackTrace != null) {
      buffer.writeln('\nStack trace:');
      // Only show first few lines of stack trace
      final lines = stackTrace.toString().split('\n').take(10);
      buffer.writeln(lines.join('\n'));
    }
    return buffer.toString();
  }
}