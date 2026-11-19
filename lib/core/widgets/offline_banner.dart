import 'package:flutter/material.dart';

class OfflineBanner extends StatelessWidget {
  final String? message;
  final VoidCallback? onRetry;

  const OfflineBanner({
    super.key,
    this.message,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF3C7), // Warm amber background
        border: const Border(
          bottom: BorderSide(color: Color(0xFFFDE68A), width: 1),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.cloud_off_rounded,
            color: Color(0xFFD97706),
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message ?? 'Operating in offline mode. Viewing cached data.',
              style: const TextStyle(
                color: Color(0xFF92400E),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (onRetry != null) ...[
            const SizedBox(width: 8),
            GestureDetector(
              onTap: onRetry,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFD97706),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'Retry',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
