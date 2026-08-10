import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_canteen_app/app.dart';

void main() {
  testWidgets('splash presents accessible brand messaging', (tester) async {
    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.light, home: const SplashScreen()),
    );

    expect(find.text('Smart Canteen'), findsOneWidget);
    expect(find.text('Order ahead. Skip the queue.'), findsOneWidget);
    expect(find.byIcon(Icons.restaurant_menu_rounded), findsOneWidget);
  });
}
