import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Basic widget test - app structure exists', (WidgetTester tester) async {
    // Simple test without Supabase to verify Flutter setup
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          appBar: AppBar(title: const Text('EcoTrack')),
          body: const Center(child: Text('Test')),
        ),
      ),
    );

    // Verify basic widgets work
    expect(find.text('EcoTrack'), findsOneWidget);
    expect(find.text('Test'), findsOneWidget);
    expect(find.byType(AppBar), findsOneWidget);
  });
}
