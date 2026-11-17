import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shopping_hub/main.dart';

void main() {
  testWidgets('ShoppingHubApp boots and displays splash screen title', (WidgetTester tester) async {
    // Mock initial shared preferences
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const ShoppingHubApp());

    // Verify app renders splash screen title
    expect(find.text('ShoppingHub'), findsOneWidget);
    expect(find.text('Curated Goods & Essentials'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    // Settle pending splash timer and transition
    await tester.pumpAndSettle();
  });
}
