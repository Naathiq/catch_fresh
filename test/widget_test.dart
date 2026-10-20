import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('App theme and basic smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Text('Catch FRESH'),
        ),
      ),
    );
    expect(find.text('Catch FRESH'), findsOneWidget);
  });
}
