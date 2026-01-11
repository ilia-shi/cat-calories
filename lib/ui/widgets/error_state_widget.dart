import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A widget that displays an error state with full error details and stack trace
class ErrorStateWidget extends StatelessWidget {
  final String message;
  final String? technicalDetails;
  final VoidCallback? onRetry;
  final VoidCallback? onDismiss;
  final bool showTechnicalDetails;

  const ErrorStateWidget({
    Key? key,
    required this.message,
    this.technicalDetails,
    this.onRetry,
    this.onDismiss,
    this.showTechnicalDetails = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Error header
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.error_outline, color: Colors.red[700], size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Error',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.red[700],
                    ),
                  ),
                ),
                if (technicalDetails != null)
                  IconButton(
                    icon: const Icon(Icons.copy),
                    onPressed: () {
                      final fullError = '$message\n\n$technicalDetails';
                      Clipboard.setData(ClipboardData(text: fullError));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Error copied to clipboard'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                    tooltip: 'Copy error',
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Error message
          Text(
            'Error Message:',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: SelectableText(
              message,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 13,
                color: Colors.red[800],
              ),
            ),
          ),

          // Stack trace
          if (showTechnicalDetails && technicalDetails != null) ...[
            const SizedBox(height: 16),
            Text(
              'Stack Trace:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(8),
              ),
              child: SelectableText(
                technicalDetails!,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 11,
                  color: Colors.greenAccent,
                ),
              ),
            ),
          ],

          const SizedBox(height: 24),

          // Action buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (onDismiss != null) ...[
                OutlinedButton(
                  onPressed: onDismiss,
                  child: const Text('Dismiss'),
                ),
                const SizedBox(width: 12),
              ],
              if (onRetry != null)
                ElevatedButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// A smaller inline error widget for use within lists or cards
class InlineErrorWidget extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const InlineErrorWidget({
    Key? key,
    required this.message,
    this.onRetry,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red[700]),
          const SizedBox(width: 12),
          Expanded(
            child: SelectableText(
              message,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 12,
                color: Colors.red[800],
              ),
            ),
          ),
          if (onRetry != null)
            IconButton(
              onPressed: onRetry,
              icon: Icon(Icons.refresh, color: Colors.red[700]),
              tooltip: 'Retry',
            ),
        ],
      ),
    );
  }
}