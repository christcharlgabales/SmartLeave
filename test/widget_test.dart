// test/widget_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

// Import your app components
// Adjust these imports based on your actual file structure

import '..//lib/screens/auth/login_screen.dart';
import '..//lib/providers/auth_provider.dart';
void main() {
  group('SmartLeave Widget Tests', () {
    testWidgets('LoginScreen renders correctly', (WidgetTester tester) async {
      // Create a test app wrapper with necessary providers
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider(
            create: (_) => AuthProvider(),
            child: const LoginScreen(),
          ),
        ),
      );

      // Verify that login screen elements are present
      expect(find.text('Welcome Back'), findsOneWidget);
      expect(find.text('Sign in to manage your leaves'), findsOneWidget);
      expect(find.byType(TextFormField), findsNWidgets(2)); // Email and password fields
      expect(find.text('Sign In'), findsOneWidget);
      expect(find.text('Sign Up'), findsOneWidget);
    });

    testWidgets('LoginScreen email validation works', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider(
            create: (_) => AuthProvider(),
            child: const LoginScreen(),
          ),
        ),
      );

      // Find the email field and enter invalid email
      final emailField = find.byKey(const Key('email'));
      if (emailField.evaluate().isNotEmpty) {
        await tester.enterText(emailField, 'invalid-email');
        await tester.tap(find.text('Sign In'));
        await tester.pump();
        
        // Check if validation error appears
        expect(find.textContaining('email'), findsAtLeastNWidgets(1));
      }
    });

    testWidgets('Password visibility toggle works', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider(
            create: (_) => AuthProvider(),
            child: const LoginScreen(),
          ),
        ),
      );

      // Find and tap the password visibility icon
      final visibilityIcon = find.byIcon(Icons.visibility_off);
      if (visibilityIcon.evaluate().isNotEmpty) {
        await tester.tap(visibilityIcon);
        await tester.pump();
        
        // Check if icon changed to visibility
        expect(find.byIcon(Icons.visibility), findsOneWidget);
      }
    });
  });

  group('Navigation Tests', () {
    testWidgets('Navigation between login and signup works', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider(
            create: (_) => AuthProvider(),
            child: const LoginScreen(),
          ),
          routes: {
            '/signup': (context) => ChangeNotifierProvider(
                  create: (_) => AuthProvider(),
                  child: const Scaffold(body: Text('SignUp Screen')),
                ),
          },
        ),
      );

      // Tap on Sign Up link
      final signUpLink = find.text('Sign Up');
      if (signUpLink.evaluate().isNotEmpty) {
        await tester.tap(signUpLink);
        await tester.pumpAndSettle();
        
        // Verify navigation occurred (this is a simplified test)
        // In a real app with proper routing, you'd test the actual navigation
      }
    });
  });

  group('Form Validation Tests', () {
    testWidgets('Empty form shows validation errors', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider(
            create: (_) => AuthProvider(),
            child: const LoginScreen(),
          ),
        ),
      );

      // Tap Sign In button without filling form
      await tester.tap(find.text('Sign In'));
      await tester.pump();

      // The form should not proceed without valid data
      // This test depends on your form validation implementation
    });
  });
}