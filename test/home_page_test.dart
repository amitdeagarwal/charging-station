// test/home_page_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:your_app_name/notification_service.dart';
import 'package:your_app_name/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('HomePage Widget Tests', () {
    final notificationService = NotificationService();

    testWidgets('Start Tracking button should change the status', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        home: HomePage(notificationService: notificationService),
      ));

      expect(find.text('Tracking is off'), findsOneWidget);
      expect(find.text('Tracking is on'), findsNothing);

      await tester.tap(find.text('Start Tracking'));
      await tester.pump();

      expect(find.text('Tracking is on'), findsOneWidget);
      expect(find.text('Tracking is off'), findsNothing);
    });

    testWidgets('Markers should be visible on the map', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        home: HomePage(notificationService: notificationService),
      ));

      final GoogleMap googleMap = tester.widget(find.byType(GoogleMap));
      expect(googleMap.markers.length, 4);
    });
  });
}
