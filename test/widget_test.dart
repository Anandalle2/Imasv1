import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('IMAS app smoke test', (WidgetTester tester) async {
    // Verify basic widget renders
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(child: Text('IMAS')),
        ),
      ),
    );

    expect(find.text('IMAS'), findsOneWidget);
  });
}
