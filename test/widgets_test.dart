import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:campus_fix/core/widgets/custom_button.dart';
import 'package:campus_fix/core/widgets/status_badge.dart';
import 'package:campus_fix/core/widgets/priority_badge.dart';
import 'package:campus_fix/core/widgets/empty_view.dart';
import 'package:campus_fix/app/theme/app_theme.dart';

void main() {
  testWidgets('CustomButton renders text and triggers callback', (WidgetTester tester) async {
    bool tapped = false;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(
          body: CustomButton(
            text: 'Submit Request',
            onPressed: () {
              tapped = true;
            },
          ),
        ),
      ),
    );

    expect(find.text('Submit Request'), findsOneWidget);
    await tester.tap(find.text('Submit Request'));
    await tester.pumpAndSettle();

    expect(tapped, true);
  });

  testWidgets('StatusBadge displays correct text and icon', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: const Scaffold(
          body: StatusBadge(status: 'IN_PROGRESS'),
        ),
      ),
    );

    expect(find.text('IN PROGRESS'), findsOneWidget);
    expect(find.byIcon(Icons.engineering_rounded), findsOneWidget);
  });

  testWidgets('PriorityBadge displays correct priority level', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: const Scaffold(
          body: PriorityBadge(priority: 'URGENT'),
        ),
      ),
    );

    expect(find.text('URGENT'), findsOneWidget);
  });

  testWidgets('EmptyView displays title, message and button', (WidgetTester tester) async {
    bool buttonPressed = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: EmptyView(
            title: 'No Items Found',
            message: 'Nothing here yet.',
            buttonText: 'Add New',
            onButtonPressed: () {
              buttonPressed = true;
            },
          ),
        ),
      ),
    );

    expect(find.text('No Items Found'), findsOneWidget);
    expect(find.text('Nothing here yet.'), findsOneWidget);
    expect(find.text('Add New'), findsOneWidget);

    await tester.tap(find.text('Add New'));
    await tester.pumpAndSettle();

    expect(buttonPressed, true);
  });
}
