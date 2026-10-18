import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:private_tracker_app/core/services/auth_service.dart';
import 'package:private_tracker_app/presentation/theme/app_theme.dart';
import 'package:private_tracker_app/presentation/widgets/authentication_overlay.dart';
import 'package:provider/provider.dart';

class MockAuthService extends Mock implements AuthService {}

void main() {
  late MockAuthService mockAuthService;

  setUp(() {
    mockAuthService = MockAuthService();
  });

  testWidgets('AuthenticationOverlay renders correctly', (WidgetTester tester) async {
    await tester.pumpWidget(
      Provider<AuthService>.value(
        value: mockAuthService,
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: AuthenticationOverlay(onUnlockSuccess: () {}),
        ),
      ),
    );

    expect(find.text('APP LOCKED'), findsOneWidget);
    expect(find.text('Please authenticate to access your private data'), findsOneWidget);
    expect(find.byIcon(Icons.lock_person_rounded), findsOneWidget);
    expect(find.text('UNLOCK NOW'), findsOneWidget);
  });

  testWidgets('Tapping Unlock Now calls AuthService.authenticate and onUnlockSuccess on success', (
    WidgetTester tester,
  ) async {
    bool unlocked = false;
    when(() => mockAuthService.authenticate()).thenAnswer((_) async => true);

    await tester.pumpWidget(
      Provider<AuthService>.value(
        value: mockAuthService,
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: AuthenticationOverlay(onUnlockSuccess: () => unlocked = true),
        ),
      ),
    );

    await tester.tap(find.text('UNLOCK NOW'));
    await tester.pump(const Duration(seconds: 1));

    verify(() => mockAuthService.authenticate()).called(1);
    expect(unlocked, true);
  });

  testWidgets('Tapping Unlock Now does not call onUnlockSuccess on failure', (
    WidgetTester tester,
  ) async {
    bool unlocked = false;
    when(() => mockAuthService.authenticate()).thenAnswer((_) async => false);

    await tester.pumpWidget(
      Provider<AuthService>.value(
        value: mockAuthService,
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: AuthenticationOverlay(onUnlockSuccess: () => unlocked = true),
        ),
      ),
    );

    await tester.tap(find.text('UNLOCK NOW'));
    await tester.pump(const Duration(seconds: 1));

    verify(() => mockAuthService.authenticate()).called(1);
    expect(unlocked, false);
  });
}
