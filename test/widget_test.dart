import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:campus_fix/features/auth/login/login_screen.dart';
import 'package:campus_fix/app/theme/app_theme.dart';

void main() {
  testWidgets('CampusFix LoginScreen renders email and password fields', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const LoginScreen(),
        ),
      ),
    );

    // Verify key UI elements on Login screen
    expect(find.text('Welcome Back'), findsOneWidget);
    expect(find.text('College Email'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
    expect(find.text('Sign In'), findsOneWidget);
    expect(find.text('Register Now'), findsOneWidget);
  });
}
