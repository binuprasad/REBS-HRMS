import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rebs_hrms/core/widgets/offline_banner.dart';

void main() {
  group('Widget Tests - Offline & Status States', () {
    testWidgets('OfflineBanner renders offline message and triggers retry', (WidgetTester tester) async {
      bool retryPressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: OfflineBanner(
              message: 'Viewing cached dashboard data while offline.',
              onRetry: () {
                retryPressed = true;
              },
            ),
          ),
        ),
      );

      // Verify that offline icon and message are rendered
      expect(find.byIcon(Icons.cloud_off_rounded), findsOneWidget);
      expect(find.text('Viewing cached dashboard data while offline.'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);

      // Tap Retry button and verify callback
      await tester.tap(find.text('Retry'));
      await tester.pump();

      expect(retryPressed, isTrue);
    });

    testWidgets('OfflineBanner without retry does not show retry button', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: OfflineBanner(
              message: 'Offline mode active.',
            ),
          ),
        ),
      );

      expect(find.text('Offline mode active.'), findsOneWidget);
      expect(find.text('Retry'), findsNothing);
    });
  });
}
