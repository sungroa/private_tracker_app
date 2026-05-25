import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:private_tracker_app/presentation/pages/privacy_policy_page.dart';
import 'package:private_tracker_app/presentation/theme/app_theme.dart';

class MockAssetBundle extends Fake implements AssetBundle {
  @override
  Future<String> loadString(String key, {bool cache = true}) async {
    if (key == 'assets/docs/privacy_policy.md') {
      return '''
# Privacy Policy
## 3. Optional Cloud Synchronization
## 4. Biometric Protection
''';
    }
    throw FlutterError('Asset not found');
  }
}

void main() {
  group('PrivacyPolicyPage', () {
    testWidgets('renders Privacy Policy page with markdown content', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: DefaultAssetBundle(
            bundle: MockAssetBundle(),
            child: const PrivacyPolicyPage(),
          ),
        ),
      );
      
      // Wait for FutureBuilder to complete
      await tester.pump(); // Start the future
      await tester.pump(const Duration(milliseconds: 100)); // Complete the future

      // Verify AppBar title
      expect(find.descendant(of: find.byType(AppBar), matching: find.text('Privacy Policy')), findsOneWidget);

      // Verify specific content from PRIVACY_POLICY.md
      // Note: Markdown uses a scrollable internal view.
      final scrollableFinder = find.byType(Scrollable).first;
      
      await tester.scrollUntilVisible(find.textContaining('Optional Cloud Synchronization', findRichText: true), 500, scrollable: scrollableFinder);
      expect(find.textContaining('Optional Cloud Synchronization', findRichText: true), findsOneWidget);
      
      await tester.scrollUntilVisible(find.textContaining('Biometric Protection', findRichText: true), 500, scrollable: scrollableFinder);
      expect(find.textContaining('Biometric Protection', findRichText: true), findsOneWidget);
    });

    testWidgets('can be closed via leading button', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: DefaultAssetBundle(
            bundle: MockAssetBundle(),
            child: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () => PrivacyPolicyPage.show(context),
                  child: const Text('Open'),
                ),
              ),
            ),
          ),
        ),
      );

      // Open page
      await tester.tap(find.text('Open'));
      await tester.pump(); // start animation and future
      await tester.pump(const Duration(milliseconds: 500)); // resolve future and dismiss progress indicator
      await tester.pumpAndSettle(); // settle transition animation

      expect(find.byType(PrivacyPolicyPage), findsOneWidget);

      // Close page
      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pumpAndSettle();

      expect(find.byType(PrivacyPolicyPage), findsNothing);
    });
  });
}
